import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class SchoolServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get list of supported banks from Paystack
  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await _apiService.get(ApiConfig.schoolsBanks);
      
      if (response['success'] == true) {
        final List<dynamic> banks = response['data'] ?? [];
        return banks.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching banks: $e');
    }
  }

  /// Get school settings/details
  Future<Map<String, dynamic>> getSchool() async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.get(ApiConfig.school(schoolId));

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch school details');
      }
    } catch (e) {
      throw Exception('Error fetching school details: $e');
    }
  }

  /// Update school details
  Future<Map<String, dynamic>> updateSchool({
    String? name,
    String? shortCode,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.put(
        '${ApiConfig.schools}/$schoolId',
        body: {
          if (name != null) 'name': name,
          if (shortCode != null) 'short_code': shortCode,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
      );

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update school');
      }
    } catch (e) {
      throw Exception('Error updating school: $e');
    }
  }

  /// Setup Paystack subaccount for the school
  Future<Map<String, dynamic>> setupSubaccount({
    required String settlementBank,
    required String accountNumber,
    double? platformFeePercentage,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');

      final response = await _apiService.post(
        ApiConfig.setupSubaccount(schoolId),
        body: {
          'settlement_bank': settlementBank,
          'account_number': accountNumber,
          if (platformFeePercentage != null) 'percentage_charge': platformFeePercentage,
        },
      );

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to setup subaccount');
      }
    } catch (e) {
      throw Exception('Error setting up subaccount: $e');
    }
  }
}
