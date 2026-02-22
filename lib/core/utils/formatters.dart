import 'package:intl/intl.dart';
import '../models/user_model.dart';
import 'constants.dart';

class Formatters {
  // Format currency (e.g., ₦1,000.00)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format amount only (e.g., 1,000.00)
  static String formatAmountOnly(double amount) {
    final formatter = NumberFormat.decimalPattern('en_NG');
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;
    return formatter.format(amount);
  }

  // Format date (e.g., 14/07/2025)
  static String formatDate(DateTime date) {
    final formatter = DateFormat(AppConstants.dateFormat);
    return formatter.format(date);
  }

  // Format date and time (e.g., 14/07/2025 14:15)
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat(AppConstants.dateTimeFormat);
    return formatter.format(dateTime);
  }

  // Format class name (e.g., JSS1A → JSS 1A)
  static String formatClassName(String className) {
    return className
        .replaceAllMapped(RegExp(r'([A-Z0-9]+)([A-Z])'),
            (match) => '${match[1]} ${match[2]}')
        .trim();
  }
}

class IdGenerator {
  // Centralized role-to-code mapping (private)
  static const Map<UserRole, String> _roleToCode = {
    UserRole.proprietor: 'PRO',
    UserRole.principal: 'PRC',
    UserRole.bursar: 'BRS',
    UserRole.teacher: 'TCH',
    UserRole.parent: 'PRT',
  };

  /// Returns the role code for a given UserRole
  static String getRoleCode(UserRole role) {
    return _roleToCode[role] ?? 'UNK'; // Fallback to 'UNK' for unknown roles
  }

  /// Generates both a Firestore-safe ID and a pretty ID for display
  static Map<String, String> generateId(String schoolCode, UserRole role, int sequence) {
    final year = DateTime.now().year;
    final roleCode = _roleToCode[role] ?? 'UNK';
    final prettyId = '$schoolCode/$roleCode/$year/${sequence.toString().padLeft(3, '0')}';
    final safeId = prettyId.replaceAll('/', '_');
    return {'prettyId': prettyId, 'safeId': safeId};
  }

  static Map<String, String> generateParentId(String schoolCode, int sequence) =>
      generateId(schoolCode, UserRole.parent, sequence);

  static Map<String, String> generateTeacherId(String schoolCode, int sequence) =>
      generateId(schoolCode, UserRole.teacher, sequence);

  static Map<String, String> generatePrincipalId(String schoolCode, int sequence) =>
      generateId(schoolCode, UserRole.principal, sequence);

  static Map<String, String> generateBursarId(String schoolCode, int sequence) =>
      generateId(schoolCode, UserRole.bursar, sequence);

  static Map<String, String> generateProprietorId(String schoolCode, int sequence) =>
      generateId(schoolCode, UserRole.proprietor, sequence);

  /// Generates both a Firestore-safe ID and a pretty ID for display
  static Map<String, String> generateStudentId(String schoolCode, int sequence) {
    final year = DateTime.now().year;

    // Human-readable ID
    final prettyId = '$schoolCode/STD/$year/${sequence.toString().padLeft(3, '0')}';

    // Firestore-safe ID (no slashes)
    final safeId = prettyId.replaceAll('/', '_');

    return {
      'safeId': safeId,     // Use this in Firestore `.doc()`
      'prettyId': prettyId, // Store this in the document & display in UI
    };
  }

}
