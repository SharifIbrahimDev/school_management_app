import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/student_model.dart';
import '../../core/services/student_service_api.dart';
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
  final _fullNameController = TextEditingController();
  final _parentIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.student.fullName;
    _parentIdController.text = widget.student.parentId?.toString() ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
          parentId: _parentIdController.text.trim().isNotEmpty 
              ? int.tryParse(_parentIdController.text.trim()) 
              : null,
        );

        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Student updated successfully');
          Navigator.pop(context);
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
    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Student'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name',
                  prefixIcon: Icons.person,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _parentIdController,
                  labelText: 'Parent ID (Optional)',
                  prefixIcon: Icons.supervisor_account,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Display currently assigned sections (read-only)
                if (widget.student.sectionIds.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currently assigned to:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.student.sectionIds.map((sectionId) {
                            return Chip(
                              label: Text('Section $sectionId'),
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 24),
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
    );
  }
}
