import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/class_model.dart';
import '../../core/models/student_model.dart';
import '../../core/models/term_model.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class AddFeeScreen extends StatefulWidget {
  final String sectionId;
  final String? sessionId;
  final String? termId;

  const AddFeeScreen({
    super.key,
    required this.sectionId,
    this.sessionId,
    this.termId,
  });

  @override
  State<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends State<AddFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedSessionId;
  String? _selectedTermId;
  String? _selectedClassId;
  String? _selectedStudentId;
  DateTime? _dueDate;
  
  List<TermModel> _terms = [];
  List<ClassModel> _classes = [];
  List<StudentModel> _students = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.sessionId;
    _selectedTermId = widget.termId;
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_selectedSessionId != null) {
      await _loadTerms();
    }
    await _loadClasses();
  }

  Future<void> _loadTerms() async {
    if (_selectedSessionId == null) return;
    try {
      final termService = Provider.of<TermServiceApi>(context, listen: false);
      final termsData = await termService.getTerms(
        sectionId: int.tryParse(widget.sectionId),
        sessionId: int.tryParse(_selectedSessionId!),
      );
      if (mounted) {
        setState(() {
          _terms = termsData.map((data) => TermModel.fromMap(data)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading terms: $e');
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(sectionId: int.tryParse(widget.sectionId));
      if (mounted) {
        setState(() {
          _classes = classesData.map((data) => ClassModel.fromMap(data)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final studentsData = await studentService.getStudents(classId: int.tryParse(_selectedClassId!));
      if (mounted) {
        setState(() {
          _students = studentsData.map((data) => StudentModel.fromMap(data)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _createFee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTermId == null) {
      AppSnackbar.showError(context, message: 'Please select a term');
      return;
    }
    if (_dueDate == null) {
      AppSnackbar.showError(context, message: 'Please select a due date');
      return;
    }

    setState(() => _isLoading = true);

    String feeScope = 'section';
    if (_selectedStudentId != null) {
      feeScope = 'student';
    } else if (_selectedClassId != null) {
      feeScope = 'class';
    }

    try {
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);
      
      await feeService.createFee(
        sectionId: int.tryParse(widget.sectionId) ?? 0,
        sessionId: int.tryParse(_selectedSessionId ?? '') ?? 0,
        termId: int.tryParse(_selectedTermId!) ?? 0,
        feeName: _nameController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        feeScope: feeScope,
        dueDate: _dueDate!.toIso8601String(),
        description: _descriptionController.text.trim(),
        classId: _selectedClassId != null ? int.tryParse(_selectedClassId!) : null,
        studentId: _selectedStudentId != null ? int.tryParse(_selectedStudentId!) : null,
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Fee created successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error creating fee: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Create Fee',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(
                context: context,
                opacity: 0.6,
                borderRadius: 24,
                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Fee Name (e.g. Tuition Fee)',
                      prefixIcon: Icons.label,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _amountController,
                      labelText: 'Amount (Negative for Discounts/Scholarships)',
                      prefixIcon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    if (_terms.isNotEmpty)
                      Container(
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.3,
                          borderRadius: 12,
                          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTermId,
                          decoration: const InputDecoration(
                            labelText: 'Term',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          ),
                          items: _terms.map((t) => DropdownMenuItem(value: t.id, child: Text(t.termName))).toList(),
                          onChanged: (value) => setState(() => _selectedTermId = value),
                          validator: (value) => value == null ? 'Please select a term' : null,
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
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Class (Optional - Specific Class Only)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.class_, color: AppTheme.primaryColor),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Classes')),
                          ..._classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClassId = value;
                            _selectedStudentId = null;
                          });
                          _loadStudents();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
      
                    if (_selectedClassId != null && _students.isNotEmpty)
                      Container(
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.3,
                          borderRadius: 12,
                          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStudentId,
                          decoration: const InputDecoration(
                            labelText: 'Student (Optional - Specific Student Only)',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Students in Class')),
                            ..._students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))),
                          ],
                          onChanged: (value) => setState(() => _selectedStudentId = value),
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
                          _dueDate == null ? 'Select Due Date *' : 'Due Date: ${Formatters.formatDate(_dueDate!)}',
                          style: TextStyle(color: _dueDate == null ? Colors.grey : AppTheme.primaryColor),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(height: 16),
      
                    CustomTextField(
                      controller: _descriptionController,
                      labelText: 'Description (Optional)',
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 32),
      
                    CustomButton(
                      text: 'Create Fee',
                      isLoading: _isLoading,
                      onPressed: _createFee,
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
    );
  }
}
