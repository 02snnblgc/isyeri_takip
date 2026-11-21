import 'package:intl/intl.dart';

class TarihUtil {
  TarihUtil._();

  static final DateFormat _tarih = DateFormat('yyyy-MM-dd');
  static final DateFormat _saat = DateFormat('HH:mm:ss');
  static final DateFormat _saatKisa = DateFormat('HH:mm');
  static final DateFormat _uzunTarih = DateFormat('dd MMMM yyyy EEEE', 'tr_TR');

  static String tarihStr(DateTime d) => _tarih.format(d);
  static String saatStr(DateTime d) => _saat.format(d);
  static String saatKisaStr(DateTime d) => _saatKisa.format(d);
  static String uzunTarihStr(DateTime d) => _uzunTarih.format(d);

  static DateTime? tarihParse(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

  /// "HH:mm:ss" veya "HH:mm" → gün içi dakika (0..1439)
  static int? saatDakika(String? s) {
    if (s == null || s.isEmpty) return null;
    final p = s.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// "HH:mm" → dakika
  static int saatDakikaFromHm(String hm) => saatDakika('$hm:00') ?? 0;

  /// iki "HH:mm[:ss]" arasındaki dakika farkı (b - a). Gece geçişi için
  /// negatifse +1440 ekler (ertesi gün kabul eder).
  static int farkDakika(String a, String b, {bool geceGecisi = false}) {
    final da = saatDakika(a) ?? 0;
    final db = saatDakika(b) ?? 0;
    var fark = db - da;
    if (fark < 0 && geceGecisi) fark += 1440;
    return fark;
  }

  static bool ayniGun(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}