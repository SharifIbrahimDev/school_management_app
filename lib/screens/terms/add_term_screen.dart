import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';

class AddTermScreen extends StatefulWidget {
  final AcademicSessionModel session;
  final String schoolId;
  final String sectionId;
  final VoidCallback onSuccess;

  const AddTermScreen({
    super.key,
    required this.session,
    required this.schoolId,
    required this.sectionId,
    required this.onSuccess,
  });

  @override
  State<AddTermScreen> createState() => _AddTermScreenState();
}

class _AddTermScreenState extends State<AddTermScreen> {
  final termNameController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    termNameController.dispose();
    super.dispose();
  }

  Future<void> _addTerm() async {
    if (!formKey.currentState!.validate() || startDate == null || endDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      }
      return;
    }
    if (endDate!.isBefore(startDate!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date must be after start date')),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Confirm Term',
        content: 'Are you sure you want to add this term?',
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final termService = Provider.of<TermServiceApi>(context, listen: false);
    try {
      await termService.createTerm(
        schoolId: widget.schoolId,
        sectionId: widget.sectionId,
        sessionId: widget.session.id,
        termName: termNameController.text,
        startDate: startDate!,
        endDate: endDate!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Term added successfully')),
        );
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding term: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final isPrincipal = authService.currentUserModel?.role == UserRole.principal;

    if (!isPrincipal) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Add Term'),
        body: Center(child: Text('Only principals can add terms')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add Term',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
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
                                labelText: 'Term Name (e.g., Term 1)',
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
                                  startDate == null
                                      ? 'Select Start Date'
                                      : 'Start: ${DateFormat('dd MMM, yyyy').format(startDate!)}',
                                  style: TextStyle(color: startDate == null ? Colors.grey : AppTheme.primaryColor),
                                ),
                                trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: widget.session.startDate,
                                    firstDate: widget.session.startDate,
                                    lastDate: widget.session.endDate,
                                  );
                                  if (picked != null && mounted) {
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
                                  endDate == null
                                      ? 'Select End Date'
                                      : 'End: ${DateFormat('dd MMM, yyyy').format(endDate!)}',
                                  style: TextStyle(color: endDate == null ? Colors.grey : AppTheme.primaryColor),
                                ),
                                trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: widget.session.endDate,
                                    firstDate: widget.session.startDate,
                                    lastDate: widget.session.endDate,
                                  );
                                  if (picked != null && mounted) {
                                    setState(() => endDate = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                            CustomButton(
                              text: 'Add Term',
                              isLoading: _isLoading,
                              onPressed: _addTerm,
                              icon: Icons.add,
                              backgroundColor: AppTheme.primaryColor,
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
