import 'package:flutter/foundation.dart';

class AppLogger {
  // Fungsi statis untuk menggantikan print()
  static void log(dynamic message) {
    // Fungsi ini HANYA akan berjalan jika kDebugMode bernilai true (mode debug/profile)
    if (kDebugMode) {
      // ignore: avoid_print
      print('APP LOG: $message');
    }
  }
}
