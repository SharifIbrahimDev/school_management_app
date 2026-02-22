import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class UserServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get users
  Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    int? sectionId,
    bool? isActive,
    int? limit,
    int page = 1,
    String? search,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (role != null) queryParams['role'] = role;
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (search != null) queryParams['search'] = search;
      
      final response = await _apiService.get(
        ApiConfig.users(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final users = data['data'] as List;
        return users.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }
  
  // Get user by ID
  Future<Map<String, dynamic>?> getUser(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.user(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }
  
  // Create user
  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String phoneNumber,
    String? address,
    int? sectionId,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.users(schoolId),
        body: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role,
          'phone_number': phoneNumber,
          if (address != null) 'address': address,
          if (sectionId != null) 'section_id': sectionId,
        },
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }
  
  // Update user
  Future<Map<String, dynamic>> updateUser(
    int id, {
    String? fullName,
    String? email,
    String? password,
    String? role,
    String? phoneNumber,
    String? address,
    int? sectionId,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (role != null) body['role'] = role;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (address != null) body['address'] = address;
      if (sectionId != null) body['section_id'] = sectionId;
      if (isActive != null) body['is_active'] = isActive;
      
      final response = await _apiService.put(
        ApiConfig.user(schoolId, id),
        body: body,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }
  
  // Delete user
  Future<void> deleteUser(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.user(schoolId, id),
      );
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}
