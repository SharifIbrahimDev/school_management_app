import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class HomeworkServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get homework for a specific class/section
  Future<List<dynamic>> getHomework({int? classId, int? sectionId}) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final queryParams = <String, String>{'school_id': schoolId.toString()};
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();

      // Assuming homeworks endpoint is /schools/{schoolId}/homeworks or just /homeworks
      // Based on my ApiConfig assumption, I'll use ApiConfig.
      // Wait, I haven't added homeworks to ApiConfig yet. I should do that.
      // For now I'll use the pattern '$baseUrl/homeworks' if global, or schools scoped.
      // The backend route is `apiResource('homeworks', ...)` which is /api/homeworks.
      // So no need for school ID in URL path, but maybe query param?
      
      final response = await _apiService.get(
        ApiConfig.homeworks,
        queryParameters: queryParams,
      );

      final data = response['data'] as List? ?? [];
      return data;
    } catch (e) {
      throw Exception('Error loading homework: $e');
    }
  }

  /// Create new homework (Teacher only)
  Future<void> createHomework(Map<String, dynamic> data) async {
    try {
      await _apiService.post(ApiConfig.homeworks, body: data);
      notifyListeners();
    } catch (e) {
      throw Exception('Error creating homework: $e');
    }
  }
}
