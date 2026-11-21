import 'package:flutter/foundation.dart';
import '../models/vardiya.dart';
import '../services/db_service.dart';

class VardiyaProvider extends ChangeNotifier {
  List<Vardiya> _vardiyalar = [];
  bool _yukleniyor = false;
  String? _hata;

  List<Vardiya> get vardiyalar => _vardiyalar;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;

  Future<void> yukle() async {
    _yukleniyor = true; _hata = null; notifyListeners();
    try {
      _vardiyalar = await DbService.instance.vardiyalariGetir();
    } catch (e) {
      _hata = 'Yükleme hatası: $e';
    }
    _yukleniyor = false;
    notifyListeners();
  }

  Future<String?> ekle(Vardiya v) async {
    try {
      await DbService.instance.vardiyaEkle(v);
      await yukle();
      return null;
    } catch (e) {
      return 'Ekleme hatası: $e';
    }
  }

  Future<String?> guncelle(Vardiya v) async {
    try {
      await DbService.instance.vardiyaGuncelle(v);
      await yukle();
      return null;
    } catch (e) {
      return 'Güncelleme hatası: $e';
    }
  }

  Future<String?> sil(int id) async {
    try {
      await DbService.instance.vardiyaSil(id);
      await yukle();
      return null;
    } catch (e) {
      return 'Silme hatası: $e (bu vardiyaya atanmış personel olabilir)';
    }
  }
}