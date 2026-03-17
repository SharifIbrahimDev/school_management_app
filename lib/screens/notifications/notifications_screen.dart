import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/notification_service_api.dart';
import '../../core/services/transaction_service_api.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_snackbar.dart';
import '../transactions/transaction_detail_screen.dart';
import '../../core/models/transaction_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _notifications = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Provider.of<NotificationServiceApi>(context, listen: false);
      final notifications = await service.getNotifications();
      
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
      service.getUnreadCount(); // Update badge count
      
      // Update local state without full reload for smoothness
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            final n = _notifications[index];
            _notifications[index] = NotificationModel(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              message: n.message,
              data: n.data,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
              updatedAt: n.updatedAt,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    _markAsRead(notification);

    // Deep linking based on notification data
    if (notification.type == 'payment_verification' && notification.data != null) {
      final txId = notification.data?['transaction_id'];
      if (txId != null) {
        try {
          final txService = Provider.of<TransactionServiceApi>(context, listen: false);
          final txData = await txService.getTransaction(int.parse(txId.toString()));
          if (mounted && txData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(
                  transaction: TransactionModel.fromMap(txData),
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error navigating to transaction: $e');
        }
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      final service = Provider.of<NotificationServiceApi>(context, listen: false);
      await service.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final service = Provider.of<NotificationServiceApi>(context, listen: false);
      await service.markAllAsRead();
      _loadNotifications();
      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'All notifications marked as read');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  List<NotificationModel> _getFilteredNotifications(int tabIndex) {
    switch (tabIndex) {
      case 1: // Unread
        return _notifications.where((n) => !n.isRead).toList();
      case 2: // Academic
        return _notifications.where((n) => ['exam', 'result', 'homework'].contains(n.type)).toList();
      case 3: // Financial
        return _notifications.where((n) => ['payment_verification', 'fee_due', 'payment_reminder'].contains(n.type)).toList();
      default: // All
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Updates Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Academic'),
            Tab(text: 'Financial'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.mainGradientDecoration(context),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorDisplayWidget(error: _error!, onRetry: _loadNotifications)
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(4, (index) => _buildNotificationList(_getFilteredNotifications(index))),
                  ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.notifications_none_rounded,
        title: 'No Updates Found',
        message: 'Everything looks clear for now! Check back later for news.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification, index)
              .animate()
              .fade(duration: 300.ms, delay: (index * 50).ms)
              .slideX(begin: 0.1, duration: 300.ms, curve: Curves.easeOutQuad);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    final dateFormat = DateFormat('MMM dd • hh:mm a');
    final color = _getNotificationColor(notification.type);
    
    return Dismissible(
      key: Key('notif_${notification.id}_${notification.updatedAt.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: notification.isRead ? 0.3 : 0.8,
          borderRadius: 24,
          hasGlow: !notification.isRead,
          borderColor: notification.isRead 
              ? Colors.transparent 
              : color.withValues(alpha: 0.3),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w900,
                                fontSize: 16,
                                color: notification.isRead ? Colors.grey[700] : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.neonBlue,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppTheme.neonBlue, blurRadius: 4)],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: notification.isRead ? Colors.grey[600] : Colors.black87,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11, 
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'payment_verification':
      case 'payment_reminder':
        return Icons.account_balance_wallet_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'fee_due':
        return Icons.receipt_long_rounded;
      case 'exam':
      case 'result':
        return Icons.assignment_turned_in_rounded;
      case 'homework':
        return Icons.menu_book_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'payment_verification':
        return AppTheme.neonEmerald;
      case 'payment_reminder':
        return AppTheme.neonAmber;
      case 'announcement':
        return AppTheme.neonPurple;
      case 'fee_due':
        return Colors.redAccent;
      case 'exam':
      case 'result':
        return AppTheme.neonBlue;
      case 'homework':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }
}
