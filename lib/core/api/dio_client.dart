import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_interceptors.dart';

/// Provides a configured Dio instance with auth interceptors.
/// Use ApiService for all HTTP calls in the live app — this client
/// is kept for any future migration to Dio-based services.
Dio createDioClient(TokenStorage tokenStorage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.currentBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(ApiInterceptors(tokenStorage));

  // Add logging interceptor for development only
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
}
