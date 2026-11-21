import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../core/db/database_helper.dart';

class YedekService {
  YedekService._();
  static final YedekService instance = YedekService._();

  /// Tüm tabloları JSON olarak dışa aktarır ve paylaşır.
  Future<void> yedekAl() async {
    final db = await DatabaseHelper.instance.db;
    final tablolar = [
      'kullanicilar', 'vardiyalar', 'personeller', 'kayitlar',
      'izinler', 'tatiller', 'fazla_mesai', 'audit_log', 'ayarlar',
    ];
    final Map<String, dynamic> yedek = {
      'versiyon': 1,
      'olusturma': DateTime.now().toIso8601String(),
      'tablolar': <String, dynamic>{},
    };
    for (final t in tablolar) {
      final satirlar = await db.query(t);
      yedek['tablolar'][t] = satirlar;
    }

    final dir = await getTemporaryDirectory();
    final dosya = File(p.join(dir.path,
        'yedek_${DateTime.now().millisecondsSinceEpoch}.json'));
    await dosya.writeAsString(const JsonEncoder.withIndent('  ').convert(yedek));

    await Share.shareXFiles(
      [XFile(dosya.path, mimeType: 'application/json')],
      subject: 'İşyeri Takip Yedeği',
    );
  }

  /// JSON metnini içeri aktarır. Başarıyla aktarılan tablo sayısını döner.
  /// İçe aktarma öncesi tüm veriler silinir (kullanıcı tabloları hariç).
  Future<int> yedekYukle(String jsonMetin) async {
    final Map<String, dynamic> yedek = jsonDecode(jsonMetin) as Map<String, dynamic>;
    final tablolar = yedek['tablolar'] as Map<String, dynamic>?;
    if (tablolar == null) {
      throw Exception('Geçersiz yedek dosyası: "tablolar" anahtarı yok');
    }

    final db = await DatabaseHelper.instance.db;
    int yuklenen = 0;

    await db.transaction((txn) async {
      // Kullanıcıları KORU (mevcut admin girişi bozulmasın).
      // Kullanıcı yedeği içe aktarılmak istenirse ayrı bir "restore" gerekir.
      // İş sırası: önce bağımlı tablolar silinir.
      await txn.delete('fazla_mesai');
      await txn.delete('audit_log');
      await txn.delete('kayitlar');
      await txn.delete('izinler');
      await txn.delete('tatiller');
      await txn.delete('personeller');
      await txn.delete('vardiyalar');
      await txn.delete('ayarlar');

      // Sıra: bağımsızdan bağımlıya
      const sira = [
        'vardiyalar', 'personeller', 'kayitlar', 'izinler',
        'tatiller', 'fazla_mesai', 'audit_log', 'ayarlar',
      ];
      for (final t in sira) {
        final satirlar = tablolar[t];
        if (satirlar is! List) continue;
        for (final satir in satirlar) {
          if (satir is Map<String, dynamic>) {
            try {
              // ignore: avoid_dynamic_calls
              await txn.insert(t, Map<String, dynamic>.from(satir));
            } catch (e) {
              debugPrint('Yedek yükleme: $t satırı atlandı ($e)');
            }
          }
        }
        yuklenen++;
      }
    });

    return yuklenen;
  }

  /// Uygulamanın yerel veritabanı dosyasının yolunu döner.
  Future<String> dbDosyaYolu() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'isyeri_takip.db');
  }
}
