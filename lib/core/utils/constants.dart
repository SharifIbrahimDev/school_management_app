class AppConstants {
  // Firestore collections
  static const String usersCollection = 'users';
  static const String schoolsCollection = 'schools';
  static const String sectionsCollection = 'sections';
  static const String academicSessionsCollection = 'academic_sessions';
  static const String termsCollection = 'terms';
  static const String transactionsCollection = 'transactions';
  static const String classesCollection = 'classes';
  static const String studentsCollection = 'students';

  // User roles
  static const String roleProprietor = 'Proprietor';
  static const String rolePrincipal = 'Principal';
  static const String roleBursar = 'Bursar';
  static const String roleTeacher = 'Teacher';
  static const String roleParent = 'Parent';

  // Transaction categories
  static const List<String> creditCategories = [
    'School Fees',
    'Registration Fees',
    'Books',
    'Other Income',
  ];
  static const List<String> debitCategories = [
    'Salary',
    'Stationary',
    'Cleaning',
    'Maintenance',
    'General Expenses',
    'Utilities',
    'Rent',
    'Other Expenses',
  ];

  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Currency
  static const String currencySymbol = '₦';
}
