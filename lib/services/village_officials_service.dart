import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'package:desaku/utils/app_logger.dart';

class VillageOfficialsService {
  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>?> getVillageOfficials() async {
    try {
      final headers = ApiConfig.headers;
      final url = '${ApiConfig.baseUrl}/api/public/village-officials';

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['data'] is List) {
          final List officials = response.data['data'];
          if (officials.isNotEmpty) {
            for (final official in officials) {
              if (official is Map && official['is_active'] == true) {
                return Map<String, dynamic>.from(official);
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.log('Error getting village officials: $e');
      return null;
    }
  }
}
