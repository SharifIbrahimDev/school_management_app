import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/subject_model.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class SubjectServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Future<List<SubjectModel>> getSubjects({int? schoolId, int? classId}) async {
    try {
      final effectiveSchoolId = schoolId ?? await StorageHelper.getSchoolId();
      if (effectiveSchoolId == null) throw Exception('School ID not found');

      final queryParams = <String, String>{};
      if (classId != null) {
        queryParams['class_id'] = classId.toString();
      }

      final response = await _apiService.get(
        ApiConfig.subjects(effectiveSchoolId),
        queryParameters: queryParams,
      );

      final List<dynamic> data = response as List? ?? (response['data'] ?? []);
      return data.map((item) => SubjectModel.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Error loading subjects: $e');
    }
  }

  Future<void> createSubject(Map<String, dynamic> subjectData) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.post(
        ApiConfig.subjects(schoolId),
        body: subjectData,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error creating subject: $e');
    }
  }

  Future<void> updateSubject(int id, Map<String, dynamic> subjectData) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.put(
        ApiConfig.subject(schoolId, id),
        body: subjectData,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error updating subject: $e');
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      await _apiService.delete(
        ApiConfig.subject(schoolId, id),
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting subject: $e');
    }
  }
}
