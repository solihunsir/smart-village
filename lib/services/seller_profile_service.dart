import 'package:dio/dio.dart';
import 'package:desaku/utils/app_logger.dart';
import '../config/api_config.dart';
import '../config/dio_config.dart';

class SellerProfileService {
  static final Dio _dio = DioConfig.createDio();
  static Future<Map<String, dynamic>?> getSellerProfile({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/seller-profile',
        options: Options(headers: ApiConfig.headersWithAuth(token)),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        // Some APIs may return data directly without success flag
        if (data is Map && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        if (data is Map && data.isNotEmpty) {
          return Map<String, dynamic>.from(data);
        }
      }
      return null;
    } on DioException catch (e) {
      // Treat 404 as no seller profile yet
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  static Future<bool> createSellerProfile({
    required String token,
    required String nik,
  }) async {
    try {
      final payload = {
        'nik': nik,
      };

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/seller-profile',
        data: payload,
        options: Options(headers: ApiConfig.headersWithAuth(token)),
      );

      final code = response.statusCode ?? 0;
      if (code == 200 || code == 201) {
        final data = response.data;
        if (data is Map && data['success'] == true) return true;
        // fallback if API doesn't use success flag
        return true;
      }
      return false;
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 409 || code == 422) {
        AppLogger.log(
            'SellerProfileService.createSellerProfile: received $code — treating as success/existing profile.');
        return true;
      }
      rethrow;
    }
  }
}
