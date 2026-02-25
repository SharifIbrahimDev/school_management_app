import 'package:flutter/foundation.dart';
import '../utils/preferences_manager.dart';

/// Provider for managing app settings
class SettingsProvider extends ChangeNotifier {
  // Theme mode: 'light', 'dark', 'system'
  String _themeMode = PreferencesManager.themeMode;
  
  // Language
  String _language = PreferencesManager.language;
  
  // Notifications
  bool _emailNotifications = PreferencesManager.emailNotifications;
  bool _pushNotifications = PreferencesManager.pushNotifications;
  bool _paymentReminders = PreferencesManager.paymentReminders;

  // Getters
  String get themeMode => _themeMode;
  String get language => _language;
  bool get emailNotifications => _emailNotifications;
  bool get pushNotifications => _pushNotifications;
  bool get paymentReminders => _paymentReminders;

  // Theme mode setter
  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await PreferencesManager.setThemeMode(mode);
    notifyListeners();
  }

  // Language setter
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await PreferencesManager.setLanguage(lang);
    notifyListeners();
  }

  // Notification setters
  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    await PreferencesManager.setEmailNotifications(value);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    await PreferencesManager.setPushNotifications(value);
    notifyListeners();
  }

  Future<void> setPaymentReminders(bool value) async {
    _paymentReminders = value;
    await PreferencesManager.setPaymentReminders(value);
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await setThemeMode('light');
    await setLanguage('en');
    await setEmailNotifications(true);
    await setPushNotifications(true);
    await setPaymentReminders(true);
  }
}
