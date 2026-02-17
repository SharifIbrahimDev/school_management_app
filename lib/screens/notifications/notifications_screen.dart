import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/notification_service_api.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _notifications = [];
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Provider.of<NotificationServiceApi>(context, listen: false);
      final notifications = await service.getNotifications(
        isRead: _showUnreadOnly ? false : null,
      );
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final service = Provider.of<NotificationServiceApi>(context, listen: false);
      await service.markAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final service = Provider.of<NotificationServiceApi>(context, listen: false);
      await service.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      final service = Provider.of<NotificationServiceApi>(context, listen: false);
      await service.deleteNotification(notification.id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
            onPressed: () {
              setState(() => _showUnreadOnly = !_showUnreadOnly);
              _loadNotifications();
            },
          ),
        ],
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ErrorDisplayWidget(
                      error: _error!,
                      onRetry: _loadNotifications,
                    )
                  : _notifications.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.notifications_none,
                          title: _showUnreadOnly ? 'No Unread Notifications' : 'No Notifications',
                          message: _showUnreadOnly
                              ? 'You\'re all caught up!'
                              : 'You don\'t have any notifications yet',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return _buildNotificationTile(notification, theme);
                            },
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification, ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: notification.isRead ? 0.4 : 0.7,
          borderRadius: 16,
          hasGlow: !notification.isRead,
          borderColor: notification.isRead 
              ? Theme.of(context).dividerColor.withValues(alpha: 0.1)
              : AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.1),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: TextStyle(color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(notification.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
              ),
            ],
          ),
          onTap: () => _markAsRead(notification),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'payment_reminder':
        return Icons.payment;
      case 'announcement':
        return Icons.campaign;
      case 'fee_due':
        return Icons.attach_money;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'payment_reminder':
        return Colors.orange;
      case 'announcement':
        return Colors.blue;
      case 'fee_due':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
