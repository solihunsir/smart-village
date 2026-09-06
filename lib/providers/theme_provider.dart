import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/app_theme_service.dart';
import 'package:desaku/utils/app_logger.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _theme = AppTheme.defaultTheme;
  bool _isLoading = true; // Set true saat inisialisasi

  AppTheme get theme => _theme;
  bool get isLoading => _isLoading;

  // Memuat tema aktif saat aplikasi dimulai
  Future<void> fetchActiveTheme() async {
    // Hanya panggil API jika belum dimuat dan tidak sedang loading
    if (_isLoading == false && _theme.id != 0) return;

    if (_isLoading == false) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _theme = await AppThemeService.getActiveTheme();
    } catch (e) {
      AppLogger.log('Error in ThemeProvider fetching theme: $e');
      _theme = AppTheme.defaultTheme;
    } finally {
      // Pastikan status loading diakhiri dan notifikasi diberikan
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper untuk akses cepat ke warna utama
  Color get primaryColor => _theme.primaryColor;
  Color get secondaryColor => _theme.secondaryColor;
  Color get accentColor => _theme.accentColor;
}
