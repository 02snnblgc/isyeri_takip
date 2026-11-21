import 'package:flutter/foundation.dart';
import '../models/izin.dart';
import '../models/personel.dart';
import '../services/db_service.dart';

class IzinProvider extends ChangeNotifier {
  List<Izin> _izinler = [];
  List<Personel> _personeller = [];
  bool _yukleniyor = false;
  String? _hata;

  List<Izin> get izinler => _izinler;
  List<Personel> get personeller => _personeller;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;

  String personelAd(int? id) {
    if (id == null) return '-';
    try {
      return _personeller.firstWhere((p) => p.id == id).adSoyad;
    } catch (_) {
      return '-';
    }
  }

  Future<void> yukle() async {
    _yukleniyor = true; _hata = null; notifyListeners();
    try {
      _personeller = await DbService.instance.personelleriGetir();
      _izinler = await DbService.instance.izinleriGetir();
    } catch (e) {
      _hata = 'Yükleme hatası: $e';
    }
    _yukleniyor = false;
    notifyListeners();
  }

  Future<String?> ekle(Izin i) async {
    try {
      await DbService.instance.izinEkle(i);
      await yukle();
      return null;
    } catch (e) {
      return 'Ekleme hatası: $e';
    }
  }

  Future<String?> sil(int id) async {
    try {
      await DbService.instance.izinSil(id);
      await yukle();
      return null;
    } catch (e) {
      return 'Silme hatası: $e';
    }
  }
}