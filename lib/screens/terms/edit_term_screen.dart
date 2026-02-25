import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/academic_session_model.dart';
import '../../core/models/term_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_snackbar.dart';

class EditTermScreen extends StatefulWidget {
  final TermModel term;
  final AcademicSessionModel session;
  final String schoolId;
  final String sectionId;
  final VoidCallback onSuccess;

  const EditTermScreen({
    super.key,
    required this.term,
    required this.session,
    required this.schoolId,
    required this.sectionId,
    required this.onSuccess,
  });

  @override
  State<EditTermScreen> createState() => _EditTermScreenState();
}

class _EditTermScreenState extends State<EditTermScreen> {
  final termNameController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool isActive = false;
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    termNameController.text = widget.term.termName;
    startDate = widget.term.startDate;
    endDate = widget.term.endDate;
    isActive = widget.term.isActive;
  }

  @override
  void dispose() {
    termNameController.dispose();
    super.dispose();
  }

  Future<void> _deleteTerm() async {
    final termService = Provider.of<TermServiceApi>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Term'),
        content: Text('Are you sure you want to delete "${widget.term.termName}"?'),
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
    if (!mounted) return;
    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await termService.deleteTerm(
          int.parse(widget.term.id),
        );
        if (!context.mounted) return;
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, message: 'Term deleted successfully!');
        widget.onSuccess();
      } catch (e) {
        if (!context.mounted) return;
        AppSnackbar.friendlyError(context, error: e);
      } finally {
        if (context.mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final isPrincipal = authService.currentUserModel?.role == UserRole.principal;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Term',
        actions: [
          if (isPrincipal)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteTerm,
            ),
        ],
      ),
      body: Container(
        height: double.infinity,
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
              : Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: termNameController,
                              decoration: InputDecoration(
                                labelText: 'Term Name',
                                filled: true,
                                fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                                ),
                              ),
                              validator: (value) => value!.isEmpty ? 'Enter a term name' : null,
                              enabled: isPrincipal,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: AppTheme.glassDecoration(
                                context: context,
                                opacity: 0.3,
                                borderRadius: 12,
                                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              ),
                              child: ListTile(
                                title: Text(
                                  'Start: ${DateFormat('dd MMM, yyyy').format(startDate!)}',
                                  style: const TextStyle(color: AppTheme.primaryColor),
                                ),
                                trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                onTap: isPrincipal
                                    ? () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: startDate!,
                                          firstDate: widget.session.startDate,
                                          lastDate: widget.session.endDate,
                                        );
                                        if (picked != null) {
                                          setState(() => startDate = picked);
                                        }
                                      }
                                    : null,
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
                                  'End: ${DateFormat('dd MMM, yyyy').format(endDate!)}',
                                  style: const TextStyle(color: AppTheme.primaryColor),
                                ),
                                trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                onTap: isPrincipal
                                    ? () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: endDate!,
                                          firstDate: widget.session.startDate,
                                          lastDate: widget.session.endDate,
                                        );
                                        if (picked != null) {
                                          setState(() => endDate = picked);
                                        }
                                      }
                                    : null,
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
                            if (isPrincipal)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate() && startDate != null && endDate != null) {
                                      if (endDate!.isBefore(startDate!)) {
                                        AppSnackbar.showWarning(context, message: 'End date must be after start date.');
                                        return;
                                      }
                                      try {
                                        setState(() => _isLoading = true);
                                        final termService = Provider.of<TermServiceApi>(context, listen: false);
                                        await termService.updateTerm(
                                          id: int.parse(widget.term.id),
                                          termName: termNameController.text,
                                          startDate: startDate!,
                                          endDate: endDate!,
                                          isActive: isActive,
                                        );
                                        if (!context.mounted) return;
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          AppSnackbar.showSuccess(context, message: 'Term updated successfully!');
                                          widget.onSuccess();
                                        }
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        if (context.mounted) {
                                          AppSnackbar.friendlyError(context, error: e);
                                        }
                                      } finally {
                                        if (context.mounted) setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Update Term', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
