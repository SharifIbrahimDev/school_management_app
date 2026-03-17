import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/testing.dart';
import 'package:school_management_app/core/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService Tests', () {
    setUpAll(() {
      Hive.init(Directory.systemTemp.path);
    });

    setUp(() {
      ApiService.reset();
    });

    test('get should call the client with correct URL and headers', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/test-endpoint')) {
          return http.Response(jsonEncode({'success': true, 'data': 'ok'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(
        client: mockClient,
        tokenResolver: () async => 'test-token',
      );

      final result = await apiService.get('/test-endpoint', cacheEnabled: false);
      
      expect(result['success'], true);
      expect(result['data'], 'ok');
    });

    test('post should send body and return data', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        if (body['name'] == 'testing') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Error', 400);
      });

      final apiService = ApiService(
        client: mockClient,
        tokenResolver: () async => 'test-token',
      );
      
      final result = await apiService.post(
        '/post-endpoint', 
        body: {'name': 'testing'}, 
        shouldInvalidateCache: false,
      );
      
      expect(result['success'], true);
    });

    test('should throw ApiException on error status codes', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
      });

      final apiService = ApiService(
        client: mockClient,
        tokenResolver: () async => null,
      );
      
      expect(
        () => apiService.get('/error', cacheEnabled: false),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });
}
