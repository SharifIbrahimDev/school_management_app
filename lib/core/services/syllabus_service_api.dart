import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class SyllabusServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get syllabus topics with optional filters
  Future<List<dynamic>> getSyllabuses({
    int? sectionId,
    int? classId,
    int? subjectId,
    String? status,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (subjectId != null) queryParams['subject_id'] = subjectId.toString();
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/schools/$schoolId/syllabuses',
        queryParameters: queryParams,
      );

      return List<dynamic>.from(response['data'] ?? []);
    } catch (e) {
      throw Exception('Error loading syllabus: $e');
    }
  }

  /// Create a new syllabus topic
  Future<void> createSyllabus(Map<String, dynamic> data) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.post(
        '${ApiConfig.baseUrl}/schools/$schoolId/syllabuses',
        body: data,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error creating syllabus topic: $e');
    }
  }

  /// Update syllabus status or completion date
  Future<void> updateSyllabus(int id, Map<String, dynamic> data) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.put(
        '${ApiConfig.baseUrl}/schools/$schoolId/syllabuses/$id',
        body: data,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error updating syllabus: $e');
    }
  }

  /// Delete syllabus topic
  Future<void> deleteSyllabus(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.delete(
        '${ApiConfig.baseUrl}/schools/$schoolId/syllabuses/$id',
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting syllabus: $e');
    }
  }
}
