import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL - Update this with your server URL
  static const String baseUrl = 'https://school-api.daynapp.com/api';
  
  // Development/Production URLs
  static const String devUrl = 'https://school-api.daynapp.com/api';
  static const String prodUrl = 'https://school-api.daynapp.com/api';
  
  // Get current base URL based on environment
  static String get currentBaseUrl {
    if (kReleaseMode) {
      return prodUrl;
    }
    return devUrl;
  }
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String updatePassword = '/auth/update-password';
  static const String onboardSchool = '/auth/onboard-school';
  static const String updateProfile = '/auth/update-profile';
  
  // Schools
  static const String schools = '/schools';
  static const String schoolsBanks = '/schools/banks';
  static const String schoolsResolveBank = '/schools/resolve-bank';
  static String school(int id) => '/schools/$id';
  static String schoolStatistics(int id) => '/schools/$id/statistics';
  static String setupSubaccount(int id) => '/schools/$id/setup-subaccount';
  
  // Sections
  static String sections(int schoolId) => '/schools/$schoolId/sections';
  static String section(int schoolId, int id) => '/schools/$schoolId/sections/$id';
  static String sectionStatistics(int schoolId, int id) => '/schools/$schoolId/sections/$id/statistics';
  
  // Users
  static String users(int schoolId) => '/schools/$schoolId/users';
  static String user(int schoolId, int id) => '/schools/$schoolId/users/$id';
  
  // Academic Sessions
  static String sessions(int schoolId) => '/schools/$schoolId/sessions';
  static String session(int schoolId, int id) => '/schools/$schoolId/sessions/$id';
  
  // Terms
  static String terms(int schoolId) => '/schools/$schoolId/terms';
  static String term(int schoolId, int id) => '/schools/$schoolId/terms/$id';
  
  // Classes
  static String classes(int schoolId) => '/schools/$schoolId/classes';
  static String classItem(int schoolId, int id) => '/schools/$schoolId/classes/$id';
  static String classStatistics(int schoolId, int id) => '/schools/$schoolId/classes/$id/statistics';
  
  // Students
  static String students(int schoolId) => '/schools/$schoolId/students';
  static String student(int schoolId, int id) => '/schools/$schoolId/students/$id';
  static String studentTransactions(int schoolId, int id) => '/schools/$schoolId/students/$id/transactions';
  static String studentPaymentSummary(int schoolId, int id) => '/schools/$schoolId/students/$id/payment-summary';
  // Attendance
  static String attendance(int schoolId) => '/schools/$schoolId/attendance';
  static String studentAttendance(int schoolId, int studentId) => '/schools/$schoolId/students/$studentId/attendance';
  
  // Fees
  static String fees(int schoolId) => '/schools/$schoolId/fees';
  static String fee(int schoolId, int id) => '/schools/$schoolId/fees/$id';
  static String feesSummary(int schoolId) => '/schools/$schoolId/fees-summary';
  
  // Exams & Results
  static String exams(int schoolId) => '/schools/$schoolId/exams';
  static String examResults(int schoolId, int examId) => '/schools/$schoolId/exams/$examId/results';
  
  // Subjects
  static String subjects(int schoolId) => '/schools/$schoolId/subjects';
  static String subject(int schoolId, int id) => '/schools/$schoolId/subjects/$id';
  
  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';
  static String notification(int id) => '/notifications/$id';
  static const String notificationsReadAll = '/notifications/read/all';
  static const String notificationsBroadcast = '/notifications/broadcast';
  
  // Messages
  static const String messageInbox = '/messages/inbox';
  static const String messageSent = '/messages/sent';
  static const String messagesUnreadCount = '/messages/unread-count';
  static const String messageUsers = '/messages/users';
  static const String messages = '/messages';
  static String message(int id) => '/messages/$id';
  
  // Payments
  static const String payments = '/payments';
  static const String paymentsInitialize = '/payments/initialize';
  static const String paymentsVerify = '/payments/verify';
  
  // Homeworks
  static const String homeworks = '/homeworks';
  
  // Bulk Import
  static const String importUsers = '/import/users';
  static const String importStudentsBulk = '/import/students';
  static String studentsImport(int schoolId) => '/schools/$schoolId/students/import';
  
  // Reports
  static String reportFinancialSummary(dynamic schoolId) => '/schools/$schoolId/reports/financial-summary';
  static String reportPaymentMethods(dynamic schoolId) => '/schools/$schoolId/reports/payment-methods';
  static String reportFeeCollection(dynamic schoolId) => '/schools/$schoolId/reports/fee-collection';
  static String reportDebtors(dynamic schoolId) => '/schools/$schoolId/reports/debtors';
  static String reportAcademicCard(dynamic schoolId, int studentId) => '/schools/$schoolId/reports/academic-report-card/$studentId';

  // Transactions
  static String transactions(int schoolId) => '/schools/$schoolId/transactions';
  static String transaction(int schoolId, int id) => '/schools/$schoolId/transactions/$id';
  static String transactionsDashboardStats(int schoolId) => '/schools/$schoolId/transactions-dashboard-stats';
  static String transactionsReport(int schoolId) => '/schools/$schoolId/transactions-report';
  static String transactionsMonthlySummary(int schoolId) => '/schools/$schoolId/transactions-monthly-summary';
  
  // Timetables
  static String timetables(dynamic schoolId) => '/schools/$schoolId/timetables';
  


  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}
