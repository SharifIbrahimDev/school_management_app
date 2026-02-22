import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/class_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import 'class_detail_screen.dart';

class AssignedClassListWidget extends StatefulWidget {
  final String schoolId;
  final String sectionId;

  const AssignedClassListWidget({
    super.key,
    required this.schoolId,
    required this.sectionId,
  });

  @override
  State<AssignedClassListWidget> createState() => _AssignedClassListWidgetState();
}

class _AssignedClassListWidgetState extends State<AssignedClassListWidget> {
  late Future<List<Map<String, dynamic>>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    final classService = Provider.of<ClassServiceApi>(context, listen: false);
    setState(() {
      _classesFuture = classService.getClasses(
        sectionId: int.tryParse(widget.sectionId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserServiceApi>(context, listen: false);
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _classesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error)));
        }

        final classesData = snapshot.data ?? [];
        final classes = classesData.map((data) => ClassModel.fromMap(data)).toList();

        if (classes.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('No assigned classes found in this section.', style: theme.textTheme.bodyMedium),
          ));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = classes[index];
            final teacherId = c.assignedTeacherUserId;

            return FutureBuilder<Map<String, dynamic>?>(
              future: (teacherId != null && teacherId.isNotEmpty)
                  ? userService.getUser(int.parse(teacherId))
                  : Future.value(null),
              builder: (context, teacherSnap) {
                final loadingTeacher = teacherSnap.connectionState == ConnectionState.waiting;
                final teacherData = teacherSnap.data;
                final teacherName = loadingTeacher
                    ? 'Loading...'
                    : (teacherData != null ? (teacherData['full_name'] ?? 'Unknown') : 'Not Assigned');

                return Container(
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.6,
                    borderRadius: 16,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.class_rounded, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      c.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Teacher: $teacherName', style: theme.textTheme.bodyMedium),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassDetailScreen(
                            classModel: c,
                          ),
                        ),
                      ).then((_) => _loadClasses());
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
