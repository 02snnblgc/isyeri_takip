import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_android/nfc_manager_android.dart';
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
    List<int>? id;
    
    try {
      final NfcAAndroid? nfcA = NfcAAndroid.from(tag);
      id = nfcA?.identifier;
    } catch (e) {
      debugPrint('NfcAAndroid okuma hatası: $e');
    }

    if (id == null || id.isEmpty) {
      try {
        final MifareClassicAndroid? mifare = MifareClassicAndroid.from(tag);
        id = mifare?.identifier;
      } catch (e) {
        debugPrint('MifareClassicAndroid okuma hatası: $e');
      }
    }

    if (id == null || id.isEmpty) {
      try {
        final MifareUltralightAndroid? ultra = MifareUltralightAndroid.from(tag);
        id = ultra?.identifier;
      } catch (e) {
        debugPrint('MifareUltralightAndroid okuma hatası: $e');
      }
    }

    if (id == null || id.isEmpty) {
      try {
        final IsoDepAndroid? isoDep = IsoDepAndroid.from(tag);
        id = isoDep?.identifier;
      } catch (e) {
        debugPrint('IsoDepAndroid okuma hatası: $e');
      }
    }

    if (id == null || id.isEmpty) return null;
    
    return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
  }
}
