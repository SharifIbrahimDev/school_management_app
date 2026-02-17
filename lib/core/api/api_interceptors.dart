import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

class ApiInterceptors extends Interceptor {
  final TokenStorage _tokenStorage;
  final Ref _ref;

  ApiInterceptors(this._tokenStorage, this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Unauthorized - clear token and potentially redirect to login
      await _tokenStorage.deleteToken();
      // You can use a provider to trigger a logout/navigation in the UI
      // _ref.read(authProvider.notifier).logout(); 
    }
    super.onError(err, handler);
  }
}
