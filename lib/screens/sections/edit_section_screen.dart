import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/section_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class EditSectionScreen extends StatefulWidget {
  final SectionModel section;

  const EditSectionScreen({super.key, required this.section});

  @override
  State<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<EditSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.section.sectionName;
    _aboutController.text = widget.section.aboutSection ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _editSection(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final userMap = authService.currentUser;
    final user = userMap != null ? UserModel.fromMap(userMap) : null;

    if (user == null || (user.role != UserRole.proprietor && user.role != UserRole.principal)) {
      AppSnackbar.showError(context, message: 'Access Denied');
      setState(() => _isLoading = false);
      return;
    }

    final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
    
    try {
      await sectionService.updateSection(
        int.tryParse(widget.section.id) ?? 0,
        sectionName: _nameController.text.trim(),
        aboutSection: _aboutController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
        AppSnackbar.showSuccess(context, message: 'Section updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.showError(context, message: 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Section',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(
                context: context,
                opacity: 0.8,
                borderRadius: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Section Information',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update section details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Section Name',
                      prefixIcon: Icons.business_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _aboutController,
                      labelText: 'About Section (Optional)',
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Save Changes',
                      isLoading: _isLoading,
                      onPressed: () => _editSection(context),
                      icon: Icons.save_rounded,
                      backgroundColor: theme.colorScheme.primary,
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
