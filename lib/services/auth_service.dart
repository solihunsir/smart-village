// lib/services/auth_service.dart (Final dengan perbaikan signOut)

import 'package:desaku/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_models.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'token_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 🎯 Client ID Web (New) - Digunakan sebagai serverClientId (Audience)
  static const String _webClientId =
      '709499892401-v13ntjvv433uonrjhaiadavjdrdoopkt.apps.googleusercontent.com';

  // Inisialisasi GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _webClientId,
  );

  final String _googleLoginEndpoint =
      ApiConfig.getUrl(ApiConfig.googleLoginEndpoint);

  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 30)
    ..options.sendTimeout = const Duration(seconds: 30)
    ..options.baseUrl = ApiConfig.baseUrl
    ..options.headers = ApiConfig.headers;

  Dio get dioInstance => _dio;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  String _cleanAndFormatPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.isEmpty) return '';
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      return '62' + cleaned.substring(1);
    } else if (cleaned.startsWith('+62')) {
      return cleaned.substring(1);
    } else if (cleaned.startsWith('62')) {
      return cleaned;
    }
    return cleaned;
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final imagePath = path.startsWith('/') ? path.substring(1) : path;
    final fullUrl = '$baseUrl/$imagePath';
    AppLogger.log('Generated Photo URL: $fullUrl');
    return fullUrl;
  }

  Future<void> initialize() async {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => AppLogger.log(obj),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenService.getToken();
          if (token != null && options.headers['Authorization'] == null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await TokenService.getToken();
      final userDataJson = await TokenService.getUserData();
      if (token != null && userDataJson != null && userDataJson.isNotEmpty) {
        final userData = json.decode(userDataJson);
        if (userData['photo'] != null &&
            !userData['photo'].startsWith('http')) {
          userData['photo'] = _getFullImageUrl(userData['photo']);
          await TokenService.saveUserData(json.encode(userData));
        }
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      AppLogger.log('Error restoring session: $e');
      await TokenService.clearAuthData();
    }
  }

  // -------------------------------------------------------------
  // FUNGSI LOGIN REGULER
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      AppLogger.log('Starting login process...');
      final loginRequest = LoginRequest(email: email, password: password);
      AppLogger.log(
        'Sending login request to: ${ApiConfig.getUrl(ApiConfig.loginEndpoint)}',
      );
      final response = await _dio.post(
        ApiConfig.getUrl(ApiConfig.loginEndpoint),
        data: loginRequest.toJson(),
        options: Options(
          headers: ApiConfig.headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      if (response.statusCode == 200) {
        return _processLoginSuccess(response.data, email);
      }
      return _processLoginError(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        if (e.response!.statusCode == 200) {
          return _processLoginSuccess(e.response!.data, email);
        }
        return _processLoginError(e.response!.data);
      }
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan tidak terduga: ${e.toString()}',
      };
    }
  }

  // -------------------------------------------------------------
  // FUNGSI LOGIN GOOGLE
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      AppLogger.log('Starting Google Sign-In...');

      // 🎯 PERBAIKAN: Melakukan signOut untuk memaksa munculnya Account Chooser
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Login Google dibatalkan oleh pengguna.'
        };
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Mengambil Access Token (yang dibutuhkan Back-End untuk userinfo)
      // Jika Access Token null, kita fallback menggunakan ID Token
      final String tokenToSend =
          googleAuth.accessToken ?? googleAuth.idToken ?? '';

      if (tokenToSend.isEmpty) {
        return {'success': false, 'message': 'Token otentikasi kosong.'};
      }

      AppLogger.log('Google Access Token berhasil diambil.');

      final response = await _dio.post(
        _googleLoginEndpoint,
        // Mengirim token ke Back-End
        data: {'access_token': tokenToSend},
        options: Options(
          headers: ApiConfig.headers,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return _processLoginSuccess(response.data, googleUser.email);
      }

      return _processLoginError(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        if (e.response!.statusCode == 200) {
          return _processLoginSuccess(e.response!.data, 'google_user@temp.com');
        }
        return _processLoginError(e.response!.data);
      }
      return {
        'success': false,
        'message': 'Gagal terhubung/verifikasi Google: ${e.message}',
      };
    } catch (e) {
      AppLogger.log('Error Google Sign-In: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat otentikasi Google: ${e.toString()}',
      };
    }
  }

  // -------------------------------------------------------------
  // FUNGSI HELPER PROSES LOGIN
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> _processLoginSuccess(
    dynamic responseData,
    String email,
  ) async {
    try {
      String? token;
      if (responseData is Map<String, dynamic>) {
        token = responseData['token'] ??
            responseData['access_token'] ??
            responseData['data']?['token'] ??
            responseData['data']?['access_token'];
      }
      if (token != null) {
        await TokenService.saveToken(token);
        dynamic userData;
        if (responseData is Map<String, dynamic>) {
          userData = responseData['user'] ?? responseData['data']?['user'];
        }

        final String? rawPhoneNumber = userData?['phone_number'];
        final String formattedPhoneNumber =
            _cleanAndFormatPhone(rawPhoneNumber);

        final user = User(
          id: userData?['id'] ?? 1,
          name: userData?['name'] ?? 'User',
          email: userData?['email'] ?? email,
          phoneNumber:
              formattedPhoneNumber.isEmpty ? null : formattedPhoneNumber,
          status: userData?['status'] ?? 'active',
          verificationStatus: userData?['verification_status'] ?? 'verified',
          emailVerifiedAt: userData?['email_verified_at'] ??
              DateTime.now().toIso8601String(),
          createdAt:
              userData?['created_at'] ?? DateTime.now().toIso8601String(),
          updatedAt:
              userData?['updated_at'] ?? DateTime.now().toIso8601String(),
          avatarUrl: userData?['avatar_url'],
          photo: _getFullImageUrl(userData?['photo']),
        );
        _currentUser = user;
        try {
          await TokenService.saveUserData(json.encode(user.toJson()));
        } catch (e) {
          AppLogger.log('Warning: Could not save user data: $e');
        }
        return {'success': true, 'message': 'Login berhasil!', 'user': user};
      }
      return {
        'success': false,
        'message': 'Login gagal: Tidak ada token dalam response',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memproses response login: ${e.toString()}',
      };
    }
  }

  Map<String, dynamic> _processLoginError(dynamic responseData) {
    String errorMessage = 'Login gagal';
    if (responseData != null) {
      if (responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else if (responseData['error'] != null) {
        errorMessage = responseData['error'];
      }
    }
    return {'success': false, 'message': errorMessage};
  }

  // -------------------------------------------------------------
  // FUNGSI REGISTER
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String? phoneNumber,
  }) async {
    try {
      final registerRequest = RegisterRequest(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: password,
        phoneNumber: phoneNumber,
      );
      final response = await _dio.post(
        ApiConfig.getUrl(ApiConfig.registerEndpoint),
        data: registerRequest.toJson(),
        options: Options(
          headers: ApiConfig.headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final apiResponse = ApiResponse.fromJson(
            response.data,
            (data) => User.fromJson(data),
          );
          if (apiResponse.success && apiResponse.data != null) {
            final user = apiResponse.data as User;
            return {
              'success': true,
              'message': 'Registrasi berhasil! Silakan login dengan akun Anda.',
              'user': user,
            };
          } else {
            return {
              'success': false,
              'message': apiResponse.message,
              'errors': apiResponse.errors,
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Terjadi kesalahan saat memproses response server',
          };
        }
      } else if (response.statusCode == 422) {
        final errorData = response.data;
        String errorMessage = 'Data yang dimasukkan tidak valid';
        Map<String, dynamic>? errors;

        if (errorData is Map<String, dynamic>) {
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
          if (errorData['errors'] != null) {
            errors = errorData['errors'];
            if (errors != null && errors.isNotEmpty) {
              List<String> errorList = [];
              errors.forEach((key, value) {
                if (value is List) {
                  errorList.addAll(value.cast<String>());
                } else {
                  errorList.add(value.toString());
                }
              });
              errorMessage = errorList.join(', ');
            }
          }
        }
        return {'success': false, 'message': errorMessage, 'errors': errors};
      } else {
        final errorData = response.data;
        String errorMessage = 'Registrasi gagal';
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
        return {'success': false, 'message': errorMessage};
      }
    } on DioException catch (e) {
      String errorMessage = 'Registrasi gagal';
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData is Map && errorData['errors'] != null) {
          errorMessage = errorData['errors'].toString();
        }
      } else {
        errorMessage = 'Tidak dapat terhubung ke server';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // -------------------------------------------------------------
  // FUNGSI UPDATE USER PROFILE
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String? phoneNumber,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
    File? imageFile,
  }) async {
    try {
      final Map<String, dynamic> fields = {'_method': 'PUT', 'name': name};

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        fields['phone_number'] = _cleanAndFormatPhone(phoneNumber);
      }

      if (currentPassword != null && currentPassword.isNotEmpty) {
        fields['current_password'] = currentPassword;
        if (newPassword != null && newPassword.isNotEmpty) {
          fields['new_password'] = newPassword;
        }
        if (newPasswordConfirmation != null &&
            newPasswordConfirmation.isNotEmpty) {
          fields['new_password_confirmation'] = newPasswordConfirmation;
        }
      }

      final formData = FormData.fromMap(fields);

      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'photo', // Nama field di API
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        ApiConfig.getUrl(ApiConfig.profileEndpoint),
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data?['success'] == true) {
        await getUserProfile();

        return {
          'success': true,
          'message':
              response.data?['message'] ?? 'Profile berhasil diperbarui!',
        };
      }

      String errorMessage =
          response.data?['message'] ?? 'Gagal memperbarui profile';

      if (response.statusCode == 422 && response.data?['errors'] != null) {
        final errors = response.data!['errors'] as Map<String, dynamic>;

        if (errors.containsKey('current_password')) {
          errorMessage = (errors['current_password'] as List).first.toString();
        } else if (errors.containsKey('new_password')) {
          errorMessage = (errors['new_password'] as List).first.toString();
        } else if (errors.containsKey('photo')) {
          errorMessage = (errors['photo'] as List).first.toString();
        } else if (errors.values.isNotEmpty) {
          errorMessage = (errors.values.first as List).first.toString();
        }
      }

      return {'success': false, 'message': errorMessage};
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan jaringan atau server';

      if (e.type == DioExceptionType.connectionError || e.response == null) {
        errorMessage = 'Koneksi gagal ke server. Cek VPN/URL/Koneksi Internet.';
      } else if (e.response?.data != null &&
          e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan tidak terduga: ${e.toString()}',
      };
    }
  }

  // -------------------------------------------------------------
  // FUNGSI GET USER PROFILE
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get(
        ApiConfig.getUrl(ApiConfig.profileEndpoint),
        options: Options(headers: ApiConfig.headers),
      );
      if (response.statusCode == 200 && response.data != null) {
        dynamic userData;
        if (response.data is Map<String, dynamic>) {
          userData = response.data['data'] ?? response.data;
        }
        if (userData != null) {
          final String? rawPhoneNumber = userData['phone_number'];
          final String formattedPhoneNumber = _cleanAndFormatPhone(
            rawPhoneNumber,
          );

          final user = User(
            id: userData['id'] ?? 0,
            name: userData['name'] ?? 'User',
            email: userData['email'] ?? 'user@example.com',
            phoneNumber:
                formattedPhoneNumber.isEmpty ? null : formattedPhoneNumber,
            role: userData['role'] != null
                ? Role.fromJson(userData['role'])
                : null,
            status: userData['status'] ?? 'active',
            verificationStatus: userData['verification_status'] ?? 'verified',
            emailVerifiedAt: userData['email_verified_at'],
            avatarUrl: userData['avatar_url'],
            photo: _getFullImageUrl(userData['photo']),
            createdAt:
                userData['created_at'] ?? DateTime.now().toIso8601String(),
            updatedAt:
                userData['updated_at'] ?? DateTime.now().toIso8601String(),
          );
          _currentUser = user;
          await TokenService.saveUserData(json.encode(user.toJson()));
          return {
            'success': true,
            'user': user,
            'message': 'Profile loaded successfully',
          };
        }
      }
      return {'success': false, 'message': 'Failed to load profile'};
    } on DioException catch (e) {
      String errorMessage =
          'Gagal memuat profil. Koneksi ke server bermasalah.';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // -------------------------------------------------------------
  // FUNGSI LOGOUT & RESEND VERIFICATION EMAIL
  // -------------------------------------------------------------
  Future<void> logout() async {
    try {
      await _dio.post(ApiConfig.getUrl(ApiConfig.logoutEndpoint));
    } catch (e) {
      AppLogger.log('Error calling logout API, forcing local clean up: $e');
    } finally {
      _currentUser = null;
      await TokenService.clearAuthData();
    }
  }

  static Future<bool> resendVerificationEmail(String token) async {
    try {
      final dio = Dio();
      final url = '${ApiConfig.baseUrl}/api/email/verification-notification';
      final response = await dio.post(
        url,
        options: Options(headers: ApiConfig.headersWithAuth(token)),
      );
      final status = response.statusCode ?? 0;
      return status >= 200 && status < 300;
    } catch (_) {
      return false;
    }
  }
}

class AuthProvider extends InheritedWidget {
  final AuthService authService;
  const AuthProvider({
    Key? key,
    required this.authService,
    required Widget child,
  }) : super(key: key, child: child);
  static AuthProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthProvider>();
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return oldWidget.authService.isLoggedIn != authService.isLoggedIn;
  }
}
