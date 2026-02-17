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
    // Initial fetch of unread count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationServiceApi>(context, listen: false).getUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Consumer<NotificationServiceApi>(
        builder: (context, service, child) {
          return FutureBuilder<int>(
            future: service.getUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                   Icon(Icons.notifications_outlined, color: widget.color),
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
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
    );
  }
}
