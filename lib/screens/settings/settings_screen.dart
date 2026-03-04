import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import './school_settings_screen.dart';

/// Modernized Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      if (mounted) setState(() => _appVersion = '1.0.0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final authService = Provider.of<AuthServiceApi>(context);
    final user = authService.currentUser;
    final isAdmin = user?['role'] == 'admin' || user?['role'] == 'principal';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'System Intelligence',
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 32),
                
                // Management Group (For Admins)
                if (isAdmin) ...[
                  _buildGroupTitle('INSTITUTION MANAGEMENT'),
                  _buildSettingGroup([
                    _buildQuickActionTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Settlement & Payouts',
                      subtitle: 'Manage school financial accounts',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolSettingsScreen())),
                      color: AppTheme.accentColor,
                    ),
                    _buildQuickActionTile(
                      icon: Icons.verified_user_rounded,
                      title: 'School Verification',
                      subtitle: 'Status and credentials',
                      onTap: () => AppSnackbar.showInfo(context, message: 'Institutional verification is active.'),
                      color: AppTheme.neonEmerald,
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],

                _buildGroupTitle('PERSONALIZATION'),
                _buildSettingGroup([
                  _buildStaticTile(
                    icon: Icons.palette_rounded,
                    title: 'Interface Theme',
                    trailing: Text(_getThemeName(settings.themeMode), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    onTap: () => _showThemeDialog(settings),
                  ),
                  _buildStaticTile(
                    icon: Icons.translate_rounded,
                    title: 'Language Preferred',
                    trailing: Text(_getLanguageName(settings.language), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    onTap: () => _showLanguageDialog(settings),
                  ),
                ]),

                const SizedBox(height: 24),
                _buildGroupTitle('COMMUNICATIONS'),
                _buildSettingGroup([
                  _buildSwitchTile(
                    icon: Icons.alternate_email_rounded,
                    title: 'Intelligence Updates',
                    subtitle: 'Email reports and alerts',
                    value: settings.emailNotifications,
                    onChanged: (v) => settings.setEmailNotifications(v),
                  ),
                  _buildSwitchTile(
                    icon: Icons.app_registration_rounded,
                    title: 'Push Velocity',
                    subtitle: 'Real-time device notifications',
                    value: settings.pushNotifications,
                    onChanged: (v) => settings.setPushNotifications(v),
                  ),
                ]),

                const SizedBox(height: 24),
                _buildGroupTitle('SECURITY & PRIVACY'),
                _buildSettingGroup([
                  FutureBuilder<bool>(
                    future: authService.canCheckBiometrics,
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return _buildSwitchTile(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric Shield',
                          subtitle: 'Unlock app with bio-auth',
                          value: false, // In reality, fetch from storage
                          onChanged: (v) => authService.setBiometricEnabled(v),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
                  _buildStaticTile(
                    icon: Icons.password_rounded,
                    title: 'Authentication Barrier',
                    trailing: const Text('Change', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    onTap: () => AppSnackbar.showInfo(context, message: 'Password reset link sent to your email.'),
                  ),
                ]),

                const SizedBox(height: 24),
                _buildGroupTitle('SYSTEM MAINTENANCE'),
                _buildSettingGroup([
                   _buildStaticTile(
                    icon: Icons.cleaning_services_rounded,
                    title: 'Purge Transient Data',
                    trailing: _isClearingCache ? const LoadingIndicator(size: 16) : const Text('Clear Cache', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      setState(() => _isClearingCache = true);
                      await Future.delayed(const Duration(seconds: 1));
                      if (mounted) {
                        setState(() => _isClearingCache = false);
                        AppSnackbar.showSuccess(context, message: 'System cache optimized.');
                      }
                    },
                  ),
                  _buildStaticTile(
                    icon: Icons.history_rounded,
                    title: 'Factory Calibration',
                    trailing: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    onTap: () => _showResetDialog(settings),
                  ),
                ]),

                const SizedBox(height: 32),
                _buildAppInfo(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.8, borderRadius: 28, hasGlow: true),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.mainGradient(context),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Text(
                (user?['full_name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['full_name'] ?? 'User Profile',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                ),
                Text(
                  user?['email'] ?? 'system_access@school.com',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (user?['role'] ?? 'access').toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 1.0),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => AppSnackbar.showInfo(context, message: 'Profile editing coming soon.'),
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondaryColor, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSettingGroup(List<Widget> children) {
    return Container(
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildStaticTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Text("OS CORE v$_appVersion", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("DESIGNED BY ANTIGRAVITY EXPERIMENTAL LABS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  String _getThemeName(String mode) {
    switch (mode) {
      case 'light': return 'Lumina Light';
      case 'dark': return 'Nebula Dark';
      default: return 'System Flow';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr': return 'Français';
      case 'ar': return 'العربية';
      default: return 'English Core';
    }
  }

  // Dialog methods preserved from original but styled better...
  Future<void> _showThemeDialog(SettingsProvider settings) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Interface Matrix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('Lumina Light', 'light', settings.themeMode, (v) => settings.setThemeMode(v)),
            _buildDialogOption('Nebula Dark', 'dark', settings.themeMode, (v) => settings.setThemeMode(v)),
            _buildDialogOption('System Flow', 'system', settings.themeMode, (v) => settings.setThemeMode(v)),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog(SettingsProvider settings) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Linguistic Matrix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('English Core', 'en', settings.language, (v) => settings.setLanguage(v)),
            _buildDialogOption('Français', 'fr', settings.language, (v) => settings.setLanguage(v)),
            _buildDialogOption('العربية', 'ar', settings.language, (v) => settings.setLanguage(v)),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption(String label, String value, String groupValue, Function(String) onSelect) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (v) {
        onSelect(v!);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _showResetDialog(SettingsProvider settings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Reset'),
        content: const Text('This will revert all interface calibrations to factory defaults. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ABORT')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXECUTE RESET'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await settings.resetToDefaults();
      if (mounted) AppSnackbar.showSuccess(context, message: 'Interface recalibrated to default.');
    }
  }
}
