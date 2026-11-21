import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/tema_provider.dart';
import 'screens/ana_screen.dart';
import 'screens/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'İşyeri Takip',
      debugShowCheckedModeBanner: false,
      theme: tema.lightTheme,
      darkTheme: tema.darkTheme,
      themeMode: tema.mod,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: auth.girisYapildi ? const AnaScreen() : const LoginScreen(),
    );
  }
}