import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/message_model.dart';
import '../../core/services/message_service_api.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_display_widget.dart';
import 'compose_message_screen.dart';
import 'message_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<MessageModel> _inboxMessages = [];
  List<MessageModel> _sentMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Provider.of<MessageServiceApi>(context, listen: false);
      final inbox = await service.getInbox();
      final sent = await service.getSent();
      
      if (mounted) {
        setState(() {
          _inboxMessages = inbox;
          _sentMessages = sent;
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

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Messages',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Inbox'),
            Tab(text: 'Sent'),
          ],
        ),
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
                      onRetry: _loadMessages,
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMessageList(_inboxMessages, isInbox: true),
                        _buildMessageList(_sentMessages, isInbox: false),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComposeMessageScreen()),
          );
          if (result == true) {
            _refreshMessages();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> messages, {required bool isInbox}) {
    if (messages.isEmpty) {
      return EmptyStateWidget(
        icon: isInbox ? Icons.inbox : Icons.send,
        title: isInbox ? 'No Messages' : 'No Sent Messages',
        message: isInbox
            ? 'Your inbox is empty'
            : 'You haven\'t sent any messages yet',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildMessageTile(message, isInbox);
        },
      ),
    );
  }

  Widget _buildMessageTile(MessageModel message, bool isInbox) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd');
    final timeFormat = DateFormat('hh:mm a');
    final isToday = DateTime.now().difference(message.createdAt).inDays == 0;
    
    final otherPartyName = isInbox ? message.senderName : message.recipientName;

    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isInbox && !message.isRead ? 0.7 : 0.4,
        borderRadius: 16,
        hasGlow: isInbox && !message.isRead,
        borderColor: isInbox && !message.isRead
            ? AppTheme.primaryColor.withValues(alpha: 0.3)
            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            otherPartyName?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherPartyName ?? 'Unknown',
                style: TextStyle(
                  fontWeight: isInbox && !message.isRead ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              isToday 
                  ? timeFormat.format(message.createdAt)
                  : dateFormat.format(message.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.subject,
              style: TextStyle(
                 fontWeight: isInbox && !message.isRead ? FontWeight.w600 : FontWeight.normal,
                 color: theme.textTheme.bodyMedium?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              message.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageDetailScreen(
                message: message,
                isInbox: isInbox,
              ),
            ),
          );
          _refreshMessages();
        },
      ),
    );
  }
}
