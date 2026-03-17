import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/persistent_storage_service.dart';

class StorageHelper {
  static final IStorageService _service = PersistentStorageService();

  // ==============================
  // Basic Auth methods
  // ==============================

  static Future<void> saveToken(String token) => _service.saveToken(token);
  static Future<String?> getToken() => _service.getToken();
  static Future<void> clearToken() => _service.clearToken();

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _service.saveUser(user);

  static Future<Map<String, dynamic>?> getUser() => _service.getUser();

  static Future<void> clearUser() => _service.clearUser();

  static Future<void> saveSchoolId(int schoolId) =>
      _service.saveSchoolId(schoolId);

  static Future<int?> getSchoolId() => _service.getSchoolId();

  static Future<void> clearSchoolId() => _service.clearSchoolId();

  static Future<void> clearAll() => _service.clearAll();

  // ==============================
  // Biometric / Remember methods
  // ==============================

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _rememberMeKey = 'remember_me';

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<void> setRememberMe(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, enabled);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }

    return null;
  }

  static Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }

  // ==============================
  // Cache Support
  // ==============================

  static Future<void> saveCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data == null) {
      await prefs.remove(key);
      return;
    }

    if (data is String) {
      await prefs.setString(key, data);
    } else if (data is int) {
      await prefs.setInt(key, data);
    } else if (data is bool) {
      await prefs.setBool(key, data);
    } else {
      await prefs.setString(key, jsonEncode(data));
    }
  }

  static Future<dynamic> getCache(String key) async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(key)) return null;

    final value = prefs.get(key);

    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }

    return value;
  }

  static Future<void> removeCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}