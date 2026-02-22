import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/section_model.dart';
import '../core/models/class_model.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service_api.dart';
import '../core/services/class_service_api.dart';
import '../core/services/section_service_api.dart';
import '../core/services/student_service_api.dart';
import '../screens/academics/attendance_screen.dart';
import '../screens/academics/teacher_homework_screen.dart';
import '../screens/academics/lesson_plan_screen.dart';
import '../screens/academics/exams_list_screen.dart';
import '../screens/academics/bulk_result_upload_screen.dart';

import 'loading_indicator.dart';
import 'teacher_schedule_card.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/responsive_utils.dart';
import 'responsive_widgets.dart';
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
              ResponsiveRowColumn(
                rowOnMobile: false,
                rowOnTablet: true,
                rowOnDesktop: true,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(),
                        const SizedBox(height: 32),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                  if (!context.isMobile) const SizedBox(width: 32),
                  if (!context.isMobile)
                    const Expanded(
                      flex: 1,
                      child: TeacherScheduleCard(),
                    ),
                ],
              ),
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
                  if (_sections.length > 1)
                     Text(
                       "${_sections.length} Sections Found",
                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
                         color: AppTheme.textSecondaryColor,
                       ),
                     ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Section switcher
              if (_sections.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: _sections.map((section) {
                      final isSelected = selectedSection?.id == section.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => setState(() => selectedSection = section),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: isSelected ? 0.4 : 0.05,
                              borderRadius: 20,
                              borderColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              hasGlow: isSelected,
                            ).copyWith(
                              gradient: isSelected ? LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                                  AppTheme.neonBlue.withValues(alpha: 0.1),
                                ],
                              ) : null,
                            ),
                            child: Text(
                              section.sectionName,
                              style: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Classes for selected section in a grid
              if (selectedSection != null)
                ResponsiveGridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 3,
                  runSpacing: 20,
                  spacing: 20,
                  childAspectRatio: 1.6,
                  children: _classes
                      .where((c) => c.sectionId == selectedSection!.id)
                      .map((c) => _buildClassCard(c))
                      .toList(),
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
    final user = authService.currentUserModel;
    final name = user?.fullName.split(' ').first ?? 'Teacher';

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

  Widget _buildClassCard(ClassModel classItem) {
    final studentService = Provider.of<StudentServiceApi>(context, listen: false);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: studentService.getStudents(
        sectionId: int.tryParse(selectedSection!.id),
        classId: int.tryParse(classItem.id),
      ),
      builder: (context, snapshot) {
        final studentCount = snapshot.data?.length ?? 0;

        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen())),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(
              context: context,
              opacity: 0.1,
              borderRadius: 28,
              borderColor: AppTheme.neonBlue.withValues(alpha: 0.2),
            ).copyWith(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonBlue.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.neonBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.groups_2_rounded, color: AppTheme.neonBlue, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.neonEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$studentCount Pupils",
                        style: const TextStyle(
                          color: AppTheme.neonEmerald,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  classItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.room_rounded, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      "Section ${selectedSection?.sectionName}",
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (context.isMobile) ...[
          const TeacherScheduleCard(),
          const SizedBox(height: 24),
        ],
        Text(
          "Quick Actions",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _ActionItem(
                label: "Attendance",
                icon: Icons.how_to_reg_rounded,
                color: AppTheme.neonBlue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen())),
              ),
              _ActionItem(
                label: "Assignments",
                icon: Icons.assignment_rounded,
                color: AppTheme.neonPurple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherHomeworkScreen())),
              ),
              _ActionItem(
                label: "Lessons",
                icon: Icons.menu_book_rounded,
                color: AppTheme.neonEmerald,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LessonPlanScreen())),
              ),
              _ActionItem(
                label: "Exams",
                icon: Icons.quiz_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamsListScreen())),
              ),
              _ActionItem(
                label: "Results",
                icon: Icons.analytics_rounded,
                color: AppTheme.neonPink,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkResultUploadScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 90,
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.05,
            borderRadius: 24,
            borderColor: color.withValues(alpha: 0.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

