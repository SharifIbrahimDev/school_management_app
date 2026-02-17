import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      // The API structure might have user nested under "data"
      final userData = response.data['data'] ?? response.data;
      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'Something went wrong';
      return message;
    }
    return 'Network error. Please check your connection.';
  }
}
