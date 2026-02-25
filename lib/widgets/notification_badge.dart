import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/notification_service_api.dart';
import '../screens/notifications/notifications_screen.dart';

class NotificationBadge extends StatefulWidget {
  final Color? color;
  const NotificationBadge({super.key, this.color});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  @override
  void initState() {
    super.initState();
    // Fetch unread count once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationServiceApi>(context, listen: false).getUnreadCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationServiceApi>(
      builder: (context, service, _) {
        final count = service.unreadCount;
        return IconButton(
          tooltip: 'Notifications',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                count > 0 ? Icons.notifications_rounded : Icons.notifications_outlined,
                color: widget.color ?? Colors.white,
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ).then((_) {
              // Refresh count after returning from notifications screen
              if (context.mounted) {
                Provider.of<NotificationServiceApi>(context, listen: false).getUnreadCount();
              }
            });
          },
        );
      },
    );
  }
}
