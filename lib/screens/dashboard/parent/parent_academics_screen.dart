import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/exam_service_api.dart';
import '../../../core/services/student_service_api.dart';
import '../../../core/utils/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_display_widget.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../widgets/notification_badge.dart';

class ParentAcademicsScreen extends StatefulWidget {
  final String parentId;
  final String schoolId;

  const ParentAcademicsScreen({
    super.key,
    required this.parentId,
    required this.schoolId,
  });

  @override
  State<ParentAcademicsScreen> createState() => _ParentAcademicsScreenState();
}

class _ParentAcademicsScreenState extends State<ParentAcademicsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<StudentModel> _students = [];
  Map<String, List<Map<String, dynamic>>> _studentResults = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final examService = Provider.of<ExamServiceApi>(context, listen: false);

      final studentsData = await studentService.getStudents(
        parentId: int.tryParse(widget.parentId),
      );
      
      _students = studentsData.map((data) => StudentModel.fromMap(data)).toList();

      for (var student in _students) {
        final sId = int.tryParse(student.id);
        if (sId != null) {
          final results = await examService.getStudentRecentResults(sId);
          _studentResults[student.id] = results;
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Academic Progress',
        actions: [
          NotificationBadge(),
        ],
      ),
      body: Container(
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? ErrorDisplayWidget(error: _errorMessage!, onRetry: _loadData)
                  : _students.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.school_outlined,
                          title: 'No Children Found',
                          message: 'No student records are linked to your account.',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final results = _studentResults[student.id] ?? [];
                              return _buildAcademicCard(student, results);
                            },
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildAcademicCard(StudentModel student, List<Map<String, dynamic>> results) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 28,
        borderColor: AppTheme.neonPink.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.neonPink.withValues(alpha: 0.1),
                child: Text(
                  student.fullName[0].toUpperCase(),
                  style: const TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                student.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (results.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No recent exam results found', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...results.map((res) {
              final subject = res['exam']?['subject']?['subject_name'] ?? 'Unknown Subject';
              final score = (res['score'] as num?)?.toDouble() ?? 0.0;
              final grade = res['grade'] ?? '-';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            res['exam']?['exam_name'] ?? 'Exam',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.neonPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$score / $grade",
                        style: const TextStyle(
                          color: AppTheme.neonPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('View Full Report Card'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.neonPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 2,
      itemBuilder: (context, index) => const DashboardCardSkeletonLoader(),
    );
  }
}
