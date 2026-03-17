import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiInterceptors extends Interceptor {
  final TokenStorage _tokenStorage;

  ApiInterceptors(this._tokenStorage);

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
      // Unauthorized — clear token so next app start requires re-login
      await _tokenStorage.deleteToken();
    }
    super.onError(err, handler);
  }
}
