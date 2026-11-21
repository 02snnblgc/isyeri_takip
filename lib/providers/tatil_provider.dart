import 'package:flutter/foundation.dart';
import '../models/tatil.dart';
import '../services/db_service.dart';

class TatilProvider extends ChangeNotifier {
  List<Tatil> _tatiller = [];
  bool _yukleniyor = false;
  bool _haftaSonuTatil = true;
  String? _hata;

  List<Tatil> get tatiller => _tatiller;
  bool get yukleniyor => _yukleniyor;
  bool get haftaSonuTatil => _haftaSonuTatil;
  String? get hata => _hata;

  Future<void> yukle() async {
    _yukleniyor = true; _hata = null; notifyListeners();
    try {
      _tatiller = await DbService.instance.tatilleriGetir();
      _haftaSonuTatil = await DbService.instance.haftaSonuTatilAktif();
    } catch (e) {
      _hata = 'Yükleme hatası: $e';
    }
    _yukleniyor = false;
    notifyListeners();
  }

  Future<String?> ekle(Tatil t) async {
    try {
      await DbService.instance.tatilEkle(t);
      await yukle();
      return null;
    } catch (e) {
      return 'Ekleme hatası: $e';
    }
  }

  Future<String?> sil(int id) async {
    try {
      await DbService.instance.tatilSil(id);
      await yukle();
      return null;
    } catch (e) {
      return 'Silme hatası: $e';
    }
  }

  Future<void> haftaSonuTatilDegistir(bool deger) async {
    _haftaSonuTatil = deger;
    notifyListeners();
    await DbService.instance.ayarYaz('hafta_sonu_tatil', deger ? '1' : '0');
  }
}