import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class ReportServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get financial summary for charts
  Future<List<Map<String, dynamic>>> getFinancialSummary({int? year}) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.get(
        ApiConfig.reportFinancialSummary(schoolId),
        queryParameters: {'year': (year ?? DateTime.now().year).toString()},
      );

      final List<dynamic> data = response['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Error loading annual summary: $e');
    }
  }

  /// Get payment method distribution
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.get(ApiConfig.reportPaymentMethods(schoolId));
      final List<dynamic> data = response['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Error loading payment methods: $e');
    }
  }

  /// Get collection stats
  Future<Map<String, dynamic>> getCollectionStats() async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.get(ApiConfig.reportFeeCollection(schoolId));
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      throw Exception('Error loading collection stats: $e');
    }
  }

  /// Get list of debtors
  Future<List<Map<String, dynamic>>> getDebtors({int? sectionId}) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();

      final response = await _apiService.get(
        ApiConfig.reportDebtors(schoolId),
        queryParameters: queryParams,
      );

      final List<dynamic> data = response['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Error loading debtors list: $e');
    }
  }

  /// Get academic report card
  /// Get academic report card with offline caching
  Future<Map<String, dynamic>> getAcademicReportCard(int studentId, {int? termId, int? sessionId}) async {
    final schoolId = await StorageHelper.getSchoolId();
    if (schoolId == null) throw Exception('School ID not found');

    final cacheKey = 'report_card_${schoolId}_${studentId}_${termId ?? "curr"}_${sessionId ?? "curr"}';

    try {
      final queryParams = <String, String>{};
      if (termId != null) queryParams['term_id'] = termId.toString();
      if (sessionId != null) queryParams['session_id'] = sessionId.toString();

      final response = await _apiService.get(
        ApiConfig.reportAcademicCard(schoolId, studentId),
        queryParameters: queryParams,
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      
      // Save to cache
      await StorageHelper.saveCache(cacheKey, data);
      
      return data;
    } catch (e) {
      // Try loading from cache
      final cachedData = await StorageHelper.getCache(cacheKey);
      if (cachedData != null) {
        return cachedData as Map<String, dynamic>;
      }
      throw Exception('Error loading report card (offline): $e');
    }
  }
}
