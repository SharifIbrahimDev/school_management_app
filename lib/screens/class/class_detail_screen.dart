import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/class_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/detail_item.dart';
import '../../widgets/student_list_widget.dart';
import '../student/add_student_screen.dart';
import 'assign_teacher_screen.dart';
import 'edit_class_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/services/student_service_api.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  UserModel? _currentUser;
  String _teacherName = 'Loading...';
  int? _actualStudentCount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final userService = Provider.of<UserServiceApi>(context, listen: false);
    final studentService = Provider.of<StudentServiceApi>(context, listen: false);
    
    final userMap = authService.currentUser;
    if (userMap != null) {
      _currentUser = UserModel.fromMap(userMap);
    }
    
    try {
      final students = await studentService.getStudents(classId: int.tryParse(widget.classModel.id));
      if (mounted) {
        setState(() {
          _actualStudentCount = students.length;
        });
      }
    } catch (_) {
      // ignore silently if it fails
    }

    if (widget.classModel.assignedTeacherUserId != null && widget.classModel.assignedTeacherUserId!.isNotEmpty) {
      try {
        final teacherIdInt = int.tryParse(widget.classModel.assignedTeacherUserId!) ?? 0;
        if (teacherIdInt != 0) {
          final teacherData = await userService.getUser(teacherIdInt);
          if (mounted && teacherData != null) {
            setState(() {
              _teacherName = UserModel.fromMap(teacherData).fullName;
            });
          } else {
            if (mounted) setState(() => _teacherName = 'Not Assigned');
          }
        } else {
          if (mounted) setState(() => _teacherName = 'Not Assigned');
        }
      } catch (e) {
        if (mounted) setState(() => _teacherName = 'Unknown');
      }
    } else {
      if (mounted) setState(() => _teacherName = 'Not Assigned');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrincipal = _currentUser?.role == UserRole.principal || _currentUser?.role == UserRole.proprietor;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.classModel.name,
        actions: [
          if (isPrincipal)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit Class',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditClassScreen(
                      classModel: widget.classModel,
                      schoolId: _currentUser?.schoolId ?? '',
                      sectionId: widget.classModel.sectionId,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isPrincipal
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddStudentScreen(
                      arguments: {
                        'schoolId': _currentUser?.schoolId ?? '',
                        'sectionId': widget.classModel.sectionId,
                        'classId': widget.classModel.id,
                      },
                    ),
                  ),
                ).then((_) => _loadData());
              },
              backgroundColor: theme.colorScheme.primary,
              tooltip: 'Add Student',
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
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
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.2),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.8,
                    borderRadius: 24,
                    hasGlow: true,
                    borderColor: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    children: [
                      DetailItem(
                        icon: Icons.class_,
                        title: 'Class Name',
                        value: widget.classModel.name,
                      ),
                      const SizedBox(height: 12),
                      DetailItem(
                        icon: Icons.people,
                        title: 'Students / Capacity',
                        value: '${_actualStudentCount != null ? '$_actualStudentCount' : 'Loading...'} / ${widget.classModel.capacity?.toString() ?? 'No Limit'}',
                      ),
                      const SizedBox(height: 12),
                      DetailItem(
                        icon: Icons.person,
                        title: 'Assigned Teacher',
                        value: _teacherName,
                      ),
                      const SizedBox(height: 12),
                      DetailItem(
                        icon: Icons.calendar_today,
                        title: 'Created',
                        value: Formatters.formatDate(widget.classModel.createdAt),
                      ),
                      const SizedBox(height: 24),
                      if (isPrincipal)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              widget.classModel.assignedTeacherUserId != null && widget.classModel.assignedTeacherUserId!.isNotEmpty ? Icons.person_remove : Icons.person_add,
                              color: Colors.white,
                            ),
                            label: Text(
                              widget.classModel.assignedTeacherUserId != null && widget.classModel.assignedTeacherUserId!.isNotEmpty ? 'Change/Remove Teacher' : 'Assign Teacher',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssignTeacherScreen(
                                    classModel: widget.classModel,
                                  ),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Student List Section
                Text(
                  'Students',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                StudentListWidget(
                  schoolId: _currentUser?.schoolId ?? '',
                  sectionId: widget.classModel.sectionId,
                  classId: widget.classModel.id,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
