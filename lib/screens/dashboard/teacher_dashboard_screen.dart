import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/teacher_dashboard_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/custom_drawer.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String teacherId;
  final String schoolId;
  final AuthServiceApi authService;

  const TeacherDashboardScreen({
    super.key,
    required this.teacherId,
    required this.schoolId,
    required this.authService,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Teacher Dashboard',
        actions: [
          const NotificationBadge(),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.accentColor.withValues(alpha: 0.2),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: TeacherDashboardWidget(
            teacherId: widget.teacherId,
            schoolId: widget.schoolId,
          ),
        ),
      ),
    );
  }
}
