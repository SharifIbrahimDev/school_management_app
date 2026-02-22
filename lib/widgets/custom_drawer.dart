import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service_api.dart';
import '../core/utils/app_theme.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final user = authService.currentUserModel;
    final role = user?.role ?? UserRole.parent;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context, user),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: _buildDrawerItems(context, role),
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              user?.fullName[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user?.roleDisplayName ?? 'Parent',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, UserRole role) {
    final List<Widget> items = [];

    // Common items
    items.add(_buildDrawerItem(
      context,
      icon: Icons.grid_view_rounded,
      label: 'Home',
      onTap: () => Navigator.pop(context),
    ));

    // Role-based items
    if (role == UserRole.proprietor || role == UserRole.principal || role == UserRole.bursar) {
      items.add(_buildSectionHeader('Management'));
      items.add(_buildDrawerItem(
        context,
        icon: Icons.school_rounded,
        label: 'Academic Sections',
        onTap: () => _navigateTo(context, '/sections'),
      ));
      items.add(_buildDrawerItem(
        context,
        icon: Icons.event_note_rounded,
        label: 'Academic Sessions',
        onTap: () => _navigateTo(context, '/sessions'),
      ));
    }

    if (role == UserRole.proprietor || role == UserRole.principal) {
      items.add(_buildDrawerItem(
        context,
        icon: Icons.class_rounded,
        label: 'Class Management',
        onTap: () => _navigateTo(context, '/classes'),
      ));
      items.add(_buildDrawerItem(
        context,
        icon: Icons.people_alt_rounded,
        label: 'User Management',
        onTap: () => _navigateTo(context, '/users'),
      ));
    }

    // Academics
    items.add(_buildSectionHeader('Academics'));
    if (role != UserRole.parent) {
      items.add(_buildDrawerItem(
        context,
        icon: Icons.groups_rounded,
        label: 'Students',
        onTap: () => _navigateTo(context, '/students'),
      ));
    }
    
    items.add(_buildDrawerItem(
      context,
      icon: Icons.assignment_rounded,
      label: 'Exam Results',
      onTap: () => _navigateTo(context, '/exam-results'),
    ));

    if (role == UserRole.teacher || role == UserRole.principal) {
      items.add(_buildDrawerItem(
        context,
        icon: Icons.check_circle_rounded,
        label: 'Attendance',
        onTap: () => _navigateTo(context, '/attendance'),
      ));
    }

    // Finance (Proprietor & Bursar)
    if (role == UserRole.proprietor || role == UserRole.bursar) {
      items.add(_buildSectionHeader('Finance'));
      items.add(_buildDrawerItem(
        context,
        icon: Icons.payments_rounded,
        label: 'Fee Management',
        onTap: () => _navigateTo(context, '/fees'),
      ));
      items.add(_buildDrawerItem(
        context,
        icon: Icons.analytics_rounded,
        label: 'Financial Reports',
        onTap: () => _navigateTo(context, '/reports'),
      ));
    }

    // Communication
    items.add(_buildSectionHeader('Communication'));
    items.add(_buildDrawerItem(
      context,
      icon: Icons.chat_rounded,
      label: 'Messages',
      onTap: () => _navigateTo(context, '/messages'),
    ));

    // Support & Settings
    items.add(_buildSectionHeader('More'));
    if (role == UserRole.proprietor) {
      items.add(_buildDrawerItem(
        context,
        icon: Icons.settings_suggest_rounded,
        label: 'School Settings',
        onTap: () => _navigateTo(context, '/school-settings'),
      ));
    }
    
    items.add(_buildDrawerItem(
      context,
      icon: Icons.person_2_rounded,
      label: 'My Profile',
      onTap: () => _navigateTo(context, '/profile'),
    ));

    return items;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondaryColor, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      horizontalTitleGap: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    // In actual implementation, this would navigate to the specific route
    // For now we navigate to these routes which should be defined in main.dart
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showLogoutConfirmation(context),
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 12,
          ),
          const SizedBox(height: 12),
          Text(
            'Version 1.0.2-Stable',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthServiceApi>(context, listen: false);
              await authService.logout();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close drawer
                Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
