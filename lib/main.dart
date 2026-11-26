import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/izin_provider.dart';
import 'providers/kiosk_provider.dart';
import 'providers/personel_provider.dart';
import 'providers/tatil_provider.dart';
import 'providers/tema_provider.dart';
import 'providers/vardiya_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  final tema = TemaProvider();
  await tema.yukle();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tema),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PersonelProvider()),
        ChangeNotifierProvider(create: (_) => KioskProvider()),
        ChangeNotifierProvider(create: (_) => IzinProvider()),
        ChangeNotifierProvider(create: (_) => TatilProvider()),
        ChangeNotifierProvider(create: (_) => VardiyaProvider()),
      ],
      child: const App(),
    ),
  );
}
