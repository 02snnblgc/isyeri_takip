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
    List<int>? id;

    // 3.4.0 sürümünde sınıflar doğrudan bu isimlerle ana pakette yer alır.
    try {
      final NfcA? nfcA = NfcA.from(tag);
      id = nfcA?.identifier;
    } catch (_) {}

    if (id == null || id.isEmpty) {
      try {
        final MifareClassic? mifare = MifareClassic.from(tag);
        id = mifare?.identifier;
      } catch (_) {}
    }

    if (id == null || id.isEmpty) {
      try {
        final MifareUltralight? ultra = MifareUltralight.from(tag);
        id = ultra?.identifier;
      } catch (_) {}
    }

    if (id == null || id.isEmpty) {
      try {
        final IsoDep? isoDep = IsoDep.from(tag);
        id = isoDep?.identifier;
      } catch (_) {}
    }

    if (id == null || id.isEmpty) return null;
    
    return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
  }
}
