import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/class_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';

class AssignTeacherScreen extends StatefulWidget {
  final ClassModel classModel;

  const AssignTeacherScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<AssignTeacherScreen> createState() => _AssignTeacherScreenState();
}

class _AssignTeacherScreenState extends State<AssignTeacherScreen> {
  bool _isLoading = true;
  List<UserModel> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      final users = await userService.getUsers();
      _teachers = users
          .map((u) => UserModel.fromMap(u))
          .where((u) => u.role == UserRole.teacher)
          .toList();
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error loading teachers: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAssignment(UserModel teacher) async {
    setState(() => _isLoading = true);
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final isCurrentlyAssigned = widget.classModel.assignedTeacherUserId == teacher.id;
      
      final classId = int.tryParse(widget.classModel.id) ?? 0;
      final teacherId = int.tryParse(teacher.id) ?? 0;

      if (isCurrentlyAssigned) {
        await classService.updateClass(classId, unassignTeacher: true);
        if (mounted) AppSnackbar.showSuccess(context, message: 'Teacher removed from class');
      } else {
        await classService.updateClass(classId, formTeacherId: teacherId);
        if (mounted) AppSnackbar.showSuccess(context, message: 'Teacher assigned to class');
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error updating assignment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Assign Teacher',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _teachers.isEmpty
                  ? const Center(child: Text('No teachers found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final isAssigned = widget.classModel.assignedTeacherUserId == teacher.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.6,
                            borderRadius: 16,
                            hasGlow: isAssigned,
                            borderColor: isAssigned 
                                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAssigned 
                                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: isAssigned ? AppTheme.primaryColor : Colors.grey,
                              ),
                            ),
                            title: Text(
                              teacher.fullName,
                              style: TextStyle(
                                fontWeight: isAssigned ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(teacher.email),
                            trailing: isAssigned
                                ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                                : const Icon(Icons.add_circle_outline_rounded, color: Colors.grey),
                            onTap: () => _handleAssignment(teacher),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
