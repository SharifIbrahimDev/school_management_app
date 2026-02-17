import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class ClassServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get classes
  Future<List<Map<String, dynamic>>> getClasses({
    int? sectionId,
    int? teacherId,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (teacherId != null) queryParams['form_teacher_id'] = teacherId.toString();
      
      final response = await _apiService.get(
        ApiConfig.classes(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final classes = data['data'] as List;
        return classes.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching classes: $e');
    }
  }
  
  // Get class by ID
  Future<Map<String, dynamic>?> getClass(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.classItem(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching class: $e');
    }
  }
  
  // Get class statistics
  Future<Map<String, dynamic>> getClassStatistics(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.classStatistics(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      throw Exception('Error fetching class statistics: $e');
    }
  }


  // Create class
  Future<Map<String, dynamic>> createClass({
    required int sectionId,
    required String className,
    int? formTeacherId,
    int? capacity,
    bool isActive = true,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.classes(schoolId),
        body: {
          'section_id': sectionId,
          'class_name': className,
          if (formTeacherId != null) 'form_teacher_id': formTeacherId,
          if (capacity != null) 'capacity': capacity,
          'is_active': isActive,
        },
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to create class');
      }
    } catch (e) {
      throw Exception('Error creating class: $e');
    }
  }

  // Update class
  Future<Map<String, dynamic>> updateClass(
    int id, {
    String? className,
    int? formTeacherId,
    bool unassignTeacher = false,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final body = <String, dynamic>{};
      if (className != null) body['class_name'] = className;
      if (formTeacherId != null) body['form_teacher_id'] = formTeacherId;
      if (unassignTeacher) body['form_teacher_id'] = null;
      if (isActive != null) body['is_active'] = isActive;
      
      final response = await _apiService.put(
        ApiConfig.classItem(schoolId, id),
        body: body,
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update class');
      }
    } catch (e) {
      throw Exception('Error updating class: $e');
    }
  }

  // Delete class
  Future<void> deleteClass(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.classItem(schoolId, id),
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return;
      }
      
      throw Exception(response['message'] ?? 'Failed to delete class');
    } catch (e) {
      throw Exception('Error deleting class: $e');
    }
  }
}
