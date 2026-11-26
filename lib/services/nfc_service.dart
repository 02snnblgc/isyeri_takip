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
        // KRİTİK: Kart okunduktan sonra oturumu hemen kapatmıyoruz.
        // Android'in kartı algılamaya devam etmesini engellemek için
        // kısa bir süre bekleyip öyle kapatıyoruz.
        await Future.delayed(const Duration(seconds: 2));
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
      dynamic data = tag.data;
      if (data != null && data is Map) {
        for (var key in data.keys) {
          var innerData = data[key];
          if (innerData is Map && innerData.containsKey('identifier')) {
            List<int>? uid = innerData['identifier'];
            if (uid != null && uid.isNotEmpty) {
              return uid.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
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
