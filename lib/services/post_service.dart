import 'package:desaku/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../config/api_config.dart';
import '../models/comment.dart';
import '../models/image_to_post.dart';
import '../models/post.dart';
import '../models/activity.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class PostService {
  static bool _isValidImageExtension(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif'].contains(extension);
  }

  static MediaType _getMediaType(String fileName) {
    if (fileName.isEmpty) {
      // Default MIME type jika nama file kosong (kasus jarang)
      return MediaType('image', 'jpeg');
    }

    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.jpeg':
      case '.jpg':
        return MediaType('image', 'jpeg');
      case '.heic':
        // PERINGATAN: HEIC/HEIF tidak selalu didukung. Jika tidak bisa dikonversi
        // di client, server akan menolak. Default ke JPEG jika tidak didukung.
        return MediaType('image', 'heic');
      default:
        // Jika ekstensi tidak dikenali, gunakan default yang aman
        return MediaType('image', 'jpeg');
    }
  }

  static List<MultipartFile> _createMultipartFiles(List<ImageToPost> images) {
    List<MultipartFile> files = [];

    for (var imgToPost in images) {
      if (imgToPost.bytes == null || imgToPost.bytes!.isEmpty) {
        throw Exception(
          "Image bytes missing for upload (File: ${imgToPost.name}). Pastikan file bytes dibaca di CommunityPostPage.",
        );
      }

      // PERBAIKAN 1: Menentukan nama file yang aman dan memiliki ekstensi yang valid
      String safeFilename = imgToPost.name;
      String extension = path.extension(safeFilename).toLowerCase();

      if (!_isValidImageExtension(extension)) {
        // Jika ekstensi tidak valid/kosong, tambahkan ekstensi '.jpg' dan sesuaikan nama file
        safeFilename = '${path.basenameWithoutExtension(safeFilename)}.jpg';
      }

      final contentType = _getMediaType(safeFilename);

      // PERBAIKAN 2: Gunakan List<int> bukan Uint8List. Dio dapat menerima keduanya,
      // tetapi konversi eksplisit ini memastikan kompatibilitas penuh.
      List<int> bytesList = imgToPost.bytes!.toList();

      // Opsional: Cek ukuran file
      if (bytesList.length > 10 * 1024 * 1024) {
        // Contoh batasan 10MB
        throw Exception(
          'Ukuran gambar (${(bytesList.length / 1024 / 1024).toStringAsFixed(1)}MB) melebihi batas server.',
        );
      }

      files.add(
        MultipartFile.fromBytes(
          bytesList,
          filename: safeFilename,
          contentType: contentType,
        ),
      );
    }
    return files;
  }

  static Future<void> createPost({
    required int communityId,
    String? content,
    required List<ImageToPost> selectedImages,
  }) async {
    final Dio dio = AuthService().dioInstance;

    final List<MultipartFile> files = _createMultipartFiles(selectedImages);

    if ((content == null || content.isEmpty) && files.isEmpty) {
      throw Exception("Post must have either content or images.");
    }

    final formData = FormData.fromMap({
      'community_id': communityId,
      if (content != null && content.isNotEmpty) 'content': content,
      if (files.isNotEmpty) 'images[]': files,
    });

    try {
      final response = await dio.post(
        ApiConfig.getUrl('/api/posts'),
        data: formData,
        options: Options(
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode != 201) {
        String errorMessage =
            'Gagal membuat postingan. Status: ${response.statusCode}';
        if (response.data is Map && response.data.containsKey('message')) {
          errorMessage = response.data['message'];
        }
        if (response.data is Map && response.data.containsKey('errors')) {
          errorMessage += '\nValidasi: ${response.data['errors'].toString()}';
        }
        // Tambahkan detail respon untuk debugging lebih lanjut
        if (kDebugMode) {
          AppLogger.log('DEBUG FAILED RESPONSE: ${response.data}');
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      String message = 'Koneksi gagal atau sesi habis (401/403).';
      if (e.type == DioExceptionType.receiveTimeout) {
        message =
            'Waktu tunggu server habis (Receive Timeout). Coba lagi atau kurangi ukuran gambar.';
      } else if (e.response != null && e.response!.data is Map) {
        if (e.response!.statusCode == 422 &&
            e.response!.data.containsKey('errors')) {
          final errors = e.response!.data['errors'];
          if (errors is Map) {
            final imageError = errors.entries
                .firstWhere(
                  (entry) => entry.key.startsWith('images.'),
                  orElse: () => const MapEntry('', null),
                )
                .value;
            if (imageError != null) {
              message =
                  'Gagal mengunggah gambar: ${imageError[0] ?? e.response!.data['message']}';
            } else {
              message = e.response!.data['message'] ?? 'Validasi gagal.';
            }
          }
        } else {
          message = e.response!.data['message'] ?? message;
        }
      }
      throw Exception(message);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat membuat post: ${e.toString()}',
      );
    }
  }

  static Future<Comment> addComment(
    int postId,
    String commentText,
    List<ImageToPost> commentImages,
  ) async {
    final Dio dio = AuthService().dioInstance;

    final List<MultipartFile> files = _createMultipartFiles(commentImages);

    final formData = FormData.fromMap({
      if (commentText.isNotEmpty) 'comment_text': commentText,
      if (files.isNotEmpty) 'images[]': files,
    });

    try {
      final response = await dio.post(
        ApiConfig.getUrl('/api/posts/$postId/comments'),
        data: formData,
        options: Options(
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 201) {
        return Comment.fromJson(response.data['data']);
      }

      String errorMessage =
          response.data['message'] ?? 'Gagal menambahkan komentar.';
      if (response.data is Map && response.data.containsKey('errors')) {
        errorMessage += '\nValidasi: ${response.data['errors'].toString()}';
      }
      throw Exception(errorMessage);
    } on DioException catch (e) {
      final serverMessage =
          e.response?.data['message'] ?? 'Internal Server Error';
      throw Exception(serverMessage);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat menambahkan komentar: ${e.toString()}',
      );
    }
  }

  // --- FUNGSI LAINNYA TETAP SAMA ---

  static Future<Map<String, dynamic>> fetchPostAndComments(int postId) async {
    final Dio dio = AuthService().dioInstance;

    try {
      final response = await dio.get(
        ApiConfig.getUrl('/api/posts/$postId'),
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['data'] is Map<String, dynamic>) {
          return response.data['data'];
        } else {
          throw Exception('Format data detail post tidak valid.');
        }
      }

      final message = response.data['message'] ??
          'Gagal memuat detail post. Status: ${response.statusCode}';
      throw Exception(message);
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Koneksi gagal atau sesi habis.';
      throw Exception(message);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat memuat detail post: ${e.toString()}',
      );
    }
  }

  static Future<List<Comment>> fetchCommentsForPost(
    int postId, {
    int page = 1,
  }) async {
    final Dio dio = AuthService().dioInstance;

    try {
      final response = await dio.get(
        ApiConfig.getUrl('/api/posts/$postId/comments'),
        queryParameters: {'page': page},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList = response.data['data']['data'] ?? [];
        return dataList.map((json) => Comment.fromJson(json)).toList();
      }

      final message = response.data['message'] ??
          'Gagal memuat komentar. Status: ${response.statusCode}';
      throw Exception(message);
    } on DioException catch (e) {
      final serverMessage =
          e.response?.data['message'] ?? 'Koneksi gagal atau sesi habis.';
      throw Exception(serverMessage);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat memuat komentar: ${e.toString()}',
      );
    }
  }

  static Future<void> toggleLikeComment(int commentId) async {
    final Dio dio = AuthService().dioInstance;
    final String endpoint = '/api/comments/$commentId/like';

    try {
      final response = await dio.post(
        ApiConfig.getUrl(endpoint),
        options: Options(validateStatus: (status) => status! < 500),
      );

      // Biasanya 200 OK untuk toggle berhasil
      if (response.statusCode != 200) {
        final message =
            response.data?['message'] ?? 'Gagal toggle like komentar.';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Gagal menghubungi server.';
      throw Exception(message);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat toggle like komentar: ${e.toString()}',
      );
    }
  }

  static Future<void> reportComment(
    int commentId, {
    required String reason,
  }) async {
    final Dio dio = AuthService().dioInstance;
    final String endpoint = '/api/comments/$commentId/report';

    try {
      final response = await dio.post(
        ApiConfig.getUrl(endpoint),
        data: {'reason': reason},
        options: Options(
          validateStatus: (status) => status! < 500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode != 200 && statusCode != 201) {
        String message =
            response.data?['message'] ?? 'Gagal melaporkan komentar.';

        if (statusCode == 422 && response.data is Map) {
          message = response.data['message'] ?? 'Validation error.';
        } else if (statusCode >= 400) {
          message = response.data['message'] ??
              'Terjadi kesalahan (Status $statusCode).';
        }

        throw Exception(message);
      }
    } on DioException catch (e) {
      String errorMessage = 'Error server saat melaporkan komentar.';

      if (e.response?.data != null && e.response!.data is Map) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Koneksi time out. Coba periksa koneksi internet Anda.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat melaporkan komentar: ${e.toString()}',
      );
    }
  }

  static Future<Map<String, dynamic>> toggleLike(int postId) async {
    final Dio dio = AuthService().dioInstance;

    try {
      final response = await dio.post(
        ApiConfig.getUrl('/api/posts/$postId/like'),
        options: Options(validateStatus: (status) => status! < 500),
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception('Gagal toggle like. Status: ${response.statusCode}');
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Gagal menghubungi server.';
      throw Exception(message);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat toggle like: ${e.toString()}',
      );
    }
  }

  static Future<Map<String, bool>> toggleBookmark(int postId) async {
    final Dio dio = AuthService().dioInstance;

    try {
      final response = await dio.post(
        ApiConfig.getUrl('/api/posts/$postId/bookmark'),
        options: Options(validateStatus: (status) => status! < 500),
      );
      if (response.statusCode == 200) {
        return {
          'is_bookmarked': response.data['data']['is_bookmarked'] as bool,
        };
      }
      throw Exception('Gagal toggle bookmark. Status: ${response.statusCode}');
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Gagal menghubungi server.';
      throw Exception(message);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat toggle bookmark: ${e.toString()}',
      );
    }
  }

  static Future<List<Post>> fetchBookmarkedPosts({int page = 1}) async {
    final Dio dio = AuthService().dioInstance;

    try {
      final response = await dio.get(
        ApiConfig.getUrl('/api/posts/bookmarks/my-bookmarks'),
        queryParameters: {'page': page},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList = response.data['data']['data'] ?? [];
        return dataList.map((json) => Post.fromJson(json)).toList();
      }

      final message = response.data['message'] ?? 'Gagal memuat bookmark.';
      throw Exception(message);
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Error server saat memuat bookmark.';
      throw Exception(message);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat memuat bookmark: ${e.toString()}',
      );
    }
  }

  static Future<void> markNotInterested(int postId) async {
    final Dio dio = AuthService().dioInstance;
    final String endpoint = '/api/posts/$postId/not-interested';

    try {
      final response = await dio.post(
        ApiConfig.getUrl(endpoint),
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode != 200 || response.data?['success'] != true) {
        final message =
            response.data?['message'] ?? 'Gagal menandai tidak tertarik.';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Error server saat menandai tidak tertarik.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat menandai tidak tertarik: ${e.toString()}',
      );
    }
  }

  static Future<void> reportPost(int postId, {required String reason}) async {
    final Dio dio = AuthService().dioInstance;
    final String endpoint = '/api/posts/$postId/report';

    try {
      final response = await dio.post(
        ApiConfig.getUrl(endpoint),
        data: {'reason': reason},
        options: Options(
          validateStatus: (status) => status! < 500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode != 200 && statusCode != 201) {
        String message =
            response.data?['message'] ?? 'Gagal melaporkan postingan.';

        if (statusCode == 422 && response.data is Map) {
          message = response.data['message'] ?? 'Validation error.';
        } else if (statusCode >= 400) {
          message = response.data['message'] ??
              'Terjadi kesalahan (Status $statusCode).';
        }

        throw Exception(message);
      }
    } on DioException catch (e) {
      String errorMessage = 'Error server saat melaporkan postingan.';

      if (e.response?.data != null && e.response!.data is Map) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Koneksi time out. Coba periksa koneksi internet Anda.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Kesalahan tak terduga saat melaporkan postingan: ${e.toString()}',
      );
    }
  }

  static Future<List<ActivityItem>> fetchPostActivityDetail(int postId) async {
    final Dio dio = AuthService().dioInstance;

    try {
      final response = await dio.get(
        ApiConfig.getUrl('/api/posts/$postId/activity'),
        queryParameters: {'type': 'all', 'per_page': 50},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList =
            response.data['data']['activities']['data'] ?? [];
        return dataList.map((json) => ActivityItem.fromJson(json)).toList();
      }

      if (response.statusCode == 403) return [];

      throw Exception(
        response.data['message'] ?? 'Gagal memuat detail aktivitas post.',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) return [];
      throw Exception(
        e.response?.data['message'] ??
            'Error server saat memuat detail aktivitas.',
      );
    } catch (e) {
      throw Exception('Kesalahan tak terduga: ${e.toString()}');
    }
  }

  static Future<List<Post>> fetchMyPostsActivitySummary({int page = 1}) async {
    final Dio dio = AuthService().dioInstance;

    try {
      final response = await dio.get(
        ApiConfig.getUrl('/api/my-posts/activity'),
        queryParameters: {'page': page},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList = response.data['data']['data'] ?? [];
        return dataList.map((json) => Post.fromJson(json)).toList();
      }

      throw Exception(
        response.data['message'] ?? 'Gagal memuat ringkasan aktivitas.',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error server saat memuat ringkasan.',
      );
    } catch (e) {
      throw Exception('Kesalahan tak terduga: ${e.toString()}');
    }
  }
}
