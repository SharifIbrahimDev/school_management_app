import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/student_list_widget.dart';
import '../../widgets/custom_app_bar.dart';

class StudentListScreen extends StatelessWidget {
  final String schoolId;
  final String sectionId;
  final String classId;

  const StudentListScreen({
    super.key,
    required this.schoolId,
    required this.sectionId,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Students',
      ),
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
          child: AppTheme.constrainedContent(
            context: context,
            child: SingleChildScrollView(
              padding: AppTheme.responsivePadding(context),
              child: StudentListWidget(
                schoolId: schoolId,
                sectionId: sectionId,
                classId: classId,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
