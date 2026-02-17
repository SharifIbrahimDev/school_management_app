import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class FeeServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get fees
  Future<List<Map<String, dynamic>>> getFees({
    int? sectionId,
    int? sessionId,
    int? termId,
    int? classId,
    int? studentId,
    String? feeScope,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (sessionId != null) queryParams['session_id'] = sessionId.toString();
      if (termId != null) queryParams['term_id'] = termId.toString();
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (studentId != null) queryParams['student_id'] = studentId.toString();
      if (feeScope != null) queryParams['fee_scope'] = feeScope;
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      
      final response = await _apiService.get(
        ApiConfig.fees(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final fees = data['data'] as List;
        return fees.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching fees: $e');
    }
  }
  
  // Get fee by ID
  Future<Map<String, dynamic>?> getFee(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.fee(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching fee: $e');
    }
  }
  
  // Get fee summary
  Future<Map<String, dynamic>> getFeeSummary({
    int? sectionId,
    int? sessionId,
    int? termId,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (sessionId != null) queryParams['session_id'] = sessionId.toString();
      if (termId != null) queryParams['term_id'] = termId.toString();
      
      final response = await _apiService.get(
        ApiConfig.feesSummary(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      throw Exception('Error fetching fee summary: $e');
    }
  }
  
  // Add fee
  Future<Map<String, dynamic>> addFee({
    required int sectionId,
    required int sessionId,
    required int termId,
    int? classId,
    int? studentId,
    required String feeName,
    required double amount,
    required String feeScope,
    String? dueDate,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.fees(schoolId),
        body: {
          'section_id': sectionId,
          'session_id': sessionId,
          'term_id': termId,
          if (classId != null) 'class_id': classId,
          if (studentId != null) 'student_id': studentId,
          'fee_name': feeName,
          'amount': amount,
          'fee_scope': feeScope,
          if (dueDate != null) 'due_date': dueDate,
          if (description != null) 'description': description,
          'is_active': isActive,
        },
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to add fee');
      }
    } catch (e) {
      throw Exception('Error adding fee: $e');
    }
  }
  
  // Create fee (alias for addFee for backward compatibility)
  Future<Map<String, dynamic>> createFee({
    required int sectionId,
    required int sessionId,
    required int termId,
    int? classId,
    int? studentId,
    required String feeName,
    required double amount,
    required String feeScope,
    String? dueDate,
    String? description,
    bool isActive = true,
  }) => addFee(
    sectionId: sectionId,
    sessionId: sessionId,
    termId: termId,
    classId: classId,
    studentId: studentId,
    feeName: feeName,
    amount: amount,
    feeScope: feeScope,
    dueDate: dueDate,
    description: description,
    isActive: isActive,
  );

  // Delete fee
  Future<void> deleteFee(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.fee(schoolId, id),
      );
      
      if (response['success'] == true) {
        return;
      }
      
      throw Exception(response['message'] ?? 'Failed to delete fee');
    } catch (e) {
      throw Exception('Error deleting fee: $e');
    }
  }
  // Update fee
  Future<Map<String, dynamic>> updateFee(
    int id, {
    int? sectionId,
    int? sessionId,
    int? termId,
    int? classId,
    int? studentId,
    String? feeName,
    double? amount,
    String? feeScope,
    String? dueDate,
    String? description,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final body = <String, dynamic>{};
      if (sectionId != null) body['section_id'] = sectionId;
      if (sessionId != null) body['session_id'] = sessionId;
      if (termId != null) body['term_id'] = termId;
      if (classId != null) body['class_id'] = classId;
      if (studentId != null) body['student_id'] = studentId;
      if (feeName != null) body['fee_name'] = feeName;
      if (amount != null) body['amount'] = amount;
      if (feeScope != null) body['fee_scope'] = feeScope;
      if (dueDate != null) body['due_date'] = dueDate;
      if (description != null) body['description'] = description;
      if (isActive != null) body['is_active'] = isActive;
      
      final response = await _apiService.put(
        ApiConfig.fee(schoolId, id),
        body: body,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update fee');
      }
    } catch (e) {
      throw Exception('Error updating fee: $e');
    }
  }
}
