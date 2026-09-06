import 'package:flutter/material.dart';

// Helper function untuk mengkonversi string hex color (misalnya '#RRGGBB' atau 'RRGGBB') menjadi Color
Color _colorFromHex(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return const Color(0xFF00C853); // Default Green
  }

  String hexCode = hexColor.replaceAll('#', '').toUpperCase();
  // Ensure we only process RRGGBB (6 chars)
  if (hexCode.length == 8) {
    hexCode = hexCode.substring(2); // Remove leading Alpha if present
  }

  if (hexCode.length == 6) {
    try {
      // Tambahkan nilai alpha FF (opaque) di depan RRGGBB
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (_) {
      // Fallback jika parsing gagal
      return const Color(0xFF00C853);
    }
  }
  // Fallback ke warna hijau standar jika format salah
  return const Color(0xFF00C853);
}

class AppTheme {
  final int id;
  final String name;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  // Warna yang sudah dikonversi ke tipe Color Flutter (digunakan di UI)
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  AppTheme({
    required this.id,
    required this.name,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.accentColorHex,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : primaryColor = _colorFromHex(primaryColorHex),
       secondaryColor = _colorFromHex(secondaryColorHex),
       accentColor = _colorFromHex(accentColorHex);

  factory AppTheme.fromJson(Map<String, dynamic> json) {
    // 💡 PERBAIKAN: Mengambil field dengan nama 'primary_colour' dan 'secondary_colour'
    final primary = json['primary_colour'] as String? ?? '#00C853';
    final secondary = json['secondary_colour'] as String? ?? '#00A310';
    final accent =
        json['accent_color'] as String? ??
        '#FF9800'; // Asumsi accent_color tetap

    return AppTheme(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Default Theme',
      primaryColorHex: primary,
      secondaryColorHex: secondary,
      accentColorHex: accent,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  // Objek tema default statis untuk digunakan sebagai fallback atau loading state
  static AppTheme defaultTheme = AppTheme(
    id: 0,
    name: 'Default',
    primaryColorHex: '#00C853', // Green 600 (Primary)
    secondaryColorHex: '#00A310', // Darker Green (Banner, Indicator)
    accentColorHex: '#FF9800', // Amber/Orange (Accent)
    isActive: true,
    createdAt: '',
    updatedAt: '',
  );
}
