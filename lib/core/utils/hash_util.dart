import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class HashUtil {
  HashUtil._();

  /// Rastgele tuz üretir (16 byte hex).
  static String tuzUret() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// parola + tuz → SHA-256 hash (hex).
  static String parolaHash(String parola, String tuz) {
    final bytes = utf8.encode('$tuz:$parola');
    return sha256.convert(bytes).toString();
  }

  /// Doğrulama.
  static bool dogrula(String parola, String tuz, String beklenenHash) {
    return parolaHash(parola, tuz) == beklenenHash;
  }
}