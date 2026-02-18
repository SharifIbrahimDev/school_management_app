import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/class_model.dart';
import '../core/models/section_model.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service_api.dart';
import '../core/services/class_service_api.dart';
import '../core/services/user_service_api.dart';
import '../core/utils/formatters.dart';
import 'app_snackbar.dart';
import '../screens/class/class_detail_screen.dart';
import '../screens/class/edit_class_screen.dart';

class ClassListWidget extends StatelessWidget {
  final List<SectionModel> assignedSections;
  final String? selectedSectionId;
  final String? errorMessage;
  final ClassServiceApi classService;
  final AuthServiceApi authService;
  final ValueChanged<String?> onSectionChanged;

  const ClassListWidget({
    super.key,
    required this.assignedSections,
    required this.selectedSectionId,
    required this.errorMessage,
    required this.classService,
    required this.authService,
    required this.onSectionChanged,
  });

  Future<void> _deleteClass(BuildContext context, ClassModel classItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete "${Formatters.formatClassName(classItem.name)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await classService.deleteClass(int.tryParse(classItem.id) ?? 0);
        if (context.mounted) {
          AppSnackbar.showSuccess(context, message: 'Class deleted successfully');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(context, message: 'Error deleting class: $e');
        }
      }
    }
  }

  Widget _buildClassTile(BuildContext context, ClassModel classItem) {
    final currentUserMap = authService.currentUser;
    final isPrincipal = currentUserMap != null && 
        UserModel.fromMap(currentUserMap).role == UserRole.principal;

    return FutureBuilder<Map<String, dynamic>?>(
      future: classItem.assignedTeacherUserId != null
          ? Provider.of<UserServiceApi>(context, listen: false)
              .getUser(int.tryParse(classItem.assignedTeacherUserId!) ?? 0)
          : Future.value(null),
      builder: (context, teacherSnapshot) {
        final teacherName = teacherSnapshot.data?['full_name'] ?? 'Not assigned';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.class_, color: Colors.white),
            ),
            title: Text(
              Formatters.formatClassName(classItem.name),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Teacher: $teacherName\nStudents: ${classItem.studentIds.length}'),
            trailing: isPrincipal
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditClassScreen(
                                classModel: classItem,
                                schoolId: classItem.schoolId,
                                sectionId: classItem.sectionId,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteClass(context, classItem),
                      ),
                    ],
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassDetailScreen(
                    classModel: classItem,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    if (assignedSections.isEmpty) {
      return const Center(child: Text('No sections assigned.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            initialValue: selectedSectionId,
            decoration: const InputDecoration(
              labelText: 'Select Section',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
            ),
            items: assignedSections.map((section) {
              return DropdownMenuItem(
                value: section.id,
                child: Text(section.sectionName),
              );
            }).toList(),
            onChanged: onSectionChanged,
          ),
        ),
        Expanded(
          child: selectedSectionId == null
              ? const Center(child: Text('Please select a section to view classes.'))
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: classService.getClasses(
                    sectionId: int.tryParse(selectedSectionId!),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final classesData = snapshot.data ?? [];
                    final classes = classesData.map((data) => ClassModel.fromMap(data)).toList();

                    if (classes.isEmpty) {
                      return const Center(child: Text('No classes found in this section.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        return _buildClassTile(context, classes[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
