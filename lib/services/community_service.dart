// lib/services/community_service.dart

import 'package:dio/dio.dart';
import '../models/community.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'token_service.dart'; // Import TokenService untuk cek login

class CommunityService {
  // Dio instance dasar untuk panggilan yang tidak memerlukan token (Public)
  static final Dio _baseDio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // =========================================================================
  // FUNGSI UTAMA (Hybrid Public/Authenticated)
  // =========================================================================
  // Fungsi ini dipanggil dari CommunityChatPage.
  // Jika user logged in, ia akan memanggil endpoint authenticated.
  // Jika gagal (misal token expired/missing), atau jika user tidak login,
  // ia akan fallback ke endpoint publik.
  static Future<Map<String, dynamic>> fetchCommunityDetails(
    int communityId, {
    int postPage = 1,
  }) async {
    final isLoggedIn = await TokenService.isLoggedIn();

    if (isLoggedIn) {
      // 1. Coba ambil data menggunakan endpoint terautentikasi (dengan token)
      try {
        final Dio dio = AuthService().dioInstance;
        final response = await dio.get(
          ApiConfig.getUrl(
            '/api/communities/$communityId',
          ), // Endpoint Terautentikasi
          queryParameters: {'posts_page': postPage},
          options: Options(validateStatus: (status) => status! < 500),
        );

        if (response.statusCode == 200 && response.data != null) {
          return response.data['data']; // Berhasil, kembalikan data autentikasi
        }

        // Jika status bukan 200, dan itu bukan 401/403, kita lempar exception
        if (response.statusCode != 401 && response.statusCode != 403) {
          throw Exception(
            'Gagal memuat detail komunitas. Status: ${response.statusCode}',
          );
        }

        // Jika 401/403, kita lanjut ke fallback publik
      } on DioException catch (e) {
        if (e.response?.statusCode != 401 && e.response?.statusCode != 403) {
          // Jika error lain (misal 500), throw
          final message = e.response?.data['message'] ?? e.toString();
          throw Exception(message);
        }
        // Jika 401/403, kita lanjut ke fallback publik (continue below)
      } catch (e) {
        // Jika error generik, throw
        throw Exception(
          'Kesalahan tak terduga saat autentikasi: ${e.toString()}',
        );
      }
    }

    // 2. Jika tidak login, atau otentikasi gagal (step 1), fallback ke endpoint publik
    try {
      return await _fetchPublicCommunityDetails(
        communityId,
        postPage: postPage,
      );
    } catch (e) {
      // Jika endpoint publik gagal, lempar error akhir
      throw Exception(
        'Gagal memuat konten komunitas. Pastikan API publik tersedia.',
      );
    }
  }

  // FUNGSI PUBLIK: Mendapatkan detail komunitas (Read-Only)
  // Endpoint: /api/public/communities/{id}
  static Future<Map<String, dynamic>> _fetchPublicCommunityDetails(
    int communityId, {
    int postPage = 1,
  }) async {
    try {
      final response = await _baseDio.get(
        // Menggunakan Dio non-autentikasi
        ApiConfig.getUrl(
          '/api/public/communities/$communityId',
        ), // Endpoint Publik
        queryParameters: {'posts_page': postPage},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        // NOTE: Asumsikan response publik tidak memiliki field 'is_member' atau 'has_liked',
        // dan logic di CommunityChatPage harus menanganinya.
        return response.data['data'];
      }
      throw Exception(
        'Gagal memuat detail komunitas publik. Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? e.toString();
      throw Exception(message);
    } catch (e) {
      throw Exception('Kesalahan tak terduga: ${e.toString()}');
    }
  }

  // FUNGSI PUBLIK: Mendapatkan daftar komunitas
  static Future<List<Community>> fetchCommunities({int page = 1}) async {
    try {
      final response = await _baseDio.get(
        ApiConfig.getUrl('/api/public/communities'),
        queryParameters: {'page': page},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList =
            response.data['data']?['data'] ?? response.data['data'] ?? [];
        return dataList.map((json) => Community.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ??
          'Gagal mengambil data komunitas publik. Periksa koneksi.';
      throw Exception(message);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat memuat komunitas: ${e.toString()}',
      );
    }
  }

  // =========================================================================
  // FUNGSI BARU: Mendapatkan daftar anggota komunitas (AUTHENTICATED) 🎯
  // Endpoint: GET /api/communities/{community}/members
  // =========================================================================
  static Future<Map<String, dynamic>> fetchCommunityMembers(
    int communityId, {
    int page = 1,
  }) async {
    try {
      final Dio dio = AuthService().dioInstance;
      final response = await dio.get(
        ApiConfig.getUrl('/api/communities/$communityId/members'),
        queryParameters: {'page': page},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Mengembalikan seluruh objek respons untuk diproses oleh CommunityDetailPage
        return response.data;
      }

      // Jika status adalah 404/401/403 atau error lain
      throw Exception(
        response.data['message'] ??
            'Gagal memuat daftar anggota komunitas. Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ??
          'Error otorisasi/server saat memuat anggota.';
      throw Exception(message);
    } catch (e) {
      throw Exception('Kesalahan tak terduga: ${e.toString()}');
    }
  }

  // FUNGSI TERAUTENTIKASI: Bergabung komunitas (TIDAK DIUBAH)
  static Future<bool> joinCommunity(int communityId) async {
    try {
      final Dio dio = AuthService().dioInstance;
      final response = await dio.post(
        ApiConfig.getUrl('/api/communities/$communityId/join'),
        options: Options(validateStatus: (status) => status! < 500),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      throw Exception(
        response.data['message'] ?? 'Gagal bergabung dengan komunitas.',
      );
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ??
          'Error otorisasi/server saat bergabung.';
      throw Exception(message);
    } catch (e) {
      throw Exception('Kesalahan tak terduga: ${e.toString()}');
    }
  }

  // FUNGSI TERAUTENTIKASI: Keluar komunitas (TIDAK DIUBAH)
  static Future<bool> leaveCommunity(int communityId) async {
    try {
      final Dio dio = AuthService().dioInstance;
      final response = await dio.post(
        ApiConfig.getUrl('/api/communities/$communityId/leave'),
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(
        response.data['message'] ?? 'Gagal keluar dari komunitas.',
      );
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Error server saat keluar.';
      throw Exception(message);
    } catch (e) {
      throw Exception('Kesalahan tak terduga: ${e.toString()}');
    }
  }
}
