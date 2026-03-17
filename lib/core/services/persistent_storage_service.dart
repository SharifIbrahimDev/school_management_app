import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'storage_service.dart';

class PersistentStorageService implements IStorageService {
  final FlutterSecureStorage _secureAccess;
  
  PersistentStorageService({FlutterSecureStorage? secureStorage}) 
      : _secureAccess = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _schoolIdKey = 'school_id';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _rememberMeKey = 'remember_me';

  @override
  Future<void> saveToken(String token) async => await _secureAccess.write(key: _tokenKey, value: token);

  @override
  Future<String?> getToken() async => await _secureAccess.read(key: _tokenKey);

  @override
  Future<void> clearToken() async => await _secureAccess.delete(key: _tokenKey);

  @override
  Future<void> saveUser(Map<String, dynamic> user) async => await _secureAccess.write(key: _userKey, value: jsonEncode(user));

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _secureAccess.read(key: _userKey);
    return userJson != null ? jsonDecode(userJson) as Map<String, dynamic> : null;
  }

  @override
  Future<void> clearUser() async => await _secureAccess.delete(key: _userKey);

  @override
  Future<void> saveSchoolId(int schoolId) async => await _secureAccess.write(key: _schoolIdKey, value: schoolId.toString());

  @override
  Future<int?> getSchoolId() async {
    final id = await _secureAccess.read(key: _schoolIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  @override
  Future<void> clearSchoolId() async => await _secureAccess.delete(key: _schoolIdKey);

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureAccess.deleteAll();
    await prefs.clear();
  }

  @override
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
