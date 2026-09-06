import 'package:dio/dio.dart';
import '../config/dio_config.dart';
import '../models/featured_product.dart';
import '../models/paginated_response.dart';
import 'package:desaku/utils/app_logger.dart';

class FeaturedProductService {
  static final _dio = DioConfig.dio;

  static Future<PaginatedResponse<FeaturedProduct>> list({
    int page = 1,
    int perPage = 15,
    bool? isActive,
    String? productCategory,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (isActive != null) {
        queryParameters['is_active'] = isActive;
      }

      if (productCategory != null && productCategory.isNotEmpty) {
        queryParameters['product_category'] = productCategory;
      }

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      // Use the public endpoint so the list can be retrieved without auth.
      final response = await _dio.get(
        '/api/public/featured-products',
        queryParameters: queryParameters,
      );

      final responseData = response.data;

      // AppLogger.log response untuk debugging
      AppLogger.log('Response Data: $responseData');

      // Periksa apakah responseData adalah Map
      if (responseData is! Map<String, dynamic>) {
        throw Exception('Format response tidak valid');
      }

      // Konversi success ke bool
      final success = responseData['success'];
      final isSuccess = success == true ||
          success == 1 ||
          success == '1' ||
          success == 'true';

      if (isSuccess) {
        if (responseData['data'] == null) {
          return PaginatedResponse<FeaturedProduct>(
            data: [],
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            total: 0,
          );
        }

        // Pastikan data adalah List
        final dataList = responseData['data'];
        if (dataList is! List) {
          throw Exception('Format data tidak valid');
        }

        // Ambil meta data dengan safe conversion
        final meta = responseData['meta'] as Map<String, dynamic>? ?? {};

        return PaginatedResponse<FeaturedProduct>(
          data: dataList
              .map((item) =>
                  FeaturedProduct.fromJson(item as Map<String, dynamic>))
              .toList(),
          currentPage: meta['current_page'] as int? ?? page,
          lastPage: meta['last_page'] as int? ?? page,
          perPage: meta['per_page'] as int? ?? perPage,
          total: meta['total'] as int? ?? 0,
        );
      } else {
        throw Exception(responseData['message']?.toString() ??
            'Gagal memuat produk unggulan');
      }
    } on DioException catch (e) {
      AppLogger.log('DioError fetching featured products: ${e.message}');
      final response = e.response?.data;
      if (response != null && response['message'] != null) {
        throw Exception(response['message']);
      }
      throw Exception('Terjadi kesalahan jaringan');
    } catch (e) {
      AppLogger.log('Error fetching featured products: $e');
      throw Exception('Gagal memuat produk unggulan');
    }
  }
}
