import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/app_theme.dart';
import '../config/api_config.dart';
import 'package:desaku/utils/app_logger.dart';

class AppThemeService {
  // Mengambil tema yang sedang aktif dari API
  static Future<AppTheme> getActiveTheme() async {
    // 💡 PERBAIKAN: Mengembalikan path ke 'app-themes/active' (dengan 's')
    const apiPath = '/api/app-themes/active';
    final url = Uri.parse('${ApiConfig.baseUrl}$apiPath');

    AppLogger.log('Fetching active theme from: $url');

    try {
      // Menghapus .timeout agar tidak error saat Postman berhasil
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      AppLogger.log('Theme API response status: ${response.statusCode}');

      // Jika server mengembalikan 404, kita kembalikan default.
      if (response.statusCode != 200) {
        AppLogger.log(
          'Warning: Failed to fetch active theme. Status: ${response.statusCode}',
        );
        return AppTheme.defaultTheme;
      }

      final Map<String, dynamic> data = json.decode(response.body);

      // Sesuai screenshot Postman, data tema berada di dalam wrapper 'data'
      if (data['data'] != null) {
        AppLogger.log('Theme fetched successfully from API.');
        return AppTheme.fromJson(data['data']);
      }

      AppLogger.log('Warning: Data field is missing from API response.');
      return AppTheme.defaultTheme;
    } catch (e) {
      AppLogger.log('Error fetching active theme: $e');
      return AppTheme.defaultTheme;
    }
  }
}
