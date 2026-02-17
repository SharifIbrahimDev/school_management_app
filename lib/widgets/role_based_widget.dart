import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service_api.dart';

class RoleBasedWidget extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget unauthorizedChild;

  const RoleBasedWidget({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.unauthorizedChild = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthServiceApi>(
      builder: (context, authService, _) {
        final user = authService.currentUserModel;
        
        // If no user is logged in, show unauthorized content
        if (user == null) {
          return unauthorizedChild;
        }

        // Check if user has one of the allowed roles
        if (allowedRoles.contains(user.role)) {
          return child;
        }

        // If not authorized, show unauthorized content
        return unauthorizedChild;
      },
    );
  }
}
