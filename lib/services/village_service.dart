import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/village_settings.dart';
import '../models/village_official.dart';
import 'package:desaku/utils/app_logger.dart';

class VillageService {
  static final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 30)
    ..options.sendTimeout = const Duration(seconds: 30);

  static Future<VillageSettings?> getVillageSettings() async {
    try {
      AppLogger.log(
        'Fetching village settings from: ${ApiConfig.baseUrl}${ApiConfig.settingsEndpoint}',
      );

      final response = await _dio.get(
        ApiConfig.getUrl(ApiConfig.settingsEndpoint),
        options: Options(
          headers: ApiConfig.headers,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      AppLogger.log('Response status: ${response.statusCode}');
      final respData = response.data;
      AppLogger.log('Response type: ${respData.runtimeType}');

      if (response.statusCode == 200) {
        final data = respData;

        if (data == null) {
          AppLogger.log('Response data is null');
          return null;
        }

        if (data is Map && data['success'] == true && data['data'] != null) {
          final inner = data['data'];
          if (inner is Map<String, dynamic>) {
            AppLogger.log('Parsing village settings with success wrapper');
            return VillageSettings.fromJson(Map<String, dynamic>.from(inner));
          }
          if (inner is List && inner.isNotEmpty && inner[0] is Map) {
            AppLogger.log(
              'Parsing village settings: wrapper.data is List, using first element',
            );
            return VillageSettings.fromJson(
              Map<String, dynamic>.from(inner[0] as Map),
            );
          }
        }

        if (data is Map) {
          if (data.containsKey('data') &&
              data['data'] is List &&
              (data['data'] as List).isEmpty) {
            AppLogger.log(' Response wrapper.data is an empty List');
            return null;
          }

          if (data.containsKey('village_description')) {
            try {
              AppLogger.log('Parsing direct village settings data');
              return VillageSettings.fromJson(Map<String, dynamic>.from(data));
            } catch (e) {
              AppLogger.log('Failed parsing direct village settings: $e');
              return null;
            }
          }

          if (data.containsKey('data') && data['data'] is Map) {
            final inner = data['data'] as Map;
            try {
              AppLogger.log(
                'Parsing village settings with success wrapper (inner Map)',
              );
              return VillageSettings.fromJson(Map<String, dynamic>.from(inner));
            } catch (e) {
              AppLogger.log('Failed parsing wrapper.data as Map: $e');
              return null;
            }
          }
          for (final v in data.values) {
            if (v is Map && v.containsKey('village_description')) {
              try {
                AppLogger.log(
                    ' Found nested settings map inside response values');
                return VillageSettings.fromJson(Map<String, dynamic>.from(v));
              } catch (e) {
                AppLogger.log(' Failed parsing nested settings map: $e');
                return null;
              }
            }
          }

          try {
            AppLogger.log(
                'Attempting to parse top-level response as VillageSettings');
            return VillageSettings.fromJson(Map<String, dynamic>.from(data));
          } catch (e) {
            AppLogger.log(
              'Unexpected response format for village settings: ${data.runtimeType}',
            );
            return null;
          }
        }

        if (data is List) {
          if (data.isNotEmpty && data[0] is Map) {
            try {
              AppLogger.log(
                ' Parsing village settings from first element of List response',
              );
              return VillageSettings.fromJson(
                Map<String, dynamic>.from(data[0] as Map),
              );
            } catch (e) {
              AppLogger.log(
                  ' Failed parsing first element of List response: $e');
              return null;
            }
          }
          AppLogger.log(
              ' Response is a List but does not contain a Map at index 0');
          return null;
        }
      }

      AppLogger.log(
          ' Failed to get valid response, status: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      AppLogger.log(' Error fetching village settings: $e');
      AppLogger.log(' Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> updateVillageSettings({
    required String villageDescription,
    required String visi,
    required String misi,
    String? selectedProvinsiKode,
    String? selectedProvinsiNama,
    String? selectedKotaKode,
    String? selectedKotaNama,
    String? selectedKecamatanKode,
    String? selectedKecamatanNama,
    String? selectedKelurahanKode,
    String? selectedKelurahanNama,
    String? photoPath,
    String? photoKepalaDesaPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'village_description': villageDescription,
        'visi': visi,
        'misi': misi,
        if (selectedProvinsiKode != null)
          'selected_provinsi_kode': selectedProvinsiKode,
        if (selectedProvinsiNama != null)
          'selected_provinsi_nama': selectedProvinsiNama,
        if (selectedKotaKode != null) 'selected_kota_kode': selectedKotaKode,
        if (selectedKotaNama != null) 'selected_kota_nama': selectedKotaNama,
        if (selectedKecamatanKode != null)
          'selected_kecamatan_kode': selectedKecamatanKode,
        if (selectedKecamatanNama != null)
          'selected_kecamatan_nama': selectedKecamatanNama,
        if (selectedKelurahanKode != null)
          'selected_kelurahan_kode': selectedKelurahanKode,
        if (selectedKelurahanNama != null)
          'selected_kelurahan_nama': selectedKelurahanNama,
      });

      if (photoPath != null) {
        formData.files.add(
          MapEntry('photo', await MultipartFile.fromFile(photoPath)),
        );
      }

      if (photoKepalaDesaPath != null) {
        formData.files.add(
          MapEntry(
            'photo_kepala_desa',
            await MultipartFile.fromFile(photoKepalaDesaPath),
          ),
        );
      }

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/settings',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      AppLogger.log('Error updating village settings: $e');
      return false;
    }
  }

  static Future<bool> addDynamicSetting({
    required String key,
    required String value,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/settings/add',
        data: {
          'new_setting': {'key': key, 'value': value},
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      AppLogger.log('Error adding dynamic setting: $e');
      return false;
    }
  }

  static Future<bool> updateDynamicSetting({
    required String key,
    required String newKey,
    required String value,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.baseUrl}/api/settings/$key',
        data: {'key': newKey, 'value': value},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      AppLogger.log('Error updating dynamic setting: $e');
      return false;
    }
  }

  static Future<bool> deleteDynamicSetting(String key) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/api/settings/$key',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      AppLogger.log('Error deleting dynamic setting: $e');
      return false;
    }
  }

  // Public officials
  static Future<List<VillageOfficial>> getVillageOfficials() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/public/village-officials',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] is List) {
          final list = (data['data'] as List)
              .map((e) => VillageOfficial.fromJson(e))
              .toList();
          // Optionally filter active only
          return list.where((o) => o.isActive).toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.log('Error fetching village officials: $e');
      return [];
    }
  }
}
