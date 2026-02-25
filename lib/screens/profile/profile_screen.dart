import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/custom_button.dart';
import 'edit_profile_screen.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import 'update_password_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser(refresh: true);
  }

  Future<void> _loadUser({bool refresh = false}) async {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    
    if (refresh) {
      setState(() => _isLoading = true);
      try {
        await authService.refreshUser();
      } catch (e) {
        debugPrint('Error refreshing user profile: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthServiceApi>(
      builder: (context, authService, child) {
        final user = authService.currentUserModel;

        if (user == null && _isLoading) {
          return const Scaffold(
            appBar: CustomAppBar(title: 'Profile'),
            body: Center(child: LoadingIndicator(size: 50)),
          );
        }

        if (user == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Profile'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load profile data'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _loadUser(refresh: true),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: const CustomAppBar(
            title: 'Profile',
          ),
          body: RefreshIndicator(
            onRefresh: () => _loadUser(refresh: true),
            child: Container(
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
                child: AppTheme.constrainedContent(
                  context: context,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppTheme.responsivePadding(context),
                    child: Column(
                      children: [
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        ResponsiveRowColumn(
                          rowOnMobile: false,
                          rowOnTablet: true,
                          rowOnDesktop: true,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header Sidebar
                            if (!context.isMobile)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildHeader(context, user),
                                    if (!context.isMobile) ...[
                                      const SizedBox(height: 24),
                                      _buildActionButtons(context, user),
                                    ],
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: [
                                  _buildHeader(context, user),
                                  if (!context.isMobile) ...[
                                    const SizedBox(height: 24),
                                    _buildActionButtons(context, user),
                                  ],
                                ],
                              ),

                            if (!context.isMobile) const SizedBox(width: 32),

                            // Profile Details
                            if (!context.isMobile)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildProfileCard(context, user),
                                    if (context.isMobile) ...[
                                      const SizedBox(height: 16),
                                      _buildActionButtons(context, user),
                                    ],
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: [
                                  _buildProfileCard(context, user),
                                  if (context.isMobile) ...[
                                    const SizedBox(height: 16),
                                    _buildActionButtons(context, user),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
              child: Icon(
                _getRoleIcon(user.role),
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
    final userMap = Provider.of<AuthServiceApi>(context, listen: false).currentUser;
    
    String getNames(String key, String fallback, String nameField) {
      if (userMap != null && userMap[key] is List) {
        final list = userMap[key] as List;
        if (list.isNotEmpty) {
          final names = list.map((e) {
            if (e is Map) return e[nameField] ?? e['name'] ?? e['id'].toString();
            return e.toString();
          }).where((s) => s != 'null' && s.isNotEmpty).toList();
          if (names.isNotEmpty) return names.join(', ');
        }
      }
      return fallback;
    }
    
    final sectionsDisplay = getNames('assigned_sections', user.assignedSections.isEmpty ? 'None' : '${user.assignedSections.length} assigned', 'section_name');
    final classesDisplay = getNames('assigned_classes', user.assignedClasses.isEmpty ? 'None' : '${user.assignedClasses.length} assigned', 'class_name');

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
          if (user.role != UserRole.parent) ...[
            _buildInfoRow(
              Icons.list_alt_rounded,
              'Sections',
              sectionsDisplay,
            ),
            const SizedBox(height: 12),
          ],
          if (user.role == UserRole.teacher || user.role == UserRole.principal) ...[
            _buildInfoRow(
              Icons.class_outlined,
              'Classes',
              classesDisplay,
            ),
            const SizedBox(height: 12),
          ],
          if (user.role == UserRole.parent && user.assignedStudents.isNotEmpty) ...[
            _buildInfoRow(
              Icons.family_restroom_rounded,
              'Children Linked',
              '${user.assignedStudents.length} Students',
            ),
            const SizedBox(height: 12),
          ],
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
                  isLoading: _isLoading,
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
                  isLoading: _isLoading,
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
            isLoading: _isLoading,
            onPressed: () => _showLogoutConfirmationDialog(context),
            backgroundColor: Colors.red,
          ),
        ],
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
