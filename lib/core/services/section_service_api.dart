import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class SectionServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get sections
  Future<List<Map<String, dynamic>>> getSections({
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      
      final response = await _apiService.get(
        ApiConfig.sections(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final sections = data['data'] as List;
        return sections.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching sections: $e');
    }
  }
  
  // Get section by ID
  Future<Map<String, dynamic>?> getSection(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.section(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching section: $e');
    }
  }
  
  // Get section statistics
  Future<Map<String, dynamic>> getSectionStatistics(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.sectionStatistics(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      throw Exception('Error fetching section statistics: $e');
    }
  }
  // Create section
  Future<Map<String, dynamic>> createSection({
    required String sectionName,
    String? aboutSection,
    bool isActive = true,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.sections(schoolId),
        body: {
          'section_name': sectionName,
          if (aboutSection != null) 'about_section': aboutSection,
          'is_active': isActive,
        },
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to create section');
      }
    } catch (e) {
      throw Exception('Error creating section: $e');
    }
  }

  // Update section
  Future<Map<String, dynamic>> updateSection(
    int id, {
    String? sectionName,
    String? aboutSection,
    bool? isActive,
    List<int>? assignedPrincipalIds,
    List<int>? assignedBursarIds,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final body = <String, dynamic>{};
      if (sectionName != null) body['section_name'] = sectionName;
      if (aboutSection != null) body['about_section'] = aboutSection;
      if (isActive != null) body['is_active'] = isActive;
      if (assignedPrincipalIds != null) body['assigned_principal_ids'] = assignedPrincipalIds;
      if (assignedBursarIds != null) body['assigned_bursar_ids'] = assignedBursarIds;
      
      final response = await _apiService.put(
        ApiConfig.section(schoolId, id),
        body: body,
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update section');
      }
    } catch (e) {
      throw Exception('Error updating section: $e');
    }
  }

  // Delete section
  Future<void> deleteSection(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.section(schoolId, id),
      );
      
      if (response['success'] == true) {
        notifyListeners();
        return;
      }
      
      throw Exception(response['message'] ?? 'Failed to delete section');
    } catch (e) {
      throw Exception('Error deleting section: $e');
    }
  }
}
