import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class ExamServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get exams filtered by class or subject
  Future<List<dynamic>> getExams({int? classId, int? subjectId}) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final queryParams = <String, String>{};
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (subjectId != null) queryParams['subject_id'] = subjectId.toString();

      final response = await _apiService.get(
        ApiConfig.exams(schoolId),
        queryParameters: queryParams,
      );

      return List<dynamic>.from(response as List? ?? (response['data'] ?? []));
    } catch (e) {
      throw Exception('Error loading exams: $e');
    }
  }

  /// Create a new exam
  Future<void> createExam(Map<String, dynamic> data) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.post(
        ApiConfig.exams(schoolId),
        body: data,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error creating exam: $e');
    }
  }

  /// Get results for an exam
  Future<List<dynamic>> getResults(int examId) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.get(
        ApiConfig.examResults(schoolId, examId),
      );

      return List<dynamic>.from(response as List? ?? (response['data'] ?? []));
    } catch (e) {
      throw Exception('Error loading results: $e');
    }
  }

  /// Save bulk results
  Future<void> saveResults(int examId, List<Map<String, dynamic>> results) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.post(
        ApiConfig.examResults(schoolId, examId),
        body: {'results': results},
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error saving results: $e');
    }
  }

  /// Get academic analytics for a section
  Future<Map<String, dynamic>> getAcademicAnalytics({required int sectionId}) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.get(
        '${ApiConfig.exams(schoolId)}/academic-analytics',
        queryParameters: {'section_id': sectionId.toString()},
      );

      return Map<String, dynamic>.from(response['data'] ?? {});
    } catch (e) {
      throw Exception('Error loading academic analytics: $e');
    }
  }
}
