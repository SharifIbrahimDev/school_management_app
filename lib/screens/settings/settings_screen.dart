import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/app_theme.dart';

import '../../widgets/custom_app_bar.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

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
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),
              // Appearance Section
              _buildSectionHeader('Appearance', Icons.palette),
              _buildThemeTile(settings),
              _buildLanguageTile(settings),
              
              const SizedBox(height: 24),
              
              // Notifications Section
              _buildSectionHeader('Notifications', Icons.notifications),
              _buildNotificationTile(
                'Email Notifications',
                'Receive updates via email',
                settings.emailNotifications,
                (value) => settings.setEmailNotifications(value),
              ),
              _buildNotificationTile(
                'Push Notifications',
                'Receive push notifications',
                settings.pushNotifications,
                (value) => settings.setPushNotifications(value),
              ),
              _buildNotificationTile(
                'Payment Reminders',
                'Remind about pending payments',
                settings.paymentReminders,
                (value) => settings.setPaymentReminders(value),
              ),
              
              const SizedBox(height: 24),
              
              // About Section
              _buildSectionHeader('About', Icons.info),
              _buildInfoTile(
                Icons.info_outline,
                'Version',
                _appVersion,
              ),
              _buildActionTile(
                Icons.policy_outlined,
                'Privacy Policy',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon')),
                  );
                },
              ),
              _buildActionTile(
                Icons.description_outlined,
                'Terms of Service',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of Service coming soon')),
                  );
                },
              ),
              _buildActionTile(
                Icons.support_agent_outlined,
                'Contact Support',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact: support@schoolapp.com')),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Reset button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: OutlinedButton.icon(
                  onPressed: () => _showResetDialog(settings),
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset Settings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(SettingsProvider settings) {
    return _buildSettingTile(
      icon: Icons.brightness_6_outlined,
      title: 'Theme',
      subtitle: _getThemeName(settings.themeMode),
      onTap: () => _showThemeDialog(settings),
    );
  }

  Widget _buildLanguageTile(SettingsProvider settings) {
    return _buildSettingTile(
      icon: Icons.language_outlined,
      title: 'Language',
      subtitle: _getLanguageName(settings.language),
      onTap: () => _showLanguageDialog(settings),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 16,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).disabledColor),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 16,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[700])),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 16,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 16,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: SwitchListTile(
        activeThumbColor: AppTheme.primaryColor,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[700])),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _getThemeName(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System Default';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  Future<void> _showThemeDialog(SettingsProvider settings) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: settings.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: settings.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: settings.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await settings.setThemeMode(selected);
    }
  }

  Future<void> _showLanguageDialog(SettingsProvider settings) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: settings.language,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: settings.language,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: settings.language,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await settings.setLanguage(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language will be applied in next version'),
          ),
        );
      }
    }
  }

  Future<void> _showResetDialog(SettingsProvider settings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await settings.resetToDefaults();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }
}
