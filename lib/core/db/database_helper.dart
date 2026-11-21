import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';
import '../utils/hash_util.dart';
import '../utils/tarih_util.dart';
import '../../models/kullanici.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _ac();
    return _db!;
  }

  Future<Database> _ac() async {
    final yol = p.join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      yol,
      version: AppConstants.dbVersion,
      onConfigure: (d) async {
        await d.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _olustur,
    );
  }

  Future<void> _olustur(Database d, int v) async {
    await d.execute('''
      CREATE TABLE kullanicilar(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_adi TEXT UNIQUE NOT NULL,
        parola_hash TEXT NOT NULL,
        tuz TEXT NOT NULL,
        rol TEXT NOT NULL DEFAULT 'yonetici',
        olusturma_tarihi TEXT NOT NULL
      )
    ''');

    await d.execute('''
      CREATE TABLE vardiyalar(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad TEXT NOT NULL,
        baslangic_saat TEXT NOT NULL,
        bitis_saat TEXT NOT NULL,
        tolerans_giris_dk INTEGER NOT NULL DEFAULT 15,
        tolerans_cikis_dk INTEGER NOT NULL DEFAULT 15,
        gece_vardiyasi INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await d.execute('''
      CREATE TABLE personeller(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad_soyad TEXT NOT NULL,
        kart_uid TEXT UNIQUE,
        kart_aktif INTEGER NOT NULL DEFAULT 1,
        foto_yol TEXT,
        vardiya_id INTEGER,
        ozel_vardiya_id INTEGER,
        ise_giris_tarihi TEXT,
        aktif INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(vardiya_id) REFERENCES vardiyalar(id) ON DELETE SET NULL,
        FOREIGN KEY(ozel_vardiya_id) REFERENCES vardiyalar(id) ON DELETE SET NULL
      )
    ''');

    await d.execute('''
      CREATE TABLE kayitlar(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personel_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        giris_saati TEXT,
        cikis_saati TEXT,
        durum TEXT NOT NULL DEFAULT 'normal',
        manuel_duzeltme INTEGER NOT NULL DEFAULT 0,
        duzeltme_notu TEXT,
        olusturma_ts TEXT NOT NULL,
        FOREIGN KEY(personel_id) REFERENCES personeller(id) ON DELETE CASCADE
      )
    ''');
    await d.execute('CREATE INDEX idx_kayit_personel_tarih ON kayitlar(personel_id, tarih)');
    await d.execute('CREATE INDEX idx_kayit_tarih ON kayitlar(tarih)');
    await d.execute('CREATE INDEX idx_personel_kart ON personeller(kart_uid)');

    await d.execute('''
      CREATE TABLE izinler(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personel_id INTEGER NOT NULL,
        baslangic_tarih TEXT NOT NULL,
        bitis_tarih TEXT NOT NULL,
        tur TEXT NOT NULL,
        aciklama TEXT,
        FOREIGN KEY(personel_id) REFERENCES personeller(id) ON DELETE CASCADE
      )
    ''');
    await d.execute('CREATE INDEX idx_izin_personel ON izinler(personel_id, baslangic_tarih)');

    await d.execute('''
      CREATE TABLE tatiller(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarih TEXT UNIQUE NOT NULL,
        ad TEXT NOT NULL,
        tur TEXT NOT NULL
      )
    ''');

    await d.execute('''
      CREATE TABLE fazla_mesai(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personel_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        dakika INTEGER NOT NULL,
        kaynak TEXT NOT NULL DEFAULT 'otomatik',
        FOREIGN KEY(personel_id) REFERENCES personeller(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE audit_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_id INTEGER,
        islem TEXT NOT NULL,
        detay TEXT,
        ts TEXT NOT NULL
      )
    ''');

    await d.execute('''
      CREATE TABLE ayarlar(
        anahtar TEXT PRIMARY KEY,
        deger TEXT
      )
    ''');

    await _varsayilanVeri(d);
  }

  Future<void> _varsayilanVeri(Database d) async {
    // Varsayılan vardiyalar
    await d.insert('vardiyalar', {
      'ad': 'Sabah 08:00 - 17:00',
      'baslangic_saat': '08:00',
      'bitis_saat': '17:00',
      'tolerans_giris_dk': 15,
      'tolerans_cikis_dk': 15,
      'gece_vardiyasi': 0,
    });
    await d.insert('vardiyalar', {
      'ad': 'Gece 22:00 - 06:00',
      'baslangic_saat': '22:00',
      'bitis_saat': '06:00',
      'tolerans_giris_dk': 15,
      'tolerans_cikis_dk': 15,
      'gece_vardiyasi': 1,
    });

    // Varsayılan yönetici: admin / admin123
    final tuz = HashUtil.tuzUret();
    final hash = HashUtil.parolaHash('admin123', tuz);
    await d.insert('kullanicilar', Kullanici(
      kullaniciAdi: 'admin',
      parolaHash: hash,
      tuz: tuz,
      rol: 'yonetici',
      olusturmaTarihi: TarihUtil.tarihStr(DateTime.now()),
    ).toMap());

    // Varsayılan ayarlar
    await d.insert('ayarlar', {'anahtar': 'ilk_giris', 'deger': '1'});
  }

  Future<void> kapat() async {
    await _db?.close();
    _db = null;
  }
}