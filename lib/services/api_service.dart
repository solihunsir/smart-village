// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  // Method untuk mendapatkan headers, menambahkan token jika ada, bahkan untuk requiresAuth=false
  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = false,
  }) async {
    Map<String, String> headers = {...ApiConfig.headers};
    final token = await TokenService.getToken();

    if (requiresAuth) {
      if (token != null && token.isNotEmpty) {
        headers = ApiConfig.headersWithAuth(token);
      } else {
        // Melempar error 401 eksplisit jika otorisasi wajib tapi token tidak ada
        throw ApiException(
          'Authentication token is missing. Please login.',
          statusCode: 401,
        );
      }
    } else if (token != null && token.isNotEmpty) {
      // Untuk endpoint publik, tambahkan token jika ada (agar server tahu status like/bookmark user)
      headers = ApiConfig.headersWithAuth(token);
    }

    return headers;
  }

  static Uri _getUri(String endpoint, {Map<String, dynamic>? queryParameters}) {
    final uri = Uri.parse(ApiConfig.getUrl(endpoint));
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }
    return uri;
  }

  static void _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final Map<String, dynamic> body = json.decode(response.body);
        final message =
            body['message'] ??
            'Request failed with status code ${response.statusCode}';
        throw ApiException(message, statusCode: response.statusCode);
      } catch (e) {
        throw ApiException(
          'Server error or invalid response format. Response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  // --- GET METHOD ---
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _getUri(endpoint, queryParameters: queryParameters);
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await http.get(uri, headers: headers);
    _handleResponse(response);

    return json.decode(response.body);
  }

  // --- POST MULTIPART (UNTUK UPLOAD POST DENGAN GAMBAR) ---
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required int communityId,
    String? content,
    List<http.MultipartFile>? imageFiles,
  }) async {
    final uri = _getUri(endpoint);
    final headers = await _getHeaders(
      requiresAuth: true,
    ); // Upload POST selalu butuh auth

    final request = http.MultipartRequest('POST', uri);
    // Hapus Content-Type header karena MultipartRequest menanganinya sendiri
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    request.fields['community_id'] = communityId.toString();
    if (content != null && content.isNotEmpty) {
      request.fields['content'] = content;
    }

    if (imageFiles != null) {
      request.files.addAll(imageFiles);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _handleResponse(response);

    return json.decode(response.body);
  }

  // --- POST INTERAKSI (LIKE/BOOKMARK) ---
  static Future<Map<String, dynamic>> postInteraction(String endpoint) async {
    final uri = _getUri(endpoint);
    final headers = await _getHeaders(
      requiresAuth: true,
    ); // Interaksi selalu butuh auth

    final response = await http.post(uri, headers: headers);
    _handleResponse(response);

    return json.decode(response.body);
  }
}
