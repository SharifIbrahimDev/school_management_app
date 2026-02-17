import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import 'update_password_screen.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final userMap = authService.currentUser;
    if (userMap != null) {
      setState(() {
        _currentUser = UserModel.fromMap(userMap);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Profile'),
        body: const Center(child: Text('Please log in to view your profile')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
      ),
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
          child: AppTheme.constrainedContent(
            context: context,
            child: SingleChildScrollView(
              padding: AppTheme.responsivePadding(context),
              child: ResponsiveRowColumn(
                rowOnMobile: false,
                rowOnTablet: true,
                rowOnDesktop: true,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Sidebar
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildHeader(context, _currentUser!),
                        if (!context.isMobile) ...[
                          const SizedBox(height: 24),
                          _buildActionButtons(context, _currentUser!),
                        ],
                      ],
                    ),
                  ),
                  
                  if (!context.isMobile) const SizedBox(width: 32),
  
                  // Profile Details
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildProfileCard(context, _currentUser!),
                        if (context.isMobile) ...[
                          const SizedBox(height: 16),
                          _buildActionButtons(context, _currentUser!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 32,
        hasGlow: true,
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_rounded,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.roleDisplayName,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 16,
        hasGlow: true,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  settings.themeMode == 'dark' 
                    ? Icons.dark_mode_rounded 
                    : Icons.light_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  final newMode = settings.themeMode == 'dark' ? 'light' : 'dark';
                  settings.setThemeMode(newMode);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user.registrationId != null) ...[
            _buildInfoRow(Icons.badge_outlined, 'Registration ID', user.registrationId!),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(Icons.email_outlined, 'Email', user.email),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_outlined, 'Phone', user.phoneNumber),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'Address', user.address),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.list_alt_rounded,
            'Sections',
            user.assignedSections.isEmpty ? 'None' : '${user.assignedSections.length} assigned',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Joined',
            DateFormat('MMM dd, yyyy').format(user.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, UserModel user) {
    return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Profile',
                  backgroundColor: AppTheme.primaryColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user),
                      ),
                    ).then((_) => _loadUser());
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Change Password',
                  backgroundColor: Colors.orange,
                  onPressed: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpdatePasswordScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Sign Out',
            onPressed: () => _showLogoutConfirmationDialog(context),
            backgroundColor: Colors.red,
          ),
        ],
      );
  }

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change functionality will be implemented with the API.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
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
                Navigator.pop(context); // Close the dialog
                Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
