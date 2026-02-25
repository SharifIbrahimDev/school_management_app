import 'package:shared_preferences/shared_preferences.dart';

/// Manages app preferences and persistent storage
class PreferencesManager {
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyEmailNotifications = 'email_notifications';
  static const String _keyPushNotifications = 'push_notifications';
  static const String _keyPaymentReminders = 'payment_reminders';

  static SharedPreferences? _prefs;

  /// Initialize preferences (call in main)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get instance {
    if (_prefs == null) {
      throw Exception('PreferencesManager not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Onboarding
  static bool get isOnboardingComplete =>
      instance.getBool(_keyOnboardingComplete) ?? false;
  
  static Future<void> setOnboardingComplete(bool value) =>
      instance.setBool(_keyOnboardingComplete, value);

  // Theme
  static String get themeMode =>
      instance.getString(_keyThemeMode) ?? 'light';
  
  static Future<void> setThemeMode(String mode) =>
      instance.setString(_keyThemeMode, mode);

  // Language
  static String get language =>
      instance.getString(_keyLanguage) ?? 'en';
  
  static Future<void> setLanguage(String lang) =>
      instance.setString(_keyLanguage, lang);

  // Notifications
  static bool get emailNotifications =>
      instance.getBool(_keyEmailNotifications) ?? true;
  
  static Future<void> setEmailNotifications(bool value) =>
      instance.setBool(_keyEmailNotifications, value);

  static bool get pushNotifications =>
      instance.getBool(_keyPushNotifications) ?? true;
  
  static Future<void> setPushNotifications(bool value) =>
      instance.setBool(_keyPushNotifications, value);

  static bool get paymentReminders =>
      instance.getBool(_keyPaymentReminders) ?? true;
  
  static Future<void> setPaymentReminders(bool value) =>
      instance.setBool(_keyPaymentReminders, value);

  /// Clear all preferences (useful for logout/reset)
  static Future<void> clearAll() => instance.clear();
}
