import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/foundation.dart';

class NfcService {
  NfcService._();
  static final NfcService instance = NfcService._();

  bool _kioskAktif = false;
  bool get kioskAktif => _kioskAktif;

  Future<String?> tekOkut({Duration timeout = const Duration(seconds: 30)}) async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) return null;

    String? uid;

    await NfcManager.instance.startSession(
      pollingOptions: const {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        uid = _uidCikar(tag);
        await NfcManager.instance.stopSession();
      },
    );

    if (uid == null) {
      await Future.delayed(timeout);
      if (uid == null) {
        try {
          await NfcManager.instance.stopSession();
        } catch (_) {}
      }
    }
    return uid;
  }

  Future<void> baslatKiosk(void Function(String uid) onUid) async {
    if (_kioskAktif) return;
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) return;

    _kioskAktif = true;
    await NfcManager.instance.startSession(
      pollingOptions: const {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        final uid = _uidCikar(tag);
        if (uid != null && uid.isNotEmpty) onUid(uid);
      },
    );
  }

  Future<void> durdurKiosk() async {
    if (!_kioskAktif) return;
    _kioskAktif = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  String? _uidCikar(NfcTag tag) {
    try {
      // 4.x sürümünde tag.data bir TagPigeon nesnesidir.
      // İçindeki 'ndef' verisinden identifier'a erişmeye çalışıyoruz.
      dynamic data = tag.data;
      
      // Eğer data içinde 'ndef' varsa (NDEF formatlı kartlar)
      if (data != null && data is Map && data.containsKey('ndef')) {
        dynamic ndef = data['ndef'];
        if (ndef != null) {
          // Ndef içindeki cachedNdefMessage üzerinden identifier'a ulaşmayı dene
          if (ndef is Map && ndef.containsKey('additionalData')) {
            dynamic addData = ndef['additionalData'];
            if (addData != null && addData is Map && addData.containsKey('identifier')) {
              List<int>? id = addData['identifier'];
              if (id != null && id.isNotEmpty) {
                return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
              }
            }
          }
        }
      }

      // Alternatif olarak, doğrudan 'identifier' anahtarını ara (bazı kart tipleri için)
      if (data != null && data is Map) {
        for (var key in data.keys) {
          var innerData = data[key];
          if (innerData is Map && innerData.containsKey('identifier')) {
            List<int>? id = innerData['identifier'];
            if (id != null && id.isNotEmpty) {
              return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
            }
          }
        }
      }
      
    } catch (e) {
      debugPrint('UID okuma hatası: $e');
    }
    return null;
  }
}
