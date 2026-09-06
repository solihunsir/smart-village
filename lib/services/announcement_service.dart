import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/announcement_item.dart';
import 'package:desaku/utils/app_logger.dart';

class AnnouncementService {
  static final Dio _dio = Dio();

  static Future<List<AnnouncementItem>> list({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      final headers = ApiConfig.headers; // public endpoint, no auth required
      final url = '${ApiConfig.baseUrl}/api/public/announcements';
      // ignore: avoid_AppLogger.log
      AppLogger.log('AnnouncementService.list -> GET: ' + url);
      final response = await _dio.get(
        url,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
        options: Options(headers: headers),
      );
      // ignore: avoid_AppLogger.log
      AppLogger.log(
          'AnnouncementService.list <- status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        // Normalize possible shapes:
        // - { data: [ ... ] }
        // - { data: { ... } }
        // - [ ... ]
        List items = [];
        if (data is Map) {
          final inner = data['data'];
          if (inner is List) {
            items = inner;
          } else if (inner is Map) {
            items = [inner];
          } else if (data.containsKey('data') && inner == null) {
            items = [];
          }
        } else if (data is List) {
          items = data;
        } else {
          items = [];
        }
        final mapped = items
            .map(
              (e) => AnnouncementItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        if (mapped.isEmpty) {
          // ignore: avoid_AppLogger.log
          AppLogger.log('AnnouncementService.list: 200 OK but empty list');
        }
        return mapped;
      }
      throw DioException(requestOptions: response.requestOptions);
    } catch (e) {
      // ignore: avoid_AppLogger.log
      AppLogger.log('AnnouncementService.list error: $e');
      rethrow;
    }
  }

  static Future<AnnouncementItem?> detail(int id) async {
    try {
      final headers = ApiConfig.headers; // public endpoint, no auth required
      final url = '${ApiConfig.baseUrl}/api/public/announcements/$id';
      // ignore: avoid_AppLogger.log
      AppLogger.log('AnnouncementService.detail -> GET: ' + url);
      final response = await _dio.get(url, options: Options(headers: headers));
      // ignore: avoid_AppLogger.log
      AppLogger.log(
          'AnnouncementService.detail <- status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        final item = (data is Map && data['data'] is Map)
            ? data['data'] as Map
            : (data is Map ? data : null);
        if (item != null) {
          return AnnouncementItem.fromJson(Map<String, dynamic>.from(item));
        }
      }
      throw DioException(requestOptions: response.requestOptions);
    } catch (e) {
      rethrow;
    }
  }
}
