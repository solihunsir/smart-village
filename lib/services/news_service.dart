import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/news_item.dart';
import 'package:desaku/utils/app_logger.dart';

class NewsService {
  static final Dio _dio = Dio();

  static Future<List<NewsItem>> list({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final headers = ApiConfig.headers;
      String url = '${ApiConfig.baseUrl}/api/public/news';

      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : []);
        final mapped = items
            .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return mapped;
      }
      throw DioException(requestOptions: response.requestOptions);
    } catch (e) {
      AppLogger.log('NewsService.list error: $e');
      rethrow;
    }
  }

  static Future<NewsItem?> detail(String slug) async {
    try {
      final headers = ApiConfig.headers; // public endpoint, no auth required
      final url = '${ApiConfig.baseUrl}/api/public/news/$slug';
      final response = await _dio.get(url, options: Options(headers: headers));
      if (response.statusCode == 200) {
        final data = response.data;
        final item = (data is Map && data['data'] is Map)
            ? data['data'] as Map
            : (data is Map ? data : null);
        if (item != null) {
          return NewsItem.fromJson(Map<String, dynamic>.from(item));
        }
      }
      throw DioException(requestOptions: response.requestOptions);
    } catch (e) {
      rethrow;
    }
  }
}
