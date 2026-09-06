// lib/config/api_config.dart (Final)

class ApiConfig {
  // Pastikan tidak ada slash (/) di akhir URL
  static const String baseUrl = 'https://smart-village-web.citiasiainc.id';

  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/users';
  static const String logoutEndpoint = '/api/auth/logout';

  // 💡 TAMBAHKAN ENDPOINT BARU UNTUK GOOGLE LOGIN
  static const String googleLoginEndpoint =
      '/api/auth/google'; // Asumsi path server Anda

  // *** PATH YANG BENAR UNTUK BACKEND ANDA ***
  static const String profileEndpoint = '/api/profile-user';
  // *****************************************
  static const String userEndpoint = '/api/auth/user';
  static const String settingsEndpoint = '/api/settings';

  static const Map<String, String> headers = {'Accept': 'application/json'};

  static Map<String, String> headersWithAuth(String token) {
    return {...headers, 'Authorization': 'Bearer $token'};
  }

  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
