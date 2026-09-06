import 'package:desaku/utils/app_logger.dart';
import 'package:dio/dio.dart';
import '../config/dio_config.dart';

class DestinationService {
  static final Dio _dio = DioConfig.dio;

  // --- 1. Fungsi List (PUBLIK) ---
  static Future<List<dynamic>> list({
    int perPage = 6,
    bool? isActive,
    bool? showInProfile,
    String? search,
  }) async {
    final params = <String, dynamic>{'per_page': perPage};
    if (isActive != null) params['is_active'] = isActive;
    if (showInProfile != null) params['show_in_profile'] = showInProfile;
    if (search != null) params['search'] = search;

    try {
      final resp = await _dio.get(
        // Endpoint publik, tidak perlu token
        '/api/public/destinations',
        queryParameters: params,
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['data'] is List) {
          return List<dynamic>.from(data['data']);
        }
        return [];
      }
      throw Exception(
        'Failed to fetch destinations: Status ${resp.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Failed to fetch destinations: ${e.message}');
    }
  }

  // --- 2. Fungsi CountDestinations (PUBLIK) ---
  static Future<int> countDestinations() async {
    try {
      final resp = await _dio.get(
        '/api/public/destinations',
        queryParameters: {'per_page': 1, 'is_active': true},
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map &&
            data['meta'] is Map &&
            data['meta']['total'] is int) {
          return data['meta']['total'] as int;
        }
        return 0;
      }
      throw Exception(
        'Failed to fetch destination count: Status ${resp.statusCode}',
      );
    } on DioException catch (e) {
      // ignore: avoid_AppLogger.log
      AppLogger.log('Failed to count destinations: ${e.message}');
      return 0;
    }
  }

  // --- 3. Fungsi CountMapPoints (PUBLIK) ---
  static Future<int> countMapPoints() async {
    try {
      final resp = await _dio.get(
        '/api/public/map-points',
        queryParameters: {'per_page': 1},
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map &&
            data['meta'] is Map &&
            data['meta']['total'] is int) {
          return data['meta']['total'] as int;
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List).length;
        }
        return 0;
      }
      throw Exception(
        'Failed to fetch map points count: Status ${resp.statusCode}',
      );
    } on DioException catch (e) {
      // ignore: avoid_AppLogger.log
      AppLogger.log('Failed to count map points: ${e.message}');
      return 0;
    }
  }

  // --- 4. Fungsi getDetail (PERBAIKAN FOKUS UTAMA) ---
  static Future<Map<String, dynamic>> getDetail(int id) async {
    try {
      // PERBAIKAN: Mengganti endpoint PRIVATE (/api/destinations/$id)
      // menjadi endpoint PUBLIK (/api/public/destinations/$id)
      // untuk menghindari error 401.
      final resp = await _dio.get('/api/public/destinations/$id');

      if (resp.statusCode == 200) {
        final data = resp.data;
        // Asumsi struktur API: { success: true, data: { ... } }
        if (data is Map && data['success'] == true && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
        // Handle response jika sukses=false
        throw Exception(data['message'] ?? 'Gagal mengambil detail destinasi');
      }

      // Handle non-200 status codes (misalnya 404, 500)
      throw Exception(
        'Gagal memuat detail destinasi: Status ${resp.statusCode}',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorMessage = e.response?.data?['message'] ?? e.message;

      if (statusCode == 404) {
        throw Exception('Destinasi tidak ditemukan (404)');
      } else if (statusCode == 401) {
        // Meskipun sudah publik, kita tetap berikan pesan jika 401 muncul
        throw Exception(
            'Gagal memuat detail destinasi: Status 401. Pastikan token tersedia jika endpoint ini tetap privat.');
      }

      // Re-throw errors lainnya
      throw Exception('Terjadi kesalahan: $errorMessage');
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }
}
