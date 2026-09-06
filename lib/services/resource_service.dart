// lib/services/resource_service.dart (MODIFIED)

import 'package:dio/dio.dart';
import '../config/dio_config.dart';

class ResourceService {
  static final Dio _dio = DioConfig.dio;

  static Future<List<dynamic>> list({
    int perPage = 6,
    bool? isActive,
    String? search,
  }) async {
    final params = <String, dynamic>{'per_page': perPage};
    if (isActive != null) params['is_active'] = isActive;
    if (search != null) params['search'] = search;

    try {
      // Endpoint publik: /api/public/resources
      final resp = await _dio.get(
        '/api/public/resources',
        queryParameters: params,
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['data'] is List) {
          return List<dynamic>.from(data['data']);
        }
        return [];
      }
      throw Exception('Failed to fetch resources: Status ${resp.statusCode}');
    } on DioException catch (e) {
      throw Exception('Failed to fetch resources: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> getDetail(int id) async {
    try {
      // PERBAIKAN: Mengubah endpoint dari /api/resources/$id menjadi PUBLIK
      final resp = await _dio.get('/api/public/resources/$id');

      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['success'] == true && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception(
          data['message'] ?? 'Gagal mengambil detail sumber daya alam',
        );
      }

      throw Exception(
        'Gagal memuat detail sumber daya alam: Status ${resp.statusCode}',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 404) {
        throw Exception('Sumber daya alam tidak ditemukan');
      }
      if (statusCode == 401) {
        throw Exception(
            'Gagal memuat detail: Status 401. Pastikan endpoint benar-benar publik.');
      }
      throw Exception('Terjadi kesalahan: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }
}
