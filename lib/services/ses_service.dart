import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum KioskSes { basarili, uyari, hata }

class SesService {
  SesService._();
  static final SesService instance = SesService._();

  final AudioPlayer _player = AudioPlayer();
  bool _hazir = false;

  Future<void> _hazirla() async {
    if (_hazir) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      _hazir = true;
    } catch (e) {
      debugPrint('SesService: init hatası: $e');
    }
  }

  Future<void> cal(KioskSes ses) async {
    await _hazirla();
    final dosya = switch (ses) {
      KioskSes.basarili => 'sounds/basarili.wav',
      KioskSes.uyari    => 'sounds/uyari.wav',
      KioskSes.hata     => 'sounds/hata.wav',
    };
    try {
      await _player.stop();
      await _player.play(AssetSource(dosya));
    } catch (e) {
      // Ses dosyası yoksa sessizce geç — uygulama bozulmasın.
      debugPrint('SesService: $dosya çalınamadı: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}