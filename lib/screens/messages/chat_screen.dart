import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/message_service_api.dart';
import '../../core/models/message_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/loading_indicator.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<MessageModel> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final service = Provider.of<MessageServiceApi>(context, listen: false);
      final data = await service.getConversation(widget.otherUserId);
      if (mounted) {
        setState(() {
          _messages = data.map((m) => MessageModel.fromMap(m)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
        
        // Mark all as read
        for (var msg in _messages) {
          if (!msg.isRead && msg.recipientId != widget.otherUserId) {
            service.markAsRead(msg.id);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final body = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final service = Provider.of<MessageServiceApi>(context, listen: false);
      await service.sendMessage(
        recipientId: widget.otherUserId,
        body: body,
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final currentUserId = int.tryParse(authService.currentUserModel?.id ?? '');

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Teacher',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
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
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 64,
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet. Say hi!',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final bool isMe = msg.senderId == currentUserId;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                                decoration: AppTheme.glassDecoration(
                                  context: context,
                                  opacity: isMe ? 0.9 : 0.7,
                                  blur: 8.0,
                                  borderRadius: 20,
                                  borderColor: isMe 
                                      ? AppTheme.primaryColor.withValues(alpha: 0.3) 
                                      : Colors.white.withValues(alpha: 0.5),
                                  hasGlow: isMe,
                                ).copyWith(
                                  gradient: isMe ? AppTheme.primaryGradient : null,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.body,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm').format(msg.createdAt),
                                          style: TextStyle(
                                            color: isMe ? Colors.white.withValues(alpha: 0.7) : AppTheme.textHintColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            msg.isRead ? Icons.done_all : Icons.done,
                                            size: 14,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: AppTheme.glassDecoration(
                  context: context,
                  opacity: 0.5,
                  borderRadius: 28,
                  borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppTheme.textHintColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _isSending
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      iconSize: 22,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
