import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import 'api_interceptors.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

final dioProvider = Provider((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final tokenStorage = ref.read(tokenStorageProvider);
  dio.interceptors.add(ApiInterceptors(tokenStorage, ref));
  
  // Add logging interceptor for development
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
});
