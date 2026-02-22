import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/class_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class AddClassScreen extends StatefulWidget {
  final String schoolId;
  final String sectionId;

  const AddClassScreen({
    super.key,
    required this.schoolId,
    required this.sectionId,
  });

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _teacherIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  Future<void> _addClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      await classService.createClass(
        sectionId: int.parse(widget.sectionId),
        className: _nameController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()),
        formTeacherId: int.tryParse(_teacherIdController.text.trim()),
      );
      
      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Class added successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error adding class: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add Class',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
              theme.primaryColor.withValues(alpha: 0.05),
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
                      'Class Information',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new class for this section',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Class Name',
                      prefixIcon: Icons.class_,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _capacityController,
                      labelText: 'Capacity',
                      prefixIcon: Icons.people,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _teacherIdController,
                      labelText: 'Teacher ID (Optional)',
                      prefixIcon: Icons.person,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Add Class',
                      isLoading: _isLoading,
                      onPressed: _addClass,
                      icon: Icons.add,
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
