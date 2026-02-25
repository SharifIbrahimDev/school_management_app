import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/academic_session_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_snackbar.dart';

class EditSessionScreen extends StatefulWidget {
  final AcademicSessionModel session;
  final VoidCallback onSuccess;

  const EditSessionScreen({
    super.key,
    required this.session,
    required this.onSuccess,
  });

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final sessionNameController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool isActive = false;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    sessionNameController.text = widget.session.sessionName;
    startDate = widget.session.startDate;
    endDate = widget.session.endDate;
    isActive = widget.session.isActive;
  }

  @override
  void dispose() {
    sessionNameController.dispose();
    super.dispose();
  }

  Future<void> _deleteSession() async {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
    final schoolId = authService.currentUserModel?.schoolId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${widget.session.sessionName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && schoolId != null) {
      try {
        await sessionService.deleteAcademicSession(
          schoolId: schoolId,
          sectionId: widget.session.sectionId,
          sessionId: widget.session.id,
        );
        if (!mounted) return;
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, message: 'Session deleted successfully!');
        widget.onSuccess();
      } catch (e) {
        if (!mounted) return;
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final isPrincipal = authService.currentUserModel?.role == UserRole.principal;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Academic Session',
        actions: [
          if (isPrincipal)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteSession,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassDecoration(
                  context: context,
                  opacity: 0.6,
                  borderRadius: 24,
                  borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: sessionNameController,
                        decoration: InputDecoration(
                          labelText: 'Session Name',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Enter a session name' : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.3,
                          borderRadius: 12,
                          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                        child: ListTile(
                          title: Text(
                            'Start: ${DateFormat('dd/MM/yyyy').format(startDate!)}',
                            style: const TextStyle(color: AppTheme.primaryColor),
                          ),
                          trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate!,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.3,
                          borderRadius: 12,
                          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                        child: ListTile(
                          title: Text(
                            'End: ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                             style: const TextStyle(color: AppTheme.primaryColor),
                          ),
                          trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate!,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (picked != null) {
                              setState(() => endDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.3,
                          borderRadius: 12,
                          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                        child: CheckboxListTile(
                          title: const Text('Active'),
                          value: isActive,
                          activeColor: AppTheme.primaryColor,
                          onChanged: isPrincipal ? (value) => setState(() => isActive = value!) : null,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isPrincipal
                              ? () async {
                            if (formKey.currentState!.validate() && startDate != null && endDate != null) {
                              if (endDate!.isBefore(startDate!)) {
                                AppSnackbar.showWarning(context, message: 'End date must be after start date.');
                                return;
                              }
                              try {
                                final authService = Provider.of<AuthServiceApi>(context, listen: false);
                                final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
                                final schoolId = authService.currentUserModel?.schoolId;
                                if (schoolId == null || authService.currentUserModel == null) {
                                  throw Exception('No school assigned or user not logged in');
                                }
        
                                await sessionService.updateAcademicSession(
                                  schoolId: schoolId,
                                  sectionId: widget.session.sectionId,
                                  sessionId: widget.session.id,
                                  sessionName: sessionNameController.text,
                                  startDate: startDate!,
                                  endDate: endDate!,
                                  isActive: isActive,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                AppSnackbar.showSuccess(context, message: 'Session updated successfully!');
                                widget.onSuccess();
                              } catch (e) {
                                if (!context.mounted) return;
                                AppSnackbar.friendlyError(context, error: e);
                              }
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Update Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
