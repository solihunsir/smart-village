import 'package:desaku/utils/app_logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../config/dio_config.dart';
import '../config/api_config.dart';
import '../models/api_product.dart';

class ProductService {
  static final Dio _dio = DioConfig.dio;
  static Future<String?> getSellerPhoneById(int sellerId) async {
    try {
      final response = await _dio.get(
        '/api/public/users/$sellerId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        // Ambil nomor HP dari kunci API yang mungkin (diasumsikan 'phone_number')
        final rawPhone = data['phone_number'] ?? data['phone'];

        if (rawPhone != null && rawPhone.isNotEmpty) {
          String cleaned = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
          if (cleaned.startsWith('0')) {
            return '62' + cleaned.substring(1);
          }
          return cleaned;
        }
      }
      return null;
    } catch (e) {
      AppLogger.log('Error fetching seller phone for ID $sellerId: $e');
      return null;
    }
  }

  // =======================================================================
  // MARK: - FUNGSI UTAMA (Tidak ada perubahan)
  // =======================================================================

  /// Mengambil daftar produk, dengan opsi memfilter berdasarkan sellerId.
  /// Menggunakan GET /api/public/products
  static Future<ProductResponse?> getProducts({
    String? status,
    String? condition,
    int? categoryId,
    int? sellerId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int page = 1,
  }) async {
    try {
      Map<String, dynamic> queryParams = {'page': page};

      if (status != null) queryParams['status'] = status;
      if (condition != null) queryParams['condition'] = condition;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (sellerId != null) queryParams['seller_id'] = sellerId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (perPage != null) queryParams['per_page'] = perPage;

      final response = await _dio.get(
        '/api/public/products',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return ProductResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.log('Error fetching products: $e');
      return null;
    }
  }

  // =======================================================================
  // MARK: - FUNGSI TRANSAKSIONAL (Membutuhkan Token & Endpoint Terlindungi)
  // =======================================================================

  /// Memperbarui status produk (tersedia/terjual)
  /// Menggunakan PUT /api/products/{id}.
  static Future<bool> updateProductStatus({
    required String token,
    required int productId,
    required String newStatus,
  }) async {
    final statusMap = {'status': newStatus.toLowerCase()};

    try {
      final response = await _dio.put(
        '/api/products/$productId',
        data: statusMap,
        options: Options(
          headers: ApiConfig.headersWithAuth(token),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) return true;
        return true;
      }
      return false;
    } on DioException {
      return false;
    } catch (e) {
      AppLogger.log('Error updating product status: $e');
      return false;
    }
  }

  /// Hapus produk
  /// Menggunakan DELETE /api/products/{id}.
  static Future<bool> deleteProduct({
    required String token,
    required int productId,
  }) async {
    try {
      final response = await _dio.delete(
        '/api/products/$productId',
        options: Options(
          headers: ApiConfig.headersWithAuth(token),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final data = response.data;
        if (data == null) return true;
        if (data is Map && data['success'] == true) return true;
        return response.statusCode == 204;
      }
      return false;
    } catch (e) {
      AppLogger.log('Error deleting product: $e');
      return false;
    }
  }

  static Future<ProductCategory?> createCategory({
    required String token,
    required String name,
    String description = '',
  }) async {
    // 💡 Catatan: Fungsi ini menggunakan instance Dio lokal, tidak menggunakan _dio (DioConfig.dio)
    final dio = Dio();
    final url = '${ApiConfig.baseUrl}/api/product-categories';

    try {
      final response = await dio.post(
        url,
        data: {'name': name, 'description': description},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 && response.data['data'] is Map) {
        return ProductCategory.fromJson(response.data['data']);
      }
      return null;
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  static Future<ApiProduct?> getProductById(int id) async {
    try {
      final response = await _dio.get(
        '/api/public/products/$id',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ApiProduct.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.log('Error fetching product detail: $e');
      return null;
    }
  }

  // 🎯 MODIFIKASI: Mengganti fungsi updateProduct untuk menangani file (Multipart)
  static Future<ApiProduct?> updateProduct({
    required String token,
    required int productId,
    required int categoryId,
    required String name,
    required String description,
    required int price,
    required String status,
    required String conditionProduct,
    required String location,
    // Parameter BARU untuk File Handling
    List<XFile>? newPhotos,
    List<int>? keptPhotoIds,
  }) async {
    try {
      final formData = FormData();

      // Tambahkan data non-file
      formData.fields.add(
        MapEntry('_method', 'PUT'),
      ); // Diperlukan untuk metode PUT/PATCH dengan FormData
      formData.fields.add(MapEntry('category_id', categoryId.toString()));
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('description', description));
      formData.fields.add(MapEntry('price', price.toString()));
      formData.fields.add(MapEntry('status', status));
      formData.fields.add(MapEntry('condition_product', conditionProduct));
      formData.fields.add(MapEntry('location', location));

      // Tambahkan ID foto yang dipertahankan
      if (keptPhotoIds != null && keptPhotoIds.isNotEmpty) {
        // ASUMSI: API menerima daftar ID di bawah kunci 'kept_photo_ids[]' atau 'kept_photos[]'
        keptPhotoIds.forEach((id) {
          formData.fields.add(MapEntry('kept_photo_ids[]', id.toString()));
        });
      }

      // Tambahkan foto baru
      if (newPhotos != null && newPhotos.isNotEmpty) {
        for (int i = 0; i < newPhotos.length; i++) {
          final file = newPhotos[i];
          formData.files.add(
            MapEntry(
              'photos[]', // Kunci array untuk file baru
              await MultipartFile.fromFile(file.path, filename: file.name),
            ),
          );
        }
      }

      final response = await _dio.post(
        // Gunakan POST karena PUT/PATCH dengan FormData sering bermasalah
        '/api/products/$productId',
        data: formData,
        options: Options(
          headers: ApiConfig.headersWithAuth(token),
          validateStatus: (status) => status != null && status < 500,
          // Tambahkan timeout khusus untuk upload
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          return ApiProduct.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.log('Error updating product: $e');
      if (e is DioException) {
        AppLogger.log('Response data: ${e.response?.data}');
      }
      throw e; // Lemparkan error agar ditangani oleh UI
    }
  }

  static Future<List<ProductCategory>> getCategories() async {
    try {
      final response = await _dio.get(
        '/api/public/product-categories',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => ProductCategory.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.log('Error fetching categories: $e');
      return [];
    }
  }

  static Future<ProductResponse?> getAvailableProducts({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    return await getProducts(
      status: 'tersedia',
      page: page,
      perPage: perPage,
      search: search,
      sortBy: 'created_at',
      sortOrder: 'desc',
    );
  }

  static Future<ProductResponse?> getProductsByCategory({
    required int categoryId,
    int page = 1,
    int perPage = 15,
  }) async {
    return await getProducts(
      status: 'tersedia',
      categoryId: categoryId,
      page: page,
      perPage: perPage,
      sortBy: 'created_at',
      sortOrder: 'desc',
    );
  }

  static Future<ProductResponse?> searchProducts({
    required String query,
    int page = 1,
    int perPage = 15,
  }) async {
    return await getProducts(
      status: 'tersedia',
      search: query,
      page: page,
      perPage: perPage,
      sortBy: 'created_at',
      sortOrder: 'desc',
    );
  }

  static Future<ProductResponse?> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
    int page = 1,
    int perPage = 15,
  }) async {
    return await getProducts(
      status: 'tersedia',
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: page,
      perPage: perPage,
      sortBy: 'price',
      sortOrder: 'asc',
    );
  }

  static Future<ProductResponse?> getNewProducts({
    int page = 1,
    int perPage = 15,
  }) async {
    return await getProducts(
      status: 'tersedia',
      condition: 'baru',
      page: page,
      perPage: perPage,
      sortBy: 'created_at',
      sortOrder: 'desc',
    );
  }

  static Future<ProductResponse?> getUsedProducts({
    int page = 1,
    int perPage = 15,
  }) async {
    return await getProducts(
      status: 'tersedia',
      condition: 'bekas',
      page: page,
      perPage: perPage,
      sortBy: 'created_at',
      sortOrder: 'desc',
    );
  }

  static Future<ApiProduct?> createProduct({
    required String token,
    required int categoryId,
    required String name,
    required String description,
    required int price,
    required String status,
    required String conditionProduct,
    required String location,
    List<String>? photos,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "category_id": categoryId,
        "name": name,
        "description": description,
        "price": price,
        "status": status,
        "condition_product": conditionProduct,
        "location": location,
      };
      if (photos != null && photos.isNotEmpty) {
        data["photos"] = photos;
      }

      final response = await _dio.post(
        '/api/products',
        data: data,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ApiProduct.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.log('Error creating product: $e');
      if (e is DioException) {
        AppLogger.log('Response data: ${e.response?.data}');
      }
      throw e;
    }
  }

  /// ✅ MODIFIKASI: Menambahkan sellerPhone dan mengirimkannya dalam FormData
  static Future<ApiProduct?> createProductMultipart({
    required String token,
    required int categoryId,
    required String name,
    required String description,
    required int price,
    required String status,
    required String conditionProduct,
    required String location,
    required String sellerPhone, // Parameter sellerPhone diperlukan
    required List<MultipartFile> photoFiles,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('category_id', categoryId.toString()));
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('description', description));
      formData.fields.add(MapEntry('price', price.toString()));
      formData.fields.add(MapEntry('status', status));
      formData.fields.add(MapEntry('condition_product', conditionProduct));
      formData.fields.add(MapEntry('location', location));
      // ✅ PENTING: Mengirim nomor HP ke API
      formData.fields.add(MapEntry('phone_number', sellerPhone));

      for (final file in photoFiles) {
        formData.files.add(MapEntry('photos[]', file));
      }

      final response = await _dio.post(
        '/api/products',
        data: formData,
        options: Options(
          headers: ApiConfig.headersWithAuth(token),
          // 🚀 TIMEOUT KHUSUS UNTUK UPLOAD (Mengesampingkan nilai global)
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          return ApiProduct.fromJson(responseData['data']);
        }
      }

      throw ProductUploadException(response.statusCode, response.data);
    } catch (e) {
      AppLogger.log('Error creating product (multipart): $e');
      if (e is DioException) {
        AppLogger.log('Response data: ${e.response?.data}');
      }
      if (e is ProductUploadException) rethrow;
      if (e is DioException) rethrow;
      throw ProductUploadException(null, e.toString());
    }
  }
}

class ProductUploadException implements Exception {
  final int? statusCode;
  final dynamic data;

  ProductUploadException(this.statusCode, this.data);

  @override
  String toString() =>
      'ProductUploadException(status: $statusCode, data: $data)';
}
