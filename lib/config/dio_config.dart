import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/token_service.dart';
import 'package:desaku/utils/app_logger.dart';

class DioConfig {
  static Dio? _instance;
  static Dio get dio {
    _instance ??= createDio();
    return _instance!;
  }

  static Dio createDio() {
    final dio = Dio();

    dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      // 🚀 NAIKKAN RECEIVETIMEOUT DAN SENDTIMEOUT KE 120 DETIK
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: {...ApiConfig.headers, 'Content-Type': 'application/json'},
      validateStatus: (status) {
        return status != null && status >= 200 && status < 500;
      },
    );

    // ... (InterceptorsWrapper Anda tetap sama)
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          AppLogger.log('DIO LOG: $obj');
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) {
          AppLogger.log('DIO ERROR: ${err.message}');
          AppLogger.log('DIO ERROR TYPE: ${err.type}');
          AppLogger.log('DIO ERROR RESPONSE: ${err.response?.data}');
          handler.next(err);
        },
        onRequest: (options, handler) async {
          try {
            final token = await TokenService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers.putIfAbsent(
                'Authorization',
                () => 'Bearer $token',
              );
            }
          } catch (e) {}

          AppLogger.log('Request: ${options.method} ${options.uri}');
          AppLogger.log('Headers: ${options.headers}');
          AppLogger.log('Data: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.log('Response: ${response.statusCode}');
          AppLogger.log('Data: ${response.data}');
          handler.next(response);
        },
      ),
    );

    return dio;
  }
}
