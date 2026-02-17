import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(initSettings);
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  static Future<void> showNotification(dynamic message) async {
    // Note: This method signature was changed to accept dynamic since RemoteMessage is gone.
    // If this is called with RemoteMessage, it needs to be updated.
    // However, since we removed Firebase, we won't be receiving RemoteMessage objects anyway.
    // This method is likely not called anymore in its current form or needs adaptation.
    // For now, we'll implement a generic show method.
    try {
      final androidDetails = AndroidNotificationDetails(
        'channel_id',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      final iosDetails = const DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        0, // ID
        'Notification', // Title
        message.toString(), // Body
        details,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static Future<void> showLocalNotification({required String title, required String body}) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'channel_id',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      final iosDetails = const DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static Future<void> sendAttendanceNotification({
    required String parentId,
    required String studentName,
    required String status,
  }) async {
    // In a real app, this would call the backend to trigger FCM to the parent.
    // For V1 demo, we just log it.
    debugPrint('Simulating notification to parent $parentId: $studentName is $status');
  }
}

