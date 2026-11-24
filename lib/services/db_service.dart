import 'package:sqflite/sqflite.dart';
import '../core/db/database_helper.dart';
import '../core/utils/hash_util.dart';
import '../core/utils/tarih_util.dart';
import '../models/fazla_mesai.dart';
import '../models/izin.dart';
import '../models/kayit.dart';
import '../models/kullanici.dart';
import '../models/personel.dart';
import '../models/tatil.dart';
import '../models/vardiya.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  Future<Database> get _db => DatabaseHelper.instance.db;

  // ================= AUTH =================
  Future<Kullanici?> kullaniciBul(String kullaniciAdi) async {
    final d = await _db;
    final r = await d.query('kullanicilar',
        where: 'kullanici_adi = ?', whereArgs: [kullaniciAdi], limit: 1);
    return r.isEmpty ? null : Kullanici.fromMap(r.first);
  }

  Future<bool> girisDogrula(String kullaniciAdi, String parola) async {
    final k = await kullaniciBul(kullaniciAdi);
    if (k == null) return false;
    return HashUtil.dogrula(parola, k.tuz, k.parolaHash);
  }

  Future<void> parolaDegistir(int id, String yeniParola) async {
    final d = await _db;
    final tuz = HashUtil.tuzUret();
    await d.update('kullanicilar', {
      'tuz': tuz,
      'parola_hash': HashUtil.parolaHash(yeniParola, tuz),
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ================= VARDİYA =================
  Future<List<Vardiya>> vardiyalariGetir() async {
    final d = await _db;
    final r = await d.query('vardiyalar', orderBy: 'ad ASC');
    return r.map(Vardiya.fromMap).toList();
  }

  Future<int> vardiyaEkle(Vardiya v) async {
    final d = await _db;
    return d.insert('vardiyalar', v.toMap());
  }

  Future<void> vardiyaGuncelle(Vardiya v) async {
    final d = await _db;
    await d.update('vardiyalar', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
  }

  Future<void> vardiyaSil(int id) async {
    final d = await _db;
    await d.delete('vardiyalar', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PERSONEL =================
  Future<List<Personel>> personelleriGetir({
    String? arama,
    bool sadeceAktif = true,
  }) async {
    final d = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (sadeceAktif) where.add('aktif = 1');
    if (arama != null && arama.trim().isNotEmpty) {
      where.add('ad_soyad LIKE ?');
      args.add('%${arama.trim()}%');
    }
    final r = await d.query('personeller',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'ad_soyad COLLATE NOCASE ASC');
    return r.map(Personel.fromMap).toList();
  }

  Future<Personel?> personelGetir(int id) async {
    final d = await _db;
    final r = await d.query('personeller',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Personel.fromMap(r.first);
  }

  Future<Personel?> personelKartUidIle(String uid) async {
    final d = await _db;
    final r = await d.query('personeller',
        where: 'kart_uid = ? AND kart_aktif = 1', whereArgs: [uid], limit: 1);
    return r.isEmpty ? null : Personel.fromMap(r.first);
  }

  Future<bool> kartUidKullanimdaMi(String uid, {int? haricId}) async {
    final d = await _db;
    final r = await d.query('personeller',
        where: 'kart_uid = ?${haricId != null ? ' AND id != ?' : ''}',
        whereArgs: haricId != null ? [uid, haricId] : [uid], limit: 1);
    return r.isNotEmpty;
  }

  Future<int> personelEkle(Personel p) async {
    final d = await _db;
    return d.insert('personeller', p.toMap());
  }

  Future<void> personelGuncelle(Personel p) async {
    final d = await _db;
    await d.update('personeller', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> personelSil(int id) async {
    final d = await _db;
    await d.delete('personeller', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> personelPasifYap(int id) async {
    final d = await _db;
    await d.update('personeller', {'aktif': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> kartAktiflik(int personelId, bool aktif) async {
    final d = await _db;
    await d.update('personeller', {'kart_aktif': aktif ? 1 : 0},
        where: 'id = ?', whereArgs: [personelId]);
  }

  Future<void> kartUidTemizle(int personelId) async {
    final d = await _db;
    await d.update('personeller', {'kart_uid': null},
        where: 'id = ?', whereArgs: [personelId]);
  }

  // ================= KAYIT =================
  Future<Kayit?> kayitGetir(int personelId, String tarih) async {
    final d = await _db;
    final r = await d.query('kayitlar',
        where: 'personel_id = ? AND tarih = ?',
        whereArgs: [personelId, tarih],
        orderBy: 'id DESC', limit: 1);
    return r.isEmpty ? null : Kayit.fromMap(r.first);
  }

  Future<Kayit?> acikGirisGetir(int personelId) async {
    final d = await _db;
    final r = await d.query('kayitlar',
        where: 'personel_id = ? AND giris_saati IS NOT NULL AND cikis_saati IS NULL',
        whereArgs: [personelId],
        orderBy: 'id DESC', limit: 1);
    return r.isEmpty ? null : Kayit.fromMap(r.first);
  }

  Future<bool> sonOkutmaMukerrer(int personelId, {int saniye = 60}) async {
    final d = await _db;
    final esik = DateTime.now()
        .subtract(Duration(seconds: saniye))
        .toIso8601String();
    final r = await d.query('kayitlar',
        where: 'personel_id = ? AND olusturma_ts > ?',
        whereArgs: [personelId, esik], limit: 1);
    return r.isNotEmpty;
  }

  Future<int> kayitEkle(Kayit k) async {
    final d = await _db;
    return d.insert('kayitlar', k.toMap());
  }

  Future<void> kayitGuncelle(Kayit k) async {
    final d = await _db;
    await d.update('kayitlar', k.toMap(),
        where: 'id = ?', whereArgs: [k.id]);
  }

  Future<List<Map<String, dynamic>>> kayitlariGetir({
    required String baslangic,
    required String bitis,
    int? personelId,
  }) async {
    final d = await _db;
    final where = <String>['k.tarih >= ?', 'k.tarih <= ?'];
    final args = <Object?>[baslangic, bitis];
    if (personelId != null) {
      where.add('k.personel_id = ?');
      args.add(personelId);
    }
    final r = await d.rawQuery('''
      SELECT k.*, p.ad_soyad, p.vardiya_id, p.ozel_vardiya_id
      FROM kayitlar k
      INNER JOIN personeller p ON p.id = k.personel_id
      WHERE ${where.join(' AND ')}
      ORDER BY k.tarih DESC, p.ad_soyad ASC
    ''', args);
    return r;
  }

  Future<int> iceridekiSayisi(String tarih) async {
    final d = await _db;
    final r = await d.rawQuery('''
      SELECT COUNT(DISTINCT personel_id) as c FROM kayitlar
      WHERE tarih = ? AND giris_saati IS NOT NULL AND cikis_saati IS NULL
    ''', [tarih]);
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> erkenCikanSayisi(String tarih) async {
    final d = await _db;
    final r = await d.query('kayitlar',
        where: 'tarih = ? AND durum = ? AND cikis_saati IS NOT NULL',
        whereArgs: [tarih, 'erken_cikis']);
    return r.length;
  }

  // ================= FAZLA MESAİ =================
  Future<void> fazlaMesaiEkle(FazlaMesai f) async {
    final d = await _db;
    final mevcut = await d.query('fazla_mesai',
        where: 'personel_id = ? AND tarih = ?',
        whereArgs: [f.personelId, f.tarih], limit: 1);
    if (mevcut.isEmpty) {
      await d.insert('fazla_mesai', f.toMap());
    } else {
      await d.update('fazla_mesai', {'dakika': f.dakika, 'kaynak': f.kaynak},
          where: 'id = ?', whereArgs: [mevcut.first['id']]);
    }
  }

  Future<int> gunlukFazlaMesaiDk(int personelId, String tarih) async {
    final d = await _db;
    final r = await d.query('fazla_mesai',
        where: 'personel_id = ? AND tarih = ?',
        whereArgs: [personelId, tarih], limit: 1);
    return r.isEmpty ? 0 : (r.first['dakika'] as int? ?? 0);
  }

  // ================= İZİN =================
  Future<List<Izin>> izinleriGetir({int? personelId}) async {
    final d = await _db;
    final r = await d.query('izinler',
        where: personelId != null ? 'personel_id = ?' : null,
        whereArgs: personelId != null ? [personelId] : null,
        orderBy: 'baslangic_tarih DESC');
    return r.map(Izin.fromMap).toList();
  }

  Future<int> izinEkle(Izin i) async {
    final d = await _db;
    return d.insert('izinler', i.toMap());
  }

  Future<void> izinSil(int id) async {
    final d = await _db;
    await d.delete('izinler', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> personelIzinTuru(int personelId, String tarih) async {
    final d = await _db;
    final r = await d.query('izinler',
        where: 'personel_id = ? AND baslangic_tarih <= ? AND bitis_tarih >= ?',
        whereArgs: [personelId, tarih, tarih],
        orderBy: 'baslangic_tarih DESC', limit: 1);
    return r.isEmpty ? null : r.first['tur'] as String;
  }

  Future<Set<int>> tarihteIzinliPersonelIdler(String tarih) async {
    final d = await _db;
    final r = await d.query('izinler',
        where: 'baslangic_tarih <= ? AND bitis_tarih >= ?',
        whereArgs: [tarih, tarih]);
    return r.map((m) => m['personel_id'] as int).toSet();
  }

  // ================= TATİL =================
  Future<List<Tatil>> tatilleriGetir() async {
    final d = await _db;
    final r = await d.query('tatiller', orderBy: 'tarih ASC');
    return r.map(Tatil.fromMap).toList();
  }

  Future<int> tatilEkle(Tatil t) async {
    final d = await _db;
    return d.insert('tatiller', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> tatilSil(int id) async {
    final d = await _db;
    await d.delete('tatiller', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> tarihteTatilMi(String tarih) async {
    final d = await _db;
    final r = await d.query('tatiller',
        where: 'tarih = ?', whereArgs: [tarih], limit: 1);
    return r.isNotEmpty;
  }

  Future<bool> haftaSonuTatilAktif() async {
    final v = await ayarOku('hafta_sonu_tatil');
    return v == null || v == '1';
  }

  Future<bool> tarihTatilMi(String tarih, {bool haftaSonuDahil = true}) async {
    final d = await _db;
    final r = await d.query('tatiller',
        where: 'tarih = ?', whereArgs: [tarih], limit: 1);
    if (r.isNotEmpty) return true;
    if (!haftaSonuDahil) return false;
    if (!await haftaSonuTatilAktif()) return false;
    final dt = TarihUtil.tarihParse(tarih);
    if (dt == null) return false;
    return dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
  }

  // ================= GELMEYEN =================
  Future<List<Personel>> bugunGelmeyenler(String tarih) async {
    if (await tarihTatilMi(tarih)) return [];
    final d = await _db;
    final izinliIdler = await tarihteIzinliPersonelIdler(tarih);
    final r = await d.rawQuery('''
      SELECT p.* FROM personeller p
      WHERE p.aktif = 1
        AND p.id NOT IN (
          SELECT personel_id FROM kayitlar
          WHERE tarih = ? AND giris_saati IS NOT NULL
        )
    ''', [tarih]);
    final hepsi = r.map(Personel.fromMap).toList();
    return hepsi.where((p) => !izinliIdler.contains(p.id)).toList();
  }

  Future<List<Personel>> tarihteIzinliler(String tarih) async {
    final ids = await tarihteIzinliPersonelIdler(tarih);
    if (ids.isEmpty) return [];
    final d = await _db;
    final yer = List.filled(ids.length, '?').join(',');
    final r = await d.query('personeller',
        where: 'id IN ($yer)', whereArgs: ids.toList());
    return r.map(Personel.fromMap).toList();
  }

  // ================= KAYIT DÜZELTME (MANUEL) =================
  Future<void> acikGirisiManuelKapat({
    required int kayitId,
    required String yeniCikisSaati,
    String? not,
    int? kullaniciId,
  }) async {
    final d = await _db;
    await d.update('kayitlar', {
      'cikis_saati': yeniCikisSaati,
      'manuel_duzeltme': 1,
      'duzeltme_notu': not,
    }, where: 'id = ?', whereArgs: [kayitId]);
    
    // DÜZELTME: DbService.instance yerine doğrudan auditYaz
    await auditYaz(kullaniciId, 'manuel_cikis_duzeltme',
        'kayit#$kayitId → çıkış $yeniCikisSaati');
  }

  Future<void> kayitManuelGuncelle({
    required int kayitId,
    String? yeniGiris,
    String? yeniCikis,
    String? not,
    int? kullaniciId,
  }) async {
    final d = await _db;
    final guncel = <String, Object?>{
      'manuel_duzeltme': 1,
      'duzeltme_notu': not,
    };
    if (yeniGiris != null) guncel['giris_saati'] = yeniGiris;
    if (yeniCikis != null) guncel['cikis_saati'] = yeniCikis;
    await d.update('kayitlar', guncel, where: 'id = ?', whereArgs: [kayitId]);
    
    // DÜZELTME: DbService.instance yerine doğrudan auditYaz
    await auditYaz(kullaniciId, 'manuel_kayit_guncelle',
        'kayit#$kayitId → giriş=$yeniGiris çıkış=$yeniCikis');
  }

  Future<List<Map<String, dynamic>>> acikGirisleriGetir() async {
    final d = await _db;
    return d.rawQuery('''
      SELECT k.*, p.ad_soyad
      FROM kayitlar k
      INNER JOIN personeller p ON p.id = k.personel_id
      WHERE k.giris_saati IS NOT NULL AND k.cikis_saati IS NULL
      ORDER BY k.tarih DESC, k.giris_saati ASC
    ''');
  }

  // ================= AUDIT LİSTE =================
  Future<List<Map<String, dynamic>>> auditLoglariGetir({int limit = 200}) async {
    final d = await _db;
    return d.rawQuery('''
      SELECT a.*, u.kullanici_adi
      FROM audit_log a
      LEFT JOIN kullanicilar u ON u.id = a.kullanici_id
      ORDER BY a.id DESC
      LIMIT ?
    ''', [limit]);
  }

  // ================= RAPOR SORGULARI =================
  Future<List<Map<String, dynamic>>> raporSatirlari({
    required String baslangic,
    required String bitis,
    int? personelId,
  }) async {
    final d = await _db;
    final where = <String>['k.tarih >= ?', 'k.tarih <= ?'];
    final args = <Object?>[baslangic, bitis];
    if (personelId != null) {
      where.add('k.personel_id = ?');
      args.add(personelId);
    }
    return d.rawQuery('''
      SELECT
        k.tarih, p.ad_soyad, v.ad AS vardiya_adi,
        v.baslangic_saat, v.bitis_saat,
        k.giris_saati, k.cikis_saati, k.durum,
        k.manuel_duzeltme, k.duzeltme_notu,
        COALESCE(fm.dakika, 0) AS fazla_mesai_dk
      FROM kayitlar k
      INNER JOIN personeller p ON p.id = k.personel_id
      LEFT JOIN vardiyalar v ON v.id = COALESCE(p.ozel_vardiya_id, p.vardiya_id)
      LEFT JOIN fazla_mesai fm ON fm.personel_id = k.personel_id AND fm.tarih = k.tarih
      WHERE ${where.join(' AND ')}
      ORDER BY k.tarih DESC, p.ad_soyad ASC
    ''', args);
  }

  // ================= AYAR =================
  Future<String?> ayarOku(String anahtar) async {
    final d = await _db;
    final r = await d.query('ayarlar',
        where: 'anahtar = ?', whereArgs: [anahtar], limit: 1);
    return r.isEmpty ? null : r.first['deger'] as String?;
  }

  Future<void> ayarYaz(String anahtar, String deger) async {
    final d = await _db;
    await d.insert('ayarlar', {'anahtar': anahtar, 'deger': deger},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ================= AUDIT =================
  Future<void> auditYaz(int? kullaniciId, String islem, String? detay) async {
    final d = await _db;
    await d.insert('audit_log', {
      'kullanici_id': kullaniciId,
      'islem': islem,
      'detay': detay,
      'ts': DateTime.now().toIso8601String(),
    });
  }
}