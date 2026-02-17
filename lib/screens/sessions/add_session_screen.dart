import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service_api.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class AddSessionScreen extends StatefulWidget {
  final String selectedSectionId;
  final String schoolId;
  final VoidCallback onSuccess;

  const AddSessionScreen({
    super.key,
    required this.schoolId,
    required this.selectedSectionId,
    required this.onSuccess,
  });

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      AppSnackbar.showError(context, message: 'Please fill all required session fields');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      AppSnackbar.showError(context, message: 'End date must be after start date');
      return;
    }

    setState(() => _isLoading = true);
    final sessionService = Provider.of<SessionServiceApi>(context, listen: false);

    try {
      await sessionService.createSession(
        sectionId: int.tryParse(widget.selectedSectionId) ?? 0,
        sessionName: _sessionNameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Session added successfully');
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error adding session: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add Academic Session',
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
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomTextField(
                              controller: _sessionNameController,
                              labelText: 'Session Name (e.g., 2024/2025) *',
                              isRequired: true,
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
                                  _startDate == null ? 'Select Start Date *' : 'Start: ${Formatters.formatDate(_startDate!)}',
                                  style: TextStyle(color: _startDate == null ? Colors.grey : AppTheme.primaryColor),
                                ),
                                trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                onTap: () => _selectDate(context, true),
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
                                  _endDate == null ? 'Select End Date *' : 'End: ${Formatters.formatDate(_endDate!)}',
                                  style: TextStyle(color: _endDate == null ? Colors.grey : AppTheme.primaryColor),
                                ),
                                trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                onTap: () => _selectDate(context, false),
                              ),
                            ),
                            const SizedBox(height: 32),
                            CustomButton(
                              text: 'Add Session',
                              isLoading: _isLoading,
                              onPressed: _saveSession,
                              icon: Icons.save,
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
