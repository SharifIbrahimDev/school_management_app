import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/class_model.dart';
import '../../core/models/section_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import 'class_detail_screen.dart';

class TeacherClassListWidget extends StatelessWidget {
  final String schoolId;
  final String teacherId;
  final String sectionId;
  final ClassServiceApi classService;
  final AuthServiceApi authService;

  const TeacherClassListWidget({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.sectionId,
    required this.classService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: classService.getClasses(
        sectionId: int.tryParse(sectionId),
      ), 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(context: context, opacity: 0.6),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading classes: ${snapshot.error}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }

        final classesData = snapshot.data!;
        final classes = classesData
            .map((data) => ClassModel.fromMap(data))
            .where((c) => c.assignedTeacherUserId == teacherId)
            .toList();

        if (classes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(context: context, opacity: 0.6),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.class_outlined, size: 48, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'No classes assigned',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classItem = classes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, hasGlow: true),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.class_rounded, color: theme.colorScheme.primary),
                ),
                title: Text(
                  Formatters.formatClassName(classItem.name),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Students: ${classItem.studentIds.length}\n'
                  'Created: ${Formatters.formatDate(classItem.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassDetailScreen(
                        classModel: classItem,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
