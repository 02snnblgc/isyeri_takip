import '../core/utils/tarih_util.dart';
import '../models/vardiya.dart';

enum GirisDurum { normal, gec }
enum CikisDurum { normal, erken }

class MesaiHesapService {
  MesaiHesapService._();
  static final MesaiHesapService instance = MesaiHesapService._();

  /// Giriş saatini vardiyaya göre değerlendirir.
  /// dönüş: (durum, gecikmeDakika)
  (GirisDurum, int) girisDegerlendir(String girisSaat, Vardiya v) {
    final fark = TarihUtil.farkDakika(
      v.baslangicSaat, girisSaat, geceGecisi: false);
    if (fark > v.toleransGirisDk) {
      return (GirisDurum.gec, fark - v.toleransGirisDk);
    }
    return (GirisDurum.normal, 0);
  }

  /// Çıkış saatini vardiyaya göre değerlendirir.
  /// dönüş: (durum, erkenCikisDakika)
  (CikisDurum, int) cikisDegerlendir(String cikisSaat, Vardiya v) {
    // Vardiya bitişine göre çıkış erken mi?
    // Gece vardiyasında (22:00-06:00) çıkış ertesi gün olabilir.
    // Bu nedenle fark: bitis -> cikis, gece geçişini hesaba kat.
    int fark = TarihUtil.farkDakika(
        v.bitisSaat, cikisSaat, geceGecisi: v.geceVardiyasi);
    if (fark < 0 && !v.geceVardiyasi) {
      // Çıkış, bitişten önce → erken
      final erken = -fark;
      if (erken > v.toleransCikisDk) {
        return (CikisDurum.erken, erken - v.toleransCikisDk);
      }
      return (CikisDurum.normal, 0);
    }
    // Çıkış, bitişten sonra veya tam zamanında → normal
    return (CikisDurum.normal, 0);
  }

  /// Fazla mesai: çıkış, vardiya bitişinden ne kadar sonra?
  /// Gece vardiyasında ertesi güne sarkabilir.
  int fazlaMesaiDakika(String cikisSaat, Vardiya v) {
    final fark = TarihUtil.farkDakika(
        v.bitisSaat, cikisSaat, geceGecisi: v.geceVardiyasi);
    return fark > 0 ? fark : 0;
  }

  /// Bir gün için özet durum metni döndürür.
  /// durum: 'normal' | 'gec' | 'erken_cikis' — ikisi birden olabilir
  String ozetDurum(GirisDurum g, CikisDurum c) {
    if (g == GirisDurum.gec && c == CikisDurum.erken) return 'gec';
    if (g == GirisDurum.gec) return 'gec';
    if (c == CikisDurum.erken) return 'erken_cikis';
    return 'normal';
  }
}