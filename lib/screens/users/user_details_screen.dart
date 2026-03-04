import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/user_model.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
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
      title: 'Decommission Administrator',
      content: 'Are you sure you want to permanently remove access for ${widget.user.fullName}? All associated session logs will be archived.',
      confirmText: 'ARCHIVE & DELETE',
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
        AppSnackbar.showSuccess(context, message: 'Identity decommissioned.');
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.friendlyError(context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(user.role);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Executive Profile',
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildProfileHeader(user, roleColor),
                const SizedBox(height: 24),
                _buildQuickStats(user, roleColor),
                const SizedBox(height: 24),
                _buildModernSection(
                  title: 'COMMUNICATION CHANNELS',
                  icon: Icons.alternate_email_rounded,
                  children: [
                    _buildInfoRow('Electronic Mail', user.email),
                    _buildInfoRow('Mobile Registry', user.phoneNumber),
                    _buildInfoRow('Geospatial Tag', user.address),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernSection(
                  title: 'SYSTEM AUTHORIZATION',
                  icon: Icons.security_rounded,
                  children: [
                    _buildInfoRow('Account Node', user.isActive ? 'ACTIVE' : 'SUSPENDED', color: user.isActive ? AppTheme.neonEmerald : Colors.redAccent),
                    _buildInfoRow('Initialization', DateFormat('MMMM dd, yyyy').format(user.createdAt)),
                    if (user.assignedSections.isNotEmpty) _buildSectionChips(user),
                  ],
                ),
                const SizedBox(height: 32),
                _buildModernActions(user),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.8, borderRadius: 32, hasGlow: true, borderColor: roleColor.withValues(alpha: 0.3)),
      child: Column(
        children: [
          Hero(
            tag: 'user_avatar_${user.id}',
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [roleColor, roleColor.withValues(alpha: 0.5)]),
                boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(child: Icon(_getRoleIcon(user.role), size: 48, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user.fullName.toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: roleColor.withValues(alpha: 0.2))),
            child: Text(
              user.roleDisplayName.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(UserModel user, Color roleColor) {
    return Row(
      children: [
        _buildStatChip(Icons.verified_user_rounded, 'STATUS', user.isActive ? 'ACTIVE' : 'OFFLINE', user.isActive ? AppTheme.neonEmerald : Colors.grey),
        const SizedBox(width: 12),
        _buildStatChip(Icons.layers_rounded, 'ACCESS', '${user.assignedSections.length} SECTS', AppTheme.neonBlue),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.textSecondaryColor)),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.5, borderRadius: 24),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSectionChips(UserModel user) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: user.assignedSections.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1))),
          child: Text(s.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        )).toList(),
      ),
    );
  }

  Widget _buildModernActions(UserModel user) {
    return Column(
      children: [
        _buildActionButton(Icons.auto_fix_high_rounded, 'MODIFY CREDENTIALS', AppTheme.primaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => EditUserScreen(user: user)));
        }),
        const SizedBox(height: 12),
        _buildActionButton(Icons.lock_reset_rounded, 'RESET PASSWORD', AppTheme.accentColor, () {}),
        const SizedBox(height: 12),
        _buildActionButton(Icons.no_accounts_rounded, 'DECOMMISSION NODE', Colors.redAccent, () => _deleteUser(context), outlined: true),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap, {bool outlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: outlined 
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.principal: return AppTheme.neonPurple;
      case UserRole.bursar: return AppTheme.neonBlue;
      case UserRole.teacher: return AppTheme.neonTeal;
      case UserRole.parent: return Colors.orangeAccent;
      case UserRole.proprietor: return AppTheme.neonEmerald;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.proprietor: return Icons.business_center_rounded;
      case UserRole.principal: return Icons.account_balance_rounded;
      case UserRole.bursar: return Icons.payments_rounded;
      case UserRole.teacher: return Icons.menu_book_rounded;
      case UserRole.parent: return Icons.family_restroom_rounded;
    }
  }
}
