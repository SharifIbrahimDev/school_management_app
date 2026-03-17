import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/parent_dashboard_widget.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/custom_drawer.dart';
class ParentDashboardScreen extends StatefulWidget {
  final String parentId;
  final String schoolId;

  const ParentDashboardScreen({
    super.key,
    required this.parentId,
    required this.schoolId,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Parent Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            tooltip: 'Logout',
            onPressed: () async {
              final authService = Provider.of<AuthServiceApi>(context, listen: false);
              await authService.logout();
            },
          ),
          const NotificationBadge(),
        ],
      ),
      drawer: const CustomDrawer(),
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
          child: ParentDashboardWidget(
            parentId: widget.parentId,
            schoolId: widget.schoolId,
          ),
        ),
      ),
    );
  }
}
