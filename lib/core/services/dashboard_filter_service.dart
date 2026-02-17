import 'package:shared_preferences/shared_preferences.dart';

class DashboardFilterService {
  static const String _prefix = 'dashboard_filter_';

  // Save filters for a specific user role
  static Future<void> saveFilters(String role, {
    String? sectionId,
    String? sessionId,
    String? termId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (sectionId != null) await prefs.setString('${_prefix}${role}_section', sectionId);
    if (sessionId != null) await prefs.setString('${_prefix}${role}_session', sessionId);
    if (termId != null) await prefs.setString('${_prefix}${role}_term', termId);
  }

  // Get saved filters for a specific user role
  static Future<Map<String, String?>> getFilters(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'sectionId': prefs.getString('${_prefix}${role}_section'),
      'sessionId': prefs.getString('${_prefix}${role}_session'),
      'termId': prefs.getString('${_prefix}${role}_term'),
    };
  }

  // Clear filters
  static Future<void> clearFilters(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefix}${role}_section');
    await prefs.remove('${_prefix}${role}_session');
    await prefs.remove('${_prefix}${role}_term');
  }
}
