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

      // API returns { success: true, data: { data: [...] } } or { success: true, data: [...] }
      List<dynamic> data = [];
      final innerData = response['data'];
      if (innerData is List) {
        data = innerData;
      } else if (innerData is Map) {
        final nestedData = innerData['data'];
        if (nestedData is List) {
          data = nestedData;
        }
      }
      return data.map((item) => NotificationModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(ApiConfig.notificationsUnreadCount);
      // Handle various response shapes
      int count = 0;
      final dynamic data = response['data'];
      if (data is Map) {
        count = int.tryParse((data['count'] ?? data['unread_count'] ?? 0).toString()) ?? 0;
      } else if (data is int) {
        count = data;
      } else if (data is String) {
        count = int.tryParse(data) ?? 0;
      }
      // Also check top-level
      if (count == 0) {
        count = int.tryParse((response['count'] ?? response['unread_count'] ?? 0).toString()) ?? 0;
      }
      _unreadCount = count;
      notifyListeners();
      return count;
    } catch (e) {
      return _unreadCount; // Return cached count on error
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
