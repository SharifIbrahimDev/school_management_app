import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class AttendanceServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get attendance for a specific class/section and date
  /// Get attendance for a specific class/section and date with offline caching
  Future<List<dynamic>> getAttendance({required int classId, int? sectionId, required DateTime date}) async {
    final schoolId = await StorageHelper.getSchoolId();
    if (schoolId == null) throw Exception('School ID not found');

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final cacheKey = 'attendance_${schoolId}_${classId}_${sectionId ?? "all"}_$dateStr';

    try {
      final queryParams = {
        'class_id': classId.toString(),
        'date': dateStr,
      };
      
      if (sectionId != null) {
        queryParams['section_id'] = sectionId.toString();
      }

      final response = await _apiService.get(
        ApiConfig.attendance(schoolId),
        queryParameters: queryParams,
      );

      final data = List<dynamic>.from(response as List? ?? (response['data'] ?? []));
      
      // Save to cache
      await StorageHelper.saveCache(cacheKey, data);
      
      return data;
    } catch (e) {
      // Try loading from cache
      final cachedData = await StorageHelper.getCache(cacheKey);
      if (cachedData != null) {
        return cachedData as List<dynamic>;
      }
      throw Exception('Error loading attendance (offline): $e');
    }
  }

  /// Save (mark) attendance
  /// [attendances] should be list of maps with student_id, status, remark(optional)
  Future<void> saveAttendance({
    required int classId,
    int? sectionId,
    required DateTime date,
    required List<Map<String, dynamic>> attendances,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final body = {
        'class_id': classId,
        'date': dateStr,
        'attendances': attendances,
      };
      
      if (sectionId != null) {
        body['section_id'] = sectionId;
      }

      await _apiService.post(
        ApiConfig.attendance(schoolId),
        body: body,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error saving attendance: $e');
    }
  }

  /// Get attendance summary for a section
  Future<Map<String, dynamic>> getSectionSummary({required int sectionId, required DateTime date}) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _apiService.get(
        '${ApiConfig.attendance(schoolId)}/section-summary',
        queryParameters: {
          'section_id': sectionId.toString(),
          'date': dateStr,
        },
      );

      return Map<String, dynamic>.from(response['data'] ?? {});
    } catch (e) {
      throw Exception('Error loading section attendance summary: $e');
    }
  }
  /// Get summary of attendance for a student (percentage, present count)
  Future<Map<String, dynamic>> getStudentAttendanceSummary(int studentId) async {
    final schoolId = await StorageHelper.getSchoolId();
    if (schoolId == null) throw Exception('School ID not found');

    try {
      final response = await _apiService.get(ApiConfig.studentAttendance(schoolId, studentId));
      
      // If response is list (detailed attendance), calculate summary locally
      if (response['data'] is List) {
        final list = response['data'] as List;
        int present = 0;
        for (var item in list) {
          final status = item['status']?.toString().toLowerCase() ?? '';
          if (status == 'present' || status == 'p') present++;
        }
        double percentage = list.isEmpty ? 0.0 : (present / list.length) * 100;
        return {
          'present': present,
          'total': list.length,
          'percentage': percentage,
        };
      } 
      // If response['data'] is Map (already a summary)
      else if (response['data'] is Map) {
        return Map<String, dynamic>.from(response['data']);
      }
      
      return {'percentage': 0.0, 'present': 0, 'total': 0};
    } catch (e) {
      // Return empty stats on error to avoid breaking dashboard
      return {'percentage': 0.0, 'present': 0, 'total': 0}; 
    }
  }
}
