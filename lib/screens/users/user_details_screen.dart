import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/user_model.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import 'edit_user_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/confirmation_dialog.dart';


class UserDetailsScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  Future<void> _deleteUser(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete User Account',
      content: 'Are you sure you want to delete ${widget.user.fullName}? This will permanently remove their access to the system and all associated data.',
      confirmText: 'Delete Account',
      confirmColor: Colors.red,
      icon: Icons.person_remove_rounded,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      await userService.deleteUser(int.tryParse(widget.user.id) ?? 0);
      
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, message: 'User deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(user.role);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditUserScreen(user: user)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        height: double.infinity,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.6,
                    borderColor: roleColor.withValues(alpha: 0.2),
                    hasGlow: true,
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'user_avatar_${user.id}',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: roleColor.withValues(alpha: 0.1),
                          child: Icon(
                            _getRoleIcon(user.role),
                            size: 40,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                user.roleDisplayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: roleColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.6,
                    borderRadius: 20,
                    borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTACT INFORMATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        context,
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: user.email,
                      ),
                      const Divider(height: 32, color: Colors.white10),
                      _buildInfoRow(
                        context,
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: user.phoneNumber,
                      ),
                      const Divider(height: 32, color: Colors.white10),
                      _buildInfoRow(
                        context,
                        icon: Icons.location_on_outlined,
                        label: 'Physical Address',
                        value: user.address,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // System Info Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.6,
                    borderRadius: 20,
                    borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SYSTEM STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        context,
                        icon: Icons.circle,
                        label: 'Account Status',
                        value: user.isActive ? 'Active' : 'Deactivated',
                        valueColor: user.isActive ? AppTheme.neonEmerald : Colors.redAccent,
                      ),
                      const Divider(height: 32, color: Colors.white10),
                      _buildInfoRow(
                        context,
                        icon: Icons.history,
                        label: 'Member Since',
                        value: DateFormat('MMMM dd, yyyy').format(user.createdAt),
                      ),
                      if (user.assignedSections.isNotEmpty) ...[
                        const Divider(height: 32, color: Colors.white10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assigned Sections',
                              style: TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.assignedSections.map((section) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    section,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Danger Zone
                Text(
                  'DANGER ZONE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Delete User Account',
                  icon: Icons.delete_forever,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  onPressed: () => _deleteUser(context),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.principal:
        return AppTheme.neonPurple;
      case UserRole.bursar:
        return AppTheme.neonBlue;
      case UserRole.teacher:
        return AppTheme.neonTeal;
      case UserRole.parent:
        return Colors.orangeAccent;
      case UserRole.proprietor:
        return AppTheme.neonEmerald;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.proprietor:
        return Icons.business;
      case UserRole.principal:
        return Icons.school;
      case UserRole.bursar:
        return Icons.account_balance;
      case UserRole.teacher:
        return Icons.person_rounded;
      case UserRole.parent:
        return Icons.family_restroom;
    }
  }
}
