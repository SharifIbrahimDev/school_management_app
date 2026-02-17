import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageHelper {
  static const _secureStorage = FlutterSecureStorage();
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _schoolIdKey = 'school_id';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  
  // Save authentication token securely
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  // Get authentication token securely
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  // Clear authentication token
  static Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
  
  // Save user data securely
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _secureStorage.write(key: _userKey, value: jsonEncode(user));
  }
  
  // Get user data securely
  static Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }
  
  // Clear user data
  static Future<void> clearUser() async {
    await _secureStorage.delete(key: _userKey);
  }
  
  // Save school ID securely
  static Future<void> saveSchoolId(int schoolId) async {
    await _secureStorage.write(key: _schoolIdKey, value: schoolId.toString());
  }
  
  // Get school ID securely
  static Future<int?> getSchoolId() async {
    final schoolIdStr = await _secureStorage.read(key: _schoolIdKey);
    return schoolIdStr != null ? int.tryParse(schoolIdStr) : null;
  }
  
  // Clear school ID
  static Future<void> clearSchoolId() async {
    await _secureStorage.delete(key: _schoolIdKey);
  }
  
  // --- Biometric Preferences ---

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // --- Remember Me Support ---

  static Future<void> setRememberMe(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, enabled);
  }

  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _savedEmailKey, value: email);
    await _secureStorage.write(key: _savedPasswordKey, value: password);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final email = await _secureStorage.read(key: _savedEmailKey);
    final password = await _secureStorage.read(key: _savedPasswordKey);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  static Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _savedEmailKey);
    await _secureStorage.delete(key: _savedPasswordKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await clearToken();
    await clearUser();
    await clearSchoolId();
    await prefs.remove(_biometricEnabledKey);
    // Note: We might want to keep Remember Me or clear it depending on logic.
    // For a full logout/clear, better to clear credentials too.
    await clearCredentials();
    await prefs.remove(_rememberMeKey);
    
    // Clear all cache keys
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('cache_')) {
        await prefs.remove(key);
      }
    }
    // Also clear generic storage from secure storage
    final allSecure = await _secureStorage.readAll();
    for (var key in allSecure.keys) {
      if (key.startsWith('cache_')) {
        await _secureStorage.delete(key: key);
      }
    }
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // --- Generic Cache Methods (Now Secure) ---

  // Save generic data to cache
  static Future<void> saveCache(String key, dynamic data) async {
    await _secureStorage.write(key: 'cache_$key', value: jsonEncode(data));
  }

  // Get generic data from cache
  static Future<dynamic> getCache(String key) async {
    final dataJson = await _secureStorage.read(key: 'cache_$key');
    if (dataJson != null) {
      try {
        return jsonDecode(dataJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
