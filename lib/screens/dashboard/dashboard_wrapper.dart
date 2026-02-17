import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import 'main_app.dart';

class DashboardWrapper extends StatelessWidget {
  const DashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthServiceApi>(
      builder: (context, authService, child) {
        final userMap = authService.currentUser;

        if (userMap == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = UserModel.fromMap(userMap);

        // Fallback to assignedSections.first if sectionId is null
        final sectionId = user.sectionId ?? (user.assignedSections.isNotEmpty ? user.assignedSections.first : null);

        // Block access if no sectionId at all for roles that require it
        if (sectionId == null && user.role == UserRole.principal) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No section assigned. Please contact the administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return MainApp(
          userId: user.id,
          schoolId: user.schoolId ?? '',
          role: user.role,
          sectionId: sectionId ?? '',
          authService: authService,
        );
      },
    );
  }
}
