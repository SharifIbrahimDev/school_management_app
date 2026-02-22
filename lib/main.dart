import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service_api.dart';
import 'core/services/api_service.dart';
import 'core/services/section_service_api.dart';
import 'core/services/session_service_api.dart';
import 'core/services/term_service_api.dart';
import 'core/services/class_service_api.dart';
import 'core/services/transaction_service_api.dart';
import 'core/services/student_service_api.dart';
import 'core/services/fee_service_api.dart';
import 'core/services/attendance_service_api.dart';
import 'core/services/report_service_api.dart';
import 'core/services/user_service_api.dart';
import 'core/services/subject_service_api.dart';
import 'core/services/exam_service_api.dart';
import 'core/services/homework_service_api.dart';
import 'core/services/lesson_plan_service_api.dart';
import 'core/services/syllabus_service_api.dart';
import 'core/services/timetable_service_api.dart';
import 'core/services/payment_service_api.dart';
import 'core/services/message_service_api.dart';
import 'core/services/notification_service_api.dart';
import 'core/services/school_service_api.dart';
import 'core/utils/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/utils/preferences_manager.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings/school_settings_screen.dart';
import 'screens/sections/add_section_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();          // ← Initialize Hive before any box is opened
  await PreferencesManager.init();   // Initialize shared preferences
  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthServiceApi()),
        ChangeNotifierProvider(create: (_) => SectionServiceApi()),
        ChangeNotifierProvider(create: (_) => SessionServiceApi()),
        ChangeNotifierProvider(create: (_) => TermServiceApi()),
        ChangeNotifierProvider(create: (_) => ClassServiceApi()),
        ChangeNotifierProvider(create: (_) => TransactionServiceApi()),
        ChangeNotifierProvider(create: (_) => StudentServiceApi()),
        ChangeNotifierProvider(create: (_) => FeeServiceApi()),
        ChangeNotifierProvider(create: (_) => AttendanceServiceApi()),
        ChangeNotifierProvider(create: (_) => ExamServiceApi()),
        ChangeNotifierProvider(create: (_) => ReportServiceApi()),
        ChangeNotifierProvider(create: (_) => UserServiceApi()),
        ChangeNotifierProvider(create: (_) => SubjectServiceApi()),
        ChangeNotifierProvider(create: (_) => HomeworkServiceApi()),
        ChangeNotifierProvider(create: (_) => LessonPlanServiceApi()),
        ChangeNotifierProvider(create: (_) => SyllabusServiceApi()),
        ChangeNotifierProvider(create: (_) => TimetableServiceApi()),
        ChangeNotifierProvider(create: (_) => PaymentServiceApi()),
        ChangeNotifierProvider(create: (_) => MessageServiceApi()),
        ChangeNotifierProvider(create: (_) => NotificationServiceApi()),
        ChangeNotifierProvider(create: (_) => SchoolServiceApi()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'School Management App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode == 'light' 
                ? ThemeMode.light 
                : settings.themeMode == 'dark' 
                    ? ThemeMode.dark 
                    : ThemeMode.system,
            home: const SplashScreen(),
            routes: {
              '/auth': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/school-settings': (context) => const SchoolSettingsScreen(),
              '/add-section': (context) => const AddSectionScreen(),
            },
          );
        },
      ),
    );
  }
}

