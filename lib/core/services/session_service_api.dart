import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class SessionServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get academic sessions
  Future<List<Map<String, dynamic>>> getSessions({
    int? sectionId,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      
      final response = await _apiService.get(
        ApiConfig.sessions(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final sessions = data['data'] as List;
        return sessions.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching sessions: $e');
    }
  }
  
  // Get session by ID
  Future<Map<String, dynamic>?> getSession(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.session(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching session: $e');
    }
  }
  
  // Create session
  Future<Map<String, dynamic>> createSession({
    required int sectionId,
    required String sessionName,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.sessions(schoolId),
        body: {
          'section_id': sectionId,
          'session_name': sessionName,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'is_active': isActive,
        },
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to create session');
      }
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }
  
  // Update academic session
  Future<Map<String, dynamic>> updateAcademicSession({
    required String schoolId,
    required String sectionId,
    required String sessionId,
    required String sessionName,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) async {
    try {
      final response = await _apiService.put(
        ApiConfig.session(int.tryParse(schoolId) ?? 0, int.tryParse(sessionId) ?? 0),
        body: {
          'session_name': sessionName,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'is_active': isActive,
        },
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update session');
      }
    } catch (e) {
      throw Exception('Error updating session: $e');
    }
  }
  
  // Delete academic session
  Future<void> deleteAcademicSession({
    required String schoolId,
    required String sectionId,
    required String sessionId,
  }) async {
    try {
      final response = await _apiService.delete(
        ApiConfig.session(int.tryParse(schoolId) ?? 0, int.tryParse(sessionId) ?? 0),
      );
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete session');
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting session: $e');
    }
  }
  
  // Delete session (alias)
  Future<void> deleteSession(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.session(schoolId, id),
      );
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete session');
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting session: $e');
    }
  }
}
