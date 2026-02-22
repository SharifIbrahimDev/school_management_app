import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/class_model.dart';
import '../../core/services/class_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class EditClassScreen extends StatefulWidget {
  final ClassModel classModel;
  final String schoolId;
  final String sectionId;

  const EditClassScreen({
    super.key,
    required this.classModel,
    required this.schoolId,
    required this.sectionId,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _teacherIdController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classModel.name);
    _capacityController = TextEditingController(text: widget.classModel.capacity?.toString() ?? '');
    _teacherIdController = TextEditingController(text: widget.classModel.assignedTeacherUserId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  Future<void> _updateClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      await classService.updateClass(
        int.parse(widget.classModel.id),
        className: _nameController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()),
        formTeacherId: int.tryParse(_teacherIdController.text.trim()),
      );
      
      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Class updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error updating class: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Class',
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
                hasGlow: true,
                borderColor: theme.dividerColor.withValues(alpha: 0.1),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Class Information',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update class details and settings',
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
                      text: 'Update Class',
                      isLoading: _isLoading,
                      onPressed: _updateClass,
                      icon: Icons.save,
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
