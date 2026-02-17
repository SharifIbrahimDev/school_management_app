import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/student_model.dart';
import '../../core/services/class_service_api.dart';
import '../student/student_detail_screen.dart';

class ParentStudentListWidget extends StatelessWidget {
  final StudentModel student;

  const ParentStudentListWidget({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final classService = Provider.of<ClassServiceApi>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>?>(
      future: classService.getClass(int.parse(student.classId)),
      builder: (context, snapshot) {
        final classData = snapshot.data;
        final className = classData != null ? (classData['class_name'] ?? 'Unknown') : "Unassigned";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Class: $className"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailScreen(student: student),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
