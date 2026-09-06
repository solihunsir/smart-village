import 'package:desaku/utils/app_logger.dart';
import 'package:dio/dio.dart';
import '../models/community_channel.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class ChannelService {
  // Dio instance dasar untuk permintaan publik
  static final Dio _baseDio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // PERBAIKAN: Mengganti nama dan endpoint menjadi Publik: GET /api/public/community-channels
  static Future<List<CommunityChannel>> fetchPublicChannels() async {
    try {
      final response = await _baseDio.get(
        // Menggunakan Dio non-autentikasi
        ApiConfig.getUrl('/api/public/community-channels'), // Endpoint Publik
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Asumsi: Struktur data API Publik SAMA dengan API Admin: data: { data: [..., ...] }
        final List<dynamic> dataList =
            response.data['data']?['data'] ?? response.data['data'] ?? [];
        return dataList.map((json) => CommunityChannel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      AppLogger.log('Dio Error saat memuat Channel Publik: ${e.toString()}');
      throw Exception('Gagal memuat Saluran Komunitas Publik.');
    }
  }

  // MEMPERTAHANKAN NAMA LAMA UNTUK KOMPATIBILITAS DI HOME_PAGE
  // ATAU HANYA SEBAGAI REFERENSI
  static Future<List<CommunityChannel>> fetchAdminChannels() async {
    // Kita panggil yang publik. Jika logic aslinya memang hanya admin,
    // pastikan kode di HomeContent menggunakan fungsi yang baru.

    // JIKA ANDA INGIN ENDPOINT INI BENAR-BENAR MENGGUNAKAN AUTH SERVICE/TOKEN:
    try {
      final Dio dio = AuthService().dioInstance; // Membutuhkan Token
      final response = await dio.get(
        ApiConfig.getUrl('/api/admin/community-channels'),
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList = response.data['data']?['data'] ?? [];
        return dataList.map((json) => CommunityChannel.fromJson(json)).toList();
      }

      // Jika 401/403, kita kembalikan list kosong agar Home Page tidak error
      if (response.statusCode == 403 || response.statusCode == 401) {
        AppLogger.log("Akses ditolak ke endpoint Admin Channel.");
        return [];
      }
      return [];
    } catch (e) {
      // Jika error karena Token expired/tidak ada, return list kosong.
      return [];
    }
  }
}
