import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String dbName = 'isyeri_takip.db';
  static const int dbVersion = 1;

  // 5 pastel tema
  static const List<Color> pastelRenkler = [
    Color(0xFFA8E6CF), // Mint
    Color(0xFFD4C4F0), // Lavanta
    Color(0xFFFFD3B6), // Şeftali
    Color(0xFFB6D9F0), // Gökyüzü
    Color(0xFFF0B6C8), // Gül
  ];

  static const List<String> pastelAdlari = [
    'Mint', 'Lavanta', 'Şeftali', 'Gökyüzü', 'Gül',
  ];

  // Kiosk
  static const int mukerrerOkutmaSaniye = 60;
  static const int kioskFeedbackSaniye = 3;

  // Varsayılan toleranslar
  static const int varsayilanToleransGirisDk = 15;
  static const int varsayilanToleransCikisDk = 15;

  // İzin türleri
  static const List<String> izinTurleri = ['yillik', 'rapor', 'mazeret'];

  // Kayıt durumları
  static const String durumNormal = 'normal';
  static const String durumGec = 'gec';
  static const String durumErkenCikis = 'erken_cikis';
  static const String durumGelmedi = 'gelmedi';
  static const String durumIzinli = 'izinli';
  static const String durumRaporlu = 'raporlu';
}