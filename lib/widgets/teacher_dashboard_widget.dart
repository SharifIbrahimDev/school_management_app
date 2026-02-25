import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/section_model.dart';
import '../core/models/class_model.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service_api.dart';
import '../core/services/class_service_api.dart';
import '../core/services/section_service_api.dart';
import '../screens/academics/attendance_screen.dart';
import '../screens/academics/teacher_homework_screen.dart';
import '../screens/academics/exams_list_screen.dart';

import 'loading_indicator.dart';
import '../core/utils/app_theme.dart';
import 'error_display_widget.dart';
import 'empty_state_widget.dart';

class TeacherDashboardWidget extends StatefulWidget {
  final String teacherId;
  final String schoolId;

  const TeacherDashboardWidget({
    super.key,
    required this.teacherId,
    required this.schoolId,
  });

  @override
  State<TeacherDashboardWidget> createState() => _TeacherDashboardWidgetState();
}

class _TeacherDashboardWidgetState extends State<TeacherDashboardWidget> {
  SectionModel? selectedSection;
  List<ClassModel> _classes = [];
  List<SectionModel> _sections = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);

      final userMap = authService.currentUser;
      final user = userMap != null ? UserModel.fromMap(userMap) : null;
      final teacherUserId = user?.id ?? widget.teacherId;

      // Get classes assigned to this teacher using server-side filtering
      final classesData = await classService.getClasses(
        teacherId: int.tryParse(teacherUserId),
      );
      _classes = classesData.map((data) => ClassModel.fromMap(data)).toList();

      if (_classes.isNotEmpty) {
        // Get unique section IDs
        final sectionIds = _classes.map((c) => int.tryParse(c.sectionId)).whereType<int>().toSet().toList();
        
        // Get sections
        final sectionsData = await sectionService.getSections(isActive: true);
        _sections = sectionsData
            .map((data) => SectionModel.fromMap(data))
            .where((s) => sectionIds.contains(int.tryParse(s.id)))
            .toList();

        if (_sections.isNotEmpty) {
          selectedSection = _sections.first;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading your dashboard...');
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        error: _errorMessage!,
        onRetry: _loadData,
      );
    }

    if (_classes.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.class_outlined,
        title: 'No Classes Assigned',
        message: 'You have not been assigned to any classes yet. Please contact your administrator.',
        onActionPressed: _loadData,
        actionButtonText: 'Refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: AppTheme.constrainedContent(
        context: context,
        child: SingleChildScrollView(
          padding: AppTheme.responsivePadding(context),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 32),
              
              _buildStatsOverview(),
              const SizedBox(height: 32),

              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(),

              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Classes",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (_classes.length > 3)
                    TextButton(
                      onPressed: () {},
                      child: const Text("View All"),
                    )
                ],
              ),
              const SizedBox(height: 16),
              
              // Simplified Class List (Show first 3)
              if (selectedSection != null)
                Column(
                  children: _classes
                      .where((c) => c.sectionId == selectedSection!.id)
                      .take(3)
                      .map((c) => _buildCompactClassCard(c))
                      .toList(),
                ),

              const SizedBox(height: 32),
              
              _buildInfoCard(
                context,
                title: "Administrative Notice",
                message: "Please ensure all second term results are uploaded by the end of the week for review.",
                icon: Icons.info_outline_rounded,
                color: AppTheme.neonPink,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final userMap = authService.currentUser;
    final user = authService.currentUserModel;
    final name = user?.fullName.split(' ').first ?? 'Teacher';

    String getNames(String key, String nameField) {
      if (userMap != null && userMap[key] is List) {
        final list = userMap[key] as List;
        if (list.isNotEmpty) {
          final names = list.map((e) {
            if (e is Map) return e[nameField] ?? e['name'] ?? e['id'].toString();
            return e.toString();
          }).where((s) => s != 'null' && s.isNotEmpty).toList();
          if (names.isNotEmpty) return names.join(', ');
        }
      }
      return '';
    }

    final sectionsDisplay = getNames('assigned_sections', 'section_name');
    final classesDisplay = getNames('assigned_classes', 'class_name');

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 32,
        hasGlow: true,
      ).copyWith(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.neonBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.neonBlue],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Great morning,",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),
                if (sectionsDisplay.isNotEmpty || classesDisplay.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (sectionsDisplay.isNotEmpty) "Section: $sectionsDisplay",
                      if (classesDisplay.isNotEmpty) "Class: $classesDisplay"
                    ].join(' • '),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonEmerald.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: AppTheme.neonEmerald, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard("Assigned Classes", _classes.length.toString(), Icons.class_rounded, AppTheme.neonBlue),
          _buildStatCard("Attendance (Avg)", "94%", Icons.trending_up_rounded, AppTheme.neonEmerald),
          _buildStatCard("Pending Tasks", "5", Icons.assignment_late_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         _buildTeacherAction(context, Icons.how_to_reg_rounded, "Attendance", AppTheme.neonBlue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()))),
         _buildTeacherAction(context, Icons.assignment_rounded, "Homework", AppTheme.neonPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherHomeworkScreen()))),
         _buildTeacherAction(context, Icons.quiz_rounded, "Exams", AppTheme.neonPink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamsListScreen()))),
         _buildTeacherAction(context, Icons.chat_bubble_rounded, "Messages", AppTheme.neonEmerald, () => {}),
      ],
    );
  }

  Widget _buildTeacherAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: AppTheme.glassDecoration(
              context: context,
              opacity: 0.1,
              borderRadius: 20,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCompactClassCard(ClassModel classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.05,
        borderRadius: 20,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_2_rounded, color: AppTheme.neonBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classItem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Section: ${selectedSection?.sectionName}", style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondaryColor),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String message, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 28,
        borderColor: color.withValues(alpha: 0.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

