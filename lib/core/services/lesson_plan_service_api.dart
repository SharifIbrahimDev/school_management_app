import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class LessonPlanServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get lesson plans with optional filters
  Future<List<dynamic>> getLessonPlans({
    int? sectionId,
    int? classId,
    int? subjectId,
    int? teacherId,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (subjectId != null) queryParams['subject_id'] = subjectId.toString();
      if (teacherId != null) queryParams['teacher_id'] = teacherId.toString();

      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/schools/$schoolId/lesson-plans',
        queryParameters: queryParams,
      );

      return List<dynamic>.from(response['data'] ?? []);
    } catch (e) {
      throw Exception('Error loading lesson plans: $e');
    }
  }

  /// Create a new lesson plan
  Future<void> createLessonPlan(Map<String, dynamic> data) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.post(
        '${ApiConfig.baseUrl}/schools/$schoolId/lesson-plans',
        body: data,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error creating lesson plan: $e');
    }
  }

  /// Update lesson plan status or content
  Future<void> updateLessonPlan(int id, Map<String, dynamic> data) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.put(
        '${ApiConfig.baseUrl}/schools/$schoolId/lesson-plans/$id',
        body: data,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error updating lesson plan: $e');
    }
  }

  /// Delete lesson plan
  Future<void> deleteLessonPlan(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.delete(
        '${ApiConfig.baseUrl}/schools/$schoolId/lesson-plans/$id',
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting lesson plan: $e');
    }
  }
}
