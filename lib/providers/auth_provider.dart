import 'package:flutter/material.dart';
import '../models/kullanici.dart';
import '../services/db_service.dart';

class AuthProvider extends ChangeNotifier {
  Kullanici? _kullanici;
  bool _yukleniyor = false;
  String? _hata;

  Kullanici? get kullanici => _kullanici;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;
  bool get girisYapildi => _kullanici != null;
  bool get yoneticiMi => _kullanici?.rol == 'yonetici';

  Future<bool> giris(String kullaniciAdi, String parola) async {
    _yukleniyor = true; _hata = null; notifyListeners();
    try {
      final ok = await DbService.instance.girisDogrula(kullaniciAdi, parola);
      if (!ok) {
        _hata = 'Kullanıcı adı veya parola hatalı';
        _yukleniyor = false; notifyListeners();
        return false;
      }
      _kullanici = await DbService.instance.kullaniciBul(kullaniciAdi);
      // İlk giriş işaretini düşür
      await DbService.instance.ayarYaz('ilk_giris', '0');
      _yukleniyor = false; notifyListeners();
      return true;
    } catch (e) {
      _hata = 'Giriş sırasında hata: $e';
      _yukleniyor = false; notifyListeners();
      return false;
    }
  }

  Future<void> cikis() async {
    _kullanici = null;
    notifyListeners();
  }
}