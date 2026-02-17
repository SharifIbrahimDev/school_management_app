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

import 'loading_indicator.dart';
import 'dashboard_card.dart';
import 'teacher_schedule_card.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/responsive_utils.dart';
import 'responsive_widgets.dart';

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
          _errorMessage = 'Error loading data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading classes...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return const Center(child: Text('No classes assigned'));
    }

    if (_sections.isEmpty) {
      return const Center(child: Text('No sections found for your classes'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: AppTheme.constrainedContent(
        context: context,
        child: SingleChildScrollView(
          padding: AppTheme.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveRowColumn(
                rowOnMobile: false,
                rowOnTablet: true,
                rowOnDesktop: true,
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
                    Expanded(
                      flex: 1,
                      child: const TeacherScheduleCard(),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Class Overview",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Section switcher
              if (_sections.length > 1)
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
                              opacity: isSelected ? 0.3 : 0.05,
                              borderRadius: 20,
                              borderColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              hasGlow: isSelected,
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
              if (_sections.length > 1) const SizedBox(height: 24),

              // Classes for selected section in a grid
              if (selectedSection != null)
                ResponsiveGridView(
                  mobileColumns: 2,
                  tabletColumns: 3,
                  desktopColumns: 4,
                  runSpacing: 16,
                  spacing: 16,
                  childAspectRatio: 1.1,
                  children: _classes
                      .where((c) => c.sectionId == selectedSection!.id)
                      .map((c) => _buildClassCard(c))
                      .toList(),
                ),
              const SizedBox(height: 80),
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
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.7,
        borderRadius: 32,
        hasGlow: true,
      ).copyWith(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.neonBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    fontSize: 16,
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
              color: AppTheme.neonEmerald.withOpacity(0.1),
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
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(
              context: context,
              opacity: 0.6,
              borderRadius: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_2_rounded, color: AppTheme.neonBlue, size: 20),
                    ),
                    Text(
                      "$studentCount",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classItem.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Students",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
          const SizedBox(height: 16),
        ],
        Text(
          "Quick Actions",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ActionItem(
              label: "Attendance",
              icon: Icons.how_to_reg_rounded,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen())),
            ),
            // Other actions can be added here
          ],
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.1,
            borderRadius: 16,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
