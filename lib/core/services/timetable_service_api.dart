import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class TimetableServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get timetable for logged in teacher (or specific criteria)
  Future<List<TimetableModel>> getTimetable({String? dayOfWeek, int? teacherId}) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final queryParams = <String, String>{};
      if (dayOfWeek != null) queryParams['day_of_week'] = dayOfWeek;
      if (teacherId != null) queryParams['teacher_id'] = teacherId.toString();

      final response = await _apiService.get(
        ApiConfig.timetables(schoolId),
        queryParameters: queryParams,
      );

      final data = response['data'] as List? ?? [];
      return data.map((e) => TimetableModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error loading timetable: $e');
    }
  }

  /// Create a timetable entry (Principal/Admin)
  Future<void> createEntry(Map<String, dynamic> data) async {
    try {
       final schoolId = await StorageHelper.getSchoolId();
       if (schoolId == null) throw Exception('School ID not found');
       
       await _apiService.post(
         ApiConfig.timetables(schoolId),
         body: data,
       );
       
       notifyListeners();
    } catch (e) {
      throw Exception('Error creating timetable entry: $e');
    }
  }
}
