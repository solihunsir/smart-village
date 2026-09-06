import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; 
import 'dart:io'; 
import '../config/api_config.dart'; 
import '../models/annual_category_data.dart'; 
import '../models/category_model.dart'; // Asumsi model ini ada

class VariableCategoryResponse {
  final List<VariableCategory> data;
  final bool success;
  final String message;

  VariableCategoryResponse({
    required this.data,
    required this.success,
    required this.message,
  });

  factory VariableCategoryResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? []; // Menambahkan null check
    List<VariableCategory> data = dataList.map((i) => VariableCategory.fromJson(i)).toList();

    return VariableCategoryResponse(
      data: data,
      success: json['success'] as bool? ?? false, // Menambahkan null check
      message: json['message'] as String? ?? '',  // Menambahkan null check
    );
  }
}

class IndicatorService {
  static const String _annualDataEndpoint = '/api/public/annual-category-data';
  static const String _variableCategoryEndpoint = '/api/public/variable-categories';
  static const String _categoryEndpoint = '/api/public/categories';

  static const Duration _timeoutDuration = Duration(seconds: 15); 
  
  // Fungsi 1: Mengambil Kategori Indikator (Tidak diubah)
  static Future<List<CategoryModel>> getIndicatorCategories() async {
    final headers = ApiConfig.headers;
    
    final Map<String, String> queryParams = {
      'paginate': 'false', 
      'sort_by': 'name', 
      'sort_order': 'asc',
    };
    
    final uri = Uri.parse('${ApiConfig.baseUrl}$_categoryEndpoint')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: headers).timeout(_timeoutDuration); 
      
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') != true) {
            return Future.error('Server mengembalikan format non-JSON. Periksa Base URL.');
        }

        final responseBody = jsonDecode(response.body);
        // Asumsi CategoryResponse sudah di-define di models/category_model.dart
        final responseModel = CategoryResponse.fromJson(responseBody); 
        
        if (responseModel.success) {
          return responseModel.data;
        } else {
          return Future.error(responseModel.message);
        }
      } else {
        final errorMsg = 'HTTP Error ${response.statusCode} (${response.reasonPhrase ?? 'Unknown'}).';
        return Future.error('${errorMsg} (Gagal memuat Kategori Indikator)');
      }
    } on TimeoutException {
      return Future.error('Waktu koneksi habis.');
    } on SocketException {
      return Future.error('Gagal koneksi ke server.');
    } on FormatException {
       return Future.error('Kesalahan format JSON dari server. Data tidak valid.');
    } catch (e) {
      return Future.error('Kesalahan umum memuat kategori: ${e.toString()}');
    }
  }


  // Fungsi 2: Mengambil Variabel Kategori (Tidak diubah)
  static Future<List<VariableCategory>> getVariableCategories({
    required int categoryId,
  }) async {
    final headers = ApiConfig.headers; 

    final Map<String, String> queryParams = {
      'category_id': categoryId.toString(),
      'paginate': 'false', 
      'sort_by': 'name', 
      'sort_order': 'asc',
    };
    
    final uri = Uri.parse('${ApiConfig.baseUrl}$_variableCategoryEndpoint')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: headers).timeout(_timeoutDuration); 
      
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') != true) {
            return Future.error('Server mengembalikan format non-JSON. Periksa Base URL.');
        }

        final responseBody = jsonDecode(response.body);
        
        if (responseBody['success'] == true) {
          final responseModel = VariableCategoryResponse.fromJson(responseBody);
          return responseModel.data;
        } else {
          final message = responseBody['message'] ?? 'Gagal memuat variabel kategori.';
          return Future.error(message);
        }
      } else {
        final errorMsg = 'HTTP Error ${response.statusCode} (${response.reasonPhrase ?? 'Unknown'}).';
        return Future.error('${errorMsg} (Akses publik variabel gagal.)');
      }
    } on TimeoutException {
      return Future.error('Waktu koneksi habis. Cek koneksi internet Anda.');
    } on SocketException {
      return Future.error('Gagal koneksi ke server. Cek alamat Base URL.');
    } on FormatException {
       return Future.error('Kesalahan format JSON dari server. Data tidak valid.');
    } catch (e) {
      return Future.error('Kesalahan umum: ${e.toString()}');
    }
  }

  // --- Fungsi 3: Mengambil Data Tahunan Kategori (DIMODIFIKASI) ---
  // Parameter diubah dari int? ke String? untuk menerima YYYY-MM-DD
  static Future<AnnualCategoryDataResponse?> getAnnualCategoryData({
    required int categoryId,
    required int variableCategoryId, 
    String? periodStart, // Diubah dari 'int? yearStart'
    String? periodEnd,   // Diubah dari 'int? yearEnd'
  }) async {
    final headers = ApiConfig.headers;
    
    final Map<String, String> queryParams = {
      'category_id': categoryId.toString(),
      'variable_category_id': variableCategoryId.toString(), 
      'with_variable_category': 'true', 
      'paginate': 'false', 
      'sort_by': 'year', 
      'sort_order': 'asc',
    };

    // LOGIC BARU: Menggunakan periodStart dan periodEnd (String YYYY-MM-DD)
    if (periodStart != null && periodStart.isNotEmpty) {
      queryParams['period_start'] = periodStart;
    } 
    if (periodEnd != null && periodEnd.isNotEmpty) {
      queryParams['period_end'] = periodEnd;
    }
    
    final uri = Uri.parse('${ApiConfig.baseUrl}$_annualDataEndpoint')
        .replace(queryParameters: queryParams);
        
    try {
      final response = await http.get(uri, headers: headers).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') != true) {
            return null;
        }
        
        final responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true) {
          return AnnualCategoryDataResponse.fromJson(responseBody);
        } else {
          // Mengembalikan response lengkap dengan pesan error API
          return AnnualCategoryDataResponse(
            data: [], 
            success: false, 
            message: responseBody['message'] ?? 'Gagal memuat data chart.',
          );
        }
      } else {
        // Mengembalikan response lengkap dengan error HTTP
        return AnnualCategoryDataResponse(
          data: [], 
          success: false, 
          message: 'HTTP Error ${response.statusCode} (${response.reasonPhrase ?? 'Unknown'}).',
        );
      }
    } on TimeoutException {
      return AnnualCategoryDataResponse(data: [], success: false, message: 'Waktu koneksi habis.');
    } on SocketException {
      return AnnualCategoryDataResponse(data: [], success: false, message: 'Gagal koneksi ke server.');
    } on FormatException {
       return AnnualCategoryDataResponse(data: [], success: false, message: 'Kesalahan format JSON dari server.');
    } catch (e) {
      return AnnualCategoryDataResponse(data: [], success: false, message: 'Kesalahan umum: ${e.toString()}');
    }
  }

  // --- Fungsi 4: Mengambil Tahun yang Tersedia (Tidak diubah) ---
  static Future<List<int>> getAvailableYears({required int categoryId}) async {
    final headers = ApiConfig.headers;

    final Map<String, String> queryParams = {
      'category_id': categoryId.toString(),
      'paginate': 'false', 
      'sort_by': 'year', 
      'sort_order': 'desc', 
      'per_page': '1000', 
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}$_annualDataEndpoint')
        .replace(queryParameters: queryParams);
        
    try {
      final response = await http.get(uri, headers: headers).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') != true) {
            return Future.error('Server mengembalikan format non-JSON. Periksa Base URL.');
        }

        final responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true) {
          final responseModel = AnnualCategoryDataResponse.fromJson(responseBody);
          
          final Set<int> uniqueYears = {};
          for (var data in responseModel.data) {
            if (data.year > 0) { 
                 uniqueYears.add(data.year);
            }
          }
          
          final List<int> years = uniqueYears.toList();
          years.sort((a, b) => b.compareTo(a)); 
          return years;
        } else {
          final message = responseBody['message'] ?? 'Gagal memuat tahun yang tersedia.';
          return Future.error(message);
        }
      } else {
        final errorMsg = 'HTTP Error ${response.statusCode} (${response.reasonPhrase ?? 'Unknown'}).';
        return Future.error('${errorMsg} (Akses publik gagal. Cek konfigurasi server.)');
      }
    } on TimeoutException {
      return Future.error('Waktu koneksi habis. Cek koneksi internet Anda.');
    } on SocketException {
      return Future.error('Gagal koneksi ke server. Cek alamat Base URL.');
    } on FormatException {
       return Future.error('Kesalahan format JSON dari server. Data tidak valid.');
    } catch (e) {
      return Future.error('Kesalahan umum: ${e.toString()}');
    }
  }
}