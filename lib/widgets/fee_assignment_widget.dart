import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/student_model.dart';
import '../core/services/auth_service_api.dart';
import '../core/services/student_service_api.dart';
import '../core/services/transaction_service_api.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/constants.dart';
import '../core/utils/validators.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_indicator.dart';
import 'confirmation_dialog.dart';

class FeeAssignmentScreen extends StatefulWidget {
  final String schoolId;
  final String sectionId;
  final String classId;
  final String sessionId;
  final String termId;
  final String? studentId;

  const FeeAssignmentScreen({
    super.key,
    required this.schoolId,
    required this.sectionId,
    required this.classId,
    required this.sessionId,
    required this.termId,
    this.studentId,
  });

  @override
  _FeeAssignmentScreenState createState() => _FeeAssignmentScreenState();
}

class _FeeAssignmentScreenState extends State<FeeAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _paymentType = 'cash';
  bool _isLoading = false;
  final List<String> _selectedStudentIds = [];
  List<StudentModel> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (widget.studentId != null) return;
    
    setState(() => _isLoading = true);
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final students = await studentService.getStudents(
        classId: int.tryParse(widget.classId),
      );
      setState(() {
        _students = students.map((s) => StudentModel.fromMap(s)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error loading students: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _assignFees() async {
    if (!_formKey.currentState!.validate() || (_selectedStudentIds.isEmpty && widget.studentId == null)) {
      AppSnackbar.showError(context, message: 'Please select at least one student');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Confirm Fee Assignment',
        content: 'Are you sure you want to assign fees to ${widget.studentId != null ? 'this student' : 'the selected students'}?',
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
    
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      AppSnackbar.showError(context, message: 'User not authenticated');
      setState(() => _isLoading = false);
      return;
    }

    final studentIds = widget.studentId != null ? [widget.studentId!] : _selectedStudentIds;

    try {
      for (final studentId in studentIds) {
        await transactionService.addTransaction(
          sectionId: int.tryParse(widget.sectionId) ?? 0,
          sessionId: int.tryParse(widget.sessionId),
          termId: int.tryParse(widget.termId),
          studentId: int.tryParse(studentId),
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          transactionType: 'credit',
          paymentMethod: _paymentType,
          description: _descriptionController.text,
          transactionDate: DateTime.now().toIso8601String(),
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.showSuccess(context, message: 'Fees assigned successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to assign fees: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentId != null ? 'Assign Fee to Student' : 'Assign Fees to Class'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading && _students.isEmpty && widget.studentId == null
            ? const LoadingIndicator(message: 'Loading...')
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (widget.studentId == null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Students',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_students.isEmpty)
                              const Text('No students found in this class')
                            else
                              ..._students.map((student) {
                                return CheckboxListTile(
                                  title: Text(student.fullName),
                                  value: _selectedStudentIds.contains(student.id),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedStudentIds.add(student.id);
                                      } else {
                                        _selectedStudentIds.remove(student.id);
                                      }
                                    });
                                  },
                                );
                              }),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                      CustomTextField(
                        controller: _amountController,
                        labelText: 'Amount',
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        validator: Validators.validateAmount,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.brightness == Brightness.light
                              ? AppTheme.backgroundColor
                              : const Color(0xFF1E1E1E),
                        ),
                        initialValue: _selectedCategory,
                        items: AppConstants.creditCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value),
                        validator: (value) => Validators.validateRequired(value, 'Category'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Payment Type *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.brightness == Brightness.light
                              ? AppTheme.backgroundColor
                              : const Color(0xFF1E1E1E),
                        ),
                        initialValue: _paymentType,
                        items: ['cash', 'transfer'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type[0].toUpperCase() + type.substring(1)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _paymentType = value!),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        labelText: 'Description (Optional)',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Assign Fee${widget.studentId == null ? 's' : ''}',
                        isLoading: _isLoading && _selectedStudentIds.isNotEmpty,
                        onPressed: _assignFees,
                        icon: Icons.add,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
