import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/testing.dart';
import 'package:school_management_app/core/services/api_service.dart';
import 'package:school_management_app/core/services/auth_service_api.dart';
import 'package:school_management_app/core/services/storage_service.dart';

class MockStorage implements IStorageService {
  Map<String, dynamic> data = {};
  
  @override
  Future<void> saveToken(String token) async => data['token'] = token;
  @override
  Future<String?> getToken() async => data['token'];
  @override
  Future<void> clearToken() async => data.remove('token');
  @override
  Future<void> saveUser(Map<String, dynamic> user) async => data['user'] = user;
  @override
  Future<Map<String, dynamic>?> getUser() async => data['user'];
  @override
  Future<void> clearUser() async => data.remove('user');
  @override
  Future<void> saveSchoolId(int schoolId) async => data['school_id'] = schoolId;
  @override
  Future<int?> getSchoolId() async => data['school_id'];
  @override
  Future<void> clearSchoolId() async => data.remove('school_id');
  @override
  Future<void> clearAll() async => data.clear();

  @override
  Future<bool> isBiometricEnabled() async => data['biometric_enabled'] ?? false;
  @override
  Future<void> setBiometricEnabled(bool enabled) async => data['biometric_enabled'] = enabled;
  @override
  Future<bool> isLoggedIn() async => data['token'] != null;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthServiceApi Tests', () {
    late AuthServiceApi authService;
    late MockStorage mockStorage;
    late ApiService apiService;

    setUpAll(() {
      Hive.init(Directory.systemTemp.path);
    });

    setUp(() {
      ApiService.reset();
      mockStorage = MockStorage();
    });

    test('login should update current user and save token', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'success': true,
          'data': {
            'token': 'fake-token',
            'user': {'id': 1, 'full_name': 'Test User', 'role': 'proprietor'}
          }
        }), 200);
      });

      apiService = ApiService(
        client: mockClient,
        tokenResolver: () async => mockStorage.data['token'],
        storage: mockStorage,
      );

      authService = AuthServiceApi(
        apiService: apiService,
        storage: mockStorage,
      );

      final result = await authService.login('test@example.com', 'password');
      
      expect(result['full_name'], 'Test User');
      expect(authService.currentUserModel?.fullName, 'Test User');
      expect(mockStorage.data['user']['full_name'], 'Test User');
    });

    test('logout should clear local data', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'success': true}), 200);
      });

      apiService = ApiService(client: mockClient, storage: mockStorage);
      authService = AuthServiceApi(apiService: apiService, storage: mockStorage);

      // Pre-fill some data
      await mockStorage.saveToken('old-token');
      await mockStorage.saveUser({'id': 1});

      await authService.logout();

      expect(authService.currentUser, isNull);
      expect(mockStorage.data, isEmpty);
    });
  });
}
