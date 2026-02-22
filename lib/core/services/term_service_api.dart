import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class TermServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get terms
  Future<List<Map<String, dynamic>>> getTerms({
    int? sectionId,
    int? sessionId,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (sessionId != null) queryParams['session_id'] = sessionId.toString();
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      
      final response = await _apiService.get(
        ApiConfig.terms(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final terms = data['data'] as List;
        return terms.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching terms: $e');
    }
  }
  
  // Get term by ID
  Future<Map<String, dynamic>?> getTerm(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.term(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching term: $e');
    }
  }
  
  // Create term
  Future<Map<String, dynamic>> createTerm({
    required String schoolId,
    required String sectionId,
    required String sessionId,
    required String termName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.terms(int.parse(schoolId)),
        body: {
          'section_id': int.parse(sectionId),
          'session_id': int.parse(sessionId),
          'term_name': termName,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'is_active': true,
        },
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      }
      
      throw Exception(response['message'] ?? 'Failed to create term');
    } catch (e) {
      throw Exception('Error creating term: $e');
    }
  }
  
  // Update term
  Future<Map<String, dynamic>> updateTerm({
    required int id,
    String? termName,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final data = <String, dynamic>{};
      if (termName != null) data['term_name'] = termName;
      if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];
      if (isActive != null) data['is_active'] = isActive;
      
      final response = await _apiService.put(
        ApiConfig.term(schoolId, id),
        body: data,
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      }
      
      throw Exception(response['message'] ?? 'Failed to update term');
    } catch (e) {
      throw Exception('Error updating term: $e');
    }
  }
  
  // Delete term
  Future<void> deleteTerm(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.term(schoolId, id),
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return;
      }
      
      throw Exception(response['message'] ?? 'Failed to delete term');
    } catch (e) {
      throw Exception('Error deleting term: $e');
    }
  }
}
