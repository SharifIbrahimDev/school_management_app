import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/message_model.dart';
import '../../core/services/message_service_api.dart';
import '../../widgets/app_snackbar.dart';
import 'compose_message_screen.dart';

class MessageDetailScreen extends StatelessWidget {
  final MessageModel message;
  final bool isInbox;

  const MessageDetailScreen({
    super.key,
    required this.message,
    required this.isInbox,
  });

  @override
  Widget build(BuildContext context) {
    // If it's an unread inbox message, mark as read on view
    if (isInbox && !message.isRead) {
      // In a real app one might want to do this only once or use the future
      Provider.of<MessageServiceApi>(context, listen: false).getMessage(message.id);
    }

    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, MMM dd, yyyy • hh:mm a');
    
    final otherPartyName = isInbox ? message.senderName : message.recipientName;
    final otherPartyRole = isInbox ? message.senderRole : message.recipientRole;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Message',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () => _confirmDelete(context),
          ),
          if (isInbox)
            IconButton(
              icon: const Icon(Icons.reply, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComposeMessageScreen(
                      initialRecipient: UserSelectModel(
                        id: message.senderId,
                        name: message.senderName ?? 'Unknown',
                        role: message.senderRole ?? '',
                        email: '', // Email not always available in list view
                      ),
                      initialSubject: 'Re: ${message.subject}',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.6,
                    borderRadius: 16,
                    borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          otherPartyName?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherPartyName ?? 'Unknown',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              isInbox ? 'From: $otherPartyRole' : 'To: $otherPartyRole',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dateFormat.format(message.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Subject
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    message.subject,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Body
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.4,
                    borderRadius: 16,
                    borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    message.body,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await Provider.of<MessageServiceApi>(context, listen: false)
                    .deleteMessage(message.id);
                if (context.mounted) {
                  Navigator.pop(context); // Go back to list
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.friendlyError(context, error: e);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
