import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class TemaProvider extends ChangeNotifier {
  ThemeMode _mod = ThemeMode.light;
  int _pastelIndex = 0;

  ThemeMode get mod => _mod;
  int get pastelIndex => _pastelIndex;
  Color get pastelRenk => AppConstants.pastelRenkler[_pastelIndex];

  Future<void> yukle() async {
    final p = await SharedPreferences.getInstance();
    _mod = ThemeMode.values[p.getInt('tema_mod') ?? 1];
    _pastelIndex = p.getInt('pastel_idx') ?? 0;
    notifyListeners();
  }

  Future<void> modDegistir(ThemeMode m) async {
    _mod = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('tema_mod', m.index);
  }

  Future<void> pastelDegistir(int i) async {
    _pastelIndex = i.clamp(0, AppConstants.pastelRenkler.length - 1);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('pastel_idx', _pastelIndex);
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pastelRenk, brightness: Brightness.light,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pastelRenk, brightness: Brightness.dark,
        ),
      );
}