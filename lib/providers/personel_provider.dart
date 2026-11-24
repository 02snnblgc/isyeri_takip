import 'package:flutter/foundation.dart';
import '../models/personel.dart';
import '../models/vardiya.dart';
import '../services/db_service.dart';

class PersonelProvider extends ChangeNotifier {
  List<Personel> _personeller = [];
  List<Vardiya> _vardiyalar = [];
  bool _yukleniyor = false;
  String? _hata;

  List<Personel> get personeller => _personeller;
  List<Vardiya> get vardiyalar => _vardiyalar;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;

  Vardiya? vardiyaById(int? id) {
    if (id == null) return null;
    try {
      return _vardiyalar.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> yukle({String? arama}) async {
    _yukleniyor = true; _hata = null; notifyListeners();
    try {
      _vardiyalar = await DbService.instance.vardiyalariGetir();
      _personeller = await DbService.instance.personelleriGetir(arama: arama);
    } catch (e) {
      _hata = 'Yükleme hatası: $e';
    }
    _yukleniyor = false;
    notifyListeners();
  }

  Future<String?> kaydet(Personel p) async {
    try {
      if (p.id == null) {
        await DbService.instance.personelEkle(p);
      } else {
        await DbService.instance.personelGuncelle(p);
      }
      await yukle();
      return null;
    } catch (e) {
      return 'Kaydetme hatası: $e';
    }
  }

  Future<String?> sil(int id) async {
    try {
      await DbService.instance.personelSil(id);
      await yukle();
      return null;
    } catch (e) {
      return 'Silme hatası: $e';
    }
  }

  Future<String?> pasifYap(int id) async {
    try {
      await DbService.instance.personelPasifYap(id);
      await yukle();
      return null;
    } catch (e) {
      return 'İşlem hatası: $e';
    }
  }

  Future<String?> kartAktiflik(int personelId, bool aktif) async {
    try {
      await DbService.instance.kartAktiflik(personelId, aktif);
      await yukle();
      return null;
    } catch (e) {
      return 'Kart güncelleme hatası: $e';
    }
  }

  Future<String?> kartUidTemizle(int personelId) async {
    try {
      await DbService.instance.kartUidTemizle(personelId);
      await yukle();
      return null;
    } catch (e) {
      return 'Kart temizleme hatası: $e';
    }
  }

  /// UID'nin başka personelde olup olmadığını kontrol eder.
  Future<bool> kartUidKullanimda(String uid, {int? haricId}) {
    return DbService.instance.kartUidKullanimdaMi(uid, haricId: haricId);
  }
}
