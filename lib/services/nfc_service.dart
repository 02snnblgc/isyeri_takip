import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/foundation.dart';

class NfcService {
  NfcService._();
  static final NfcService instance = NfcService._();

  bool _kioskAktif = false;
  bool get kioskAktif => _kioskAktif;

  /// Tek seferlik kart okutma. Başarılıysa UID (hex, küçük harf),
  /// iptal/hata → null. Oturum, kart okununca kapanır.
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

    // Timeout — okutma gelmezse oturumu kapat
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

  /// Kiosk modu: sürekli dinleme. Her okutmada `onUid` çağrılır,
  /// oturum açık kalır. `durdurKiosk()` ile kapatılır.
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
        // Kiosk'ta oturum kapatılmaz; dinleme devam eder.
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

  /// Her türlü ISO14443 etiketinden (MIFARE Classic/Ultralight/NfcA/NfcB...)
  /// UID çıkarır. En basit kartlar bile buradan geçer.
  String? _uidCikar(NfcTag tag) {
    List<int>? id;
    
    try {
      // 1. Deneme: NfcA (En yaygın olanı)
      final nfcA = NfcAAndroid.from(tag);
      id = nfcA?.identifier;
    } catch (e) {
      debugPrint('NfcA okuma hatası: $e');
    }

    if (id == null || id.isEmpty) {
      try {
        // 2. Deneme: MifareClassic (En basit kartlar)
        final mifare = MifareClassicAndroid.from(tag);
        id = mifare?.identifier;
      } catch (e) {
        debugPrint('MifareClassic okuma hatası: $e');
      }
    }

    if (id == null || id.isEmpty) {
      try {
        // 3. Deneme: MifareUltralight
        final ultra = MifareUltralightAndroid.from(tag);
        id = ultra?.identifier;
      } catch (e) {
        debugPrint('MifareUltralight okuma hatası: $e');
      }
    }

    if (id == null || id.isEmpty) {
      try {
        // 4. Deneme: IsoDep (Bazı kimlik kartları)
        final isoDep = IsoDepAndroid.from(tag);
        id = isoDep?.identifier;
      } catch (e) {
        debugPrint('IsoDep okuma hatası: $e');
      }
    }

    if (id == null || id.isEmpty) return null;
    
    // Gelen byte dizisini hex string'e çevir (örn: "a1b2c3d4")
    return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
  }
}
