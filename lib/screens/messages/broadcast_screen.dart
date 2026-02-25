import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/message_service_api.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_snackbar.dart';

class BroadcastScreen extends StatefulWidget {
  final String? sectionId;

  const BroadcastScreen({super.key, this.sectionId});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedRole = 'parent';
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.sectionId == null) {
      AppSnackbar.showWarning(context, message: 'Please select a section first.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final messageService = Provider.of<MessageServiceApi>(context, listen: false);
      await messageService.broadcastMessage(
        sectionId: int.parse(widget.sectionId!),
        role: _selectedRole,
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Broadcast sent to all ${_selectedRole}s!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Section Broadcast',
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(theme),
                  const SizedBox(height: 24),
                  _buildRoleSelector(theme, isDark),
                  const SizedBox(height: 24),
                  _buildMessageForm(theme, isDark),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _handleBroadcast,
                      icon: _isSending 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        _isSending ? 'Sending...' : 'Send Broadcast',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context, 
        opacity: 0.8,
        borderRadius: 20,
        hasGlow: true,
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mass Communications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'Send instant notifications to everyone in this section.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Target Audience',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRoleOption('parent', 'Parents', Icons.family_restroom_rounded, theme),
            const SizedBox(width: 16),
            _buildRoleOption('teacher', 'Teachers', Icons.school_rounded, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption(String role, String label, IconData icon, ThemeData theme) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: isSelected ? 0.9 : 0.4,
            borderRadius: 20,
            hasGlow: isSelected,
            borderColor: isSelected 
                ? AppTheme.primaryColor.withValues(alpha: 0.5) 
                : theme.dividerColor.withValues(alpha: 0.1),
          ).copyWith(
            gradient: isSelected ? AppTheme.primaryGradient : null,
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : theme.iconTheme.color?.withValues(alpha: 0.6), 
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageForm(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context, 
        opacity: 0.6,
        borderRadius: 24,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Message Details',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _subjectController,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: 'e.g. Term Fees Notice',
              prefixIcon: const Icon(Icons.subject_rounded, color: AppTheme.primaryColor),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Please enter a subject' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _bodyController,
            maxLines: 8,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              labelText: 'Message Body',
              hintText: 'Type your announcement here...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Please enter the message body' : null,
          ),
        ],
      ),
    );
  }
}
