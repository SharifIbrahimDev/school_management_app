import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/message_service_api.dart';
import '../../core/models/message_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/loading_indicator.dart';
import 'chat_screen.dart';
import 'contact_picker_screen.dart';

class ParentChatListScreen extends StatefulWidget {
  const ParentChatListScreen({super.key});

  @override
  State<ParentChatListScreen> createState() => _ParentChatListScreenState();
}

class _ParentChatListScreenState extends State<ParentChatListScreen> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final service = Provider.of<MessageServiceApi>(context, listen: false);
      final data = await service.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final currentUserId = int.tryParse(authService.currentUserModel?.id.toString() ?? '');

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Conversations',
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
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('No conversations yet', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to contact picker
                            },
                            child: const Text('New Message'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final msgData = _conversations[index];
                        final msg = MessageModel.fromMap(msgData);
                        
                        // Determine the other user
                        final bool isSender = msg.senderId == currentUserId;
                        final otherId = isSender ? msg.recipientId : msg.senderId;
                        final otherName = isSender ? msg.recipientName : msg.senderName;


                        return Container(
                          decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Text(otherName?[0] ?? '?', style: const TextStyle(color: AppTheme.primaryColor)),
                            ),
                            title: Text(otherName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              msg.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: !msg.isRead && !isSender ? FontWeight.bold : FontWeight.normal,
                                color: !msg.isRead && !isSender ? Colors.black : Colors.grey[600],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(msg.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                if (!msg.isRead && !isSender)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: otherId,
                                    otherUserName: otherName ?? 'Unknown',
                                  ),
                                ),
                              ).then((_) => _loadConversations());
                            },
                          ),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
          );

          if (!mounted) return;

          if (result != null && result is Map<String, dynamic>) {
            // result is user map
            final userId = result['id']; 
            
            final otherUserId = int.tryParse(userId.toString());
            final otherUserName = result['full_name'] ?? result['name'] ?? 'Unknown';
            
            if (otherUserId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: otherUserId,
                    otherUserName: otherUserName,
                  ),
                ),
              ).then((_) => _loadConversations());
            }
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}
