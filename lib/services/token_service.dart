import 'package:desaku/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _loginTimeKey = 'login_time';
  static const int _sessionDurationHours = 1;
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenSaved = await prefs.setString(_tokenKey, token);
      final timeSaved = await prefs.setInt(_loginTimeKey, now);
      return tokenSaved && timeSaved;
    } catch (e) {
      AppLogger.log('Error saving token: $e');
      return false;
    }
  }

  static Future<bool> saveUserData(String userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userKey, userData);
    } catch (e) {
      AppLogger.log('Error saving user data: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      AppLogger.log('Error getting token: $e');
      return null;
    }
  }

  static Future<String?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userKey);
    } catch (e) {
      AppLogger.log('Error getting user data: $e');
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    final valid = await isSessionValid();

    if (!valid) {
      AppLogger.log('Session expired. Clearing old auth data.');
      await clearAuthData();
      return false;
    }

    return true;
  }

  static Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTime = prefs.getInt(_loginTimeKey);

      if (loginTime == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionDuration = Duration(hours: _sessionDurationHours);
      final sessionExpiry = loginTime + sessionDuration.inMilliseconds;

      return now < sessionExpiry;
    } catch (e) {
      AppLogger.log('Error checking session validity: $e');
      return false;
    }
  }

  static Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_loginTimeKey);
      return true;
    } catch (e) {
      AppLogger.log('Error clearing auth data: $e');
      return false;
    }
  }
}
