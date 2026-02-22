import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/message_model.dart';
import '../../core/services/message_service_api.dart';

class ComposeMessageScreen extends StatefulWidget {
  final UserSelectModel? initialRecipient;
  final String? initialSubject;

  const ComposeMessageScreen({
    super.key,
    this.initialRecipient,
    this.initialSubject,
  });

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  UserSelectModel? _selectedRecipient;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipient != null) {
      _selectedRecipient = widget.initialRecipient;
    }
    if (widget.initialSubject != null) {
      _subjectController.text = widget.initialSubject!;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }



  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipient')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = Provider.of<MessageServiceApi>(context, listen: false);
      await service.sendMessage(
        recipientId: _selectedRecipient!.id,
        subject: _subjectController.text,
        body: _bodyController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRecipientSearch() {
    showDialog(
      context: context,
      builder: (context) => _RecipientSearchDialog(
        onSelect: (user) {
          setState(() {
            _selectedRecipient = user;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Compose Message',
        actions: [
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _isLoading ? null : _sendMessage,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassDecoration(
                      context: context,
                      opacity: 0.6,
                      borderRadius: 24,
                      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recipient Selector
                          Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.3,
                              borderRadius: 12,
                              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                            child: InkWell(
                              onTap: _showRecipientSearch,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'To',
                                  suffixIcon: Icon(Icons.person_search, color: AppTheme.primaryColor),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  _selectedRecipient?.name ?? 'Select Recipient',
                                  style: TextStyle(
                                    color: _selectedRecipient == null ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Subject
                          Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.3,
                              borderRadius: 12,
                              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                            child: TextFormField(
                              controller: _subjectController,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                prefixIcon: Icon(Icons.subject, color: AppTheme.primaryColor),
                              ),
                              validator: (value) => 
                                value == null || value.isEmpty ? 'Please enter a subject' : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Body
                          Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.3,
                              borderRadius: 12,
                              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                            child: TextFormField(
                              controller: _bodyController,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 12,
                              textAlignVertical: TextAlignVertical.top,
                              validator: (value) => 
                                value == null || value.isEmpty ? 'Please enter a message' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _RecipientSearchDialog extends StatefulWidget {
  final Function(UserSelectModel) onSelect;

  const _RecipientSearchDialog({required this.onSelect});

  @override
  State<_RecipientSearchDialog> createState() => _RecipientSearchDialogState();
}

class _RecipientSearchDialogState extends State<_RecipientSearchDialog> {
  final _searchController = TextEditingController();
  List<UserSelectModel> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load initial list (e.g. teachers/staff)
    _searchUsers('');
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<MessageServiceApi>(context, listen: false);
      final users = await service.searchUsers(query: query);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select User'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // adding debounce here would be good, simpler for now
                if (value.length > 2 || value.isEmpty) {
                  _searchUsers(value);
                }
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return ListTile(
                              leading: CircleAvatar(child: Text(user.name[0])),
                              title: Text(user.name),
                              subtitle: Text('${user.role} • ${user.email}'),
                              onTap: () => widget.onSelect(user),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
