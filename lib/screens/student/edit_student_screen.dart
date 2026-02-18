import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/student_model.dart';
import '../../core/services/student_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class EditStudentScreen extends StatefulWidget {
  final StudentModel student;

  const EditStudentScreen({super.key, required this.student});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _admissionNumberController;
  late TextEditingController _parentIdController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.student.fullName);
    _admissionNumberController = TextEditingController(text: widget.student.admissionNumber ?? '');
    _parentIdController = TextEditingController(text: widget.student.parentId?.toString() ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _admissionNumberController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }

  Future<void> _updateStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final studentService = Provider.of<StudentServiceApi>(context, listen: false);
        
        await studentService.updateStudent(
          int.tryParse(widget.student.id) ?? 0,
          studentName: _fullNameController.text.trim(),
          admissionNumber: _admissionNumberController.text.trim().isNotEmpty
              ? _admissionNumberController.text.trim()
              : null,
          parentId: _parentIdController.text.trim().isNotEmpty 
              ? int.tryParse(_parentIdController.text.trim()) 
              : null,
        );

        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Student updated successfully');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Error updating student: $e');
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Student'),
      body: Container(
        height: double.infinity,
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassDecoration(
                  context: context,
                  opacity: 0.6,
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
                        'Student Record',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update the student profile information.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _fullNameController,
                        labelText: 'Full Name',
                        prefixIcon: Icons.person,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _admissionNumberController,
                        labelText: 'Admission Number (Optional)',
                        prefixIcon: Icons.badge,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _parentIdController,
                        labelText: 'Parent ID (Optional)',
                        prefixIcon: Icons.supervisor_account,
                        keyboardType: TextInputType.number,
                        helperText: 'Link to a parent account using their ID',
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Update Student',
                        isLoading: _isLoading,
                        onPressed: _updateStudent,
                        icon: Icons.save,
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
