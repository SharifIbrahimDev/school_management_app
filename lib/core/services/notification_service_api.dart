import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get all notifications for the current user
  Future<List<NotificationModel>> getNotifications({bool? isRead}) async {
    try {
      final queryParams = isRead != null ? {'is_read': isRead ? '1' : '0'} : null;
      
      final response = await _apiService.get(
        ApiConfig.notifications,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response as List? ?? (response['data'] ?? []);
      return data.map((item) => NotificationModel.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(ApiConfig.notificationsUnreadCount);
      return (response['count'] ?? 0) as int;
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _apiService.post(ApiConfig.notificationRead(notificationId));
      notifyListeners();
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _apiService.post(ApiConfig.notificationsMarkAllRead);
      notifyListeners();
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _apiService.delete(ApiConfig.notification(notificationId));
      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  /// Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
      await _apiService.delete(ApiConfig.notificationsReadAll);
      notifyListeners();
    } catch (e) {
      throw Exception('Error deleting read notifications: $e');
    }
  }

  /// Create notification (admin only)
  Future<NotificationModel> createNotification({
    required int userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.notifications,
        body: {
          'user_id': userId,
          'type': type,
          'title': title,
          'message': message,
          if (data != null) 'data': data,
        },
      );

      return NotificationModel.fromMap(response);
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  /// Broadcast notification to multiple users (admin only)
  Future<void> broadcastNotification({
    required List<int> userIds,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _apiService.post(
        ApiConfig.notificationsBroadcast,
        body: {
          'user_ids': userIds,
          'type': type,
          'title': title,
          'message': message,
          if (data != null) 'data': data,
        },
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Error broadcasting notification: $e');
    }
  }
}
