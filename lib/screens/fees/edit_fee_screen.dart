import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/enums/fee_scope.dart';
import '../../core/models/user_model.dart';
import '../../core/models/fee_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/services/session_service_api.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';

class EditFeeScreen extends StatefulWidget {
  final String schoolId;
  final String sectionId;
  final String feeId;

  const EditFeeScreen({
    super.key,
    required this.schoolId,
    required this.sectionId,
    required this.feeId,
  });

  @override
  State<EditFeeScreen> createState() => _EditFeeScreenState();
}

class _EditFeeScreenState extends State<EditFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _feeType;
  double? _amount;
  DateTime? _dueDate;
  String? _description;
  String? _selectedSessionId;
  String? _selectedTermId;
  String? _selectedClassId;
  String? _selectedStudentId;
  FeeScope? _selectedScope;
  List<Map<String, dynamic>> _cachedSessions = [];
  FeeModel? _fee;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);

      // Fetch fee details
      final feeData = await feeService.getFee(int.tryParse(widget.feeId) ?? 0);
      if (feeData != null) {
        _fee = FeeModel.fromMap(feeData);
        _initializeFields();
      }

      // Fetch sessions
      final sessions = await sessionService.getSessions(sectionId: int.tryParse(widget.sectionId));
      
      if (mounted) {
        setState(() {
          _cachedSessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error loading data: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeFields() {
    if (_fee == null) return;
    _feeType = _fee!.feeType;
    _amount = _fee!.amount;
    _dueDate = _fee!.dueDate;
    _description = _fee!.description;
    _selectedSessionId = _fee!.sessionId;
    _selectedTermId = _fee!.termId;
    _selectedClassId = _fee!.classId.isNotEmpty ? _fee!.classId : null;
    _selectedStudentId = _fee!.studentId.isNotEmpty ? _fee!.studentId : null;
    _selectedScope = _fee!.feeScope;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final termService = Provider.of<TermServiceApi>(context);
    final classService = Provider.of<ClassServiceApi>(context);
    final studentService = Provider.of<StudentServiceApi>(context);
    final feeService = Provider.of<FeeServiceApi>(context);

    final userMap = authService.currentUser;
    final user = userMap != null ? UserModel.fromMap(userMap) : null;

    if (user?.role != UserRole.proprietor) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Edit Fee'),
        body: Center(child: Text('Access denied')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Edit Fee'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_fee == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Edit Fee'),
        body: Center(child: Text('Fee not found')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Fee',
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
                  children: [
                    // Fee Scope Dropdown
                    Container(
                      decoration: AppTheme.glassDecoration(
                        context: context,
                        opacity: 0.3,
                        borderRadius: 12,
                        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      child: DropdownButtonFormField<FeeScope>(
                        initialValue: _selectedScope,
                        decoration: const InputDecoration(
                          labelText: 'Select Fee Scope',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.category, color: AppTheme.primaryColor),
                        ),
                        items: FeeScope.values.map((scope) {
                          return DropdownMenuItem<FeeScope>(
                            value: scope,
                            child: Text(
                              scope == FeeScope.school
                                  ? 'Entire School'
                                  : scope == FeeScope.section
                                  ? 'Section'
                                  : scope == FeeScope.classScope
                                  ? 'Class'
                                  : 'Student',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() {
                          _selectedScope = value;
                          _selectedClassId = null;
                          _selectedStudentId = null;
                        }),
                        validator: (value) =>
                        value == null ? 'Please select a fee scope' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Academic Session Dropdown
                    Container(
                      decoration: AppTheme.glassDecoration(
                        context: context,
                        opacity: 0.3,
                        borderRadius: 12,
                        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSessionId,
                        decoration: const InputDecoration(
                          labelText: 'Select Academic Session',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.date_range, color: AppTheme.primaryColor),
                        ),
                        items: _cachedSessions.map((session) {
                          return DropdownMenuItem<String>(
                            value: session['id'].toString(),
                            child: Text(session['session_name'] ?? 'Unknown Session'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSessionId = value;
                            _selectedTermId = null;
                          });
                        },
                        validator: (value) =>
                        value == null ? 'Please select an academic session' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Term Dropdown
                    if (_selectedSessionId == null)
                      const Text('Please select a session first')
                    else
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: termService.getTerms(
                          sessionId: int.tryParse(_selectedSessionId!) ?? 0,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Text('Error loading terms');
                          }
                          final terms = snapshot.data ?? [];
                          if (terms.isEmpty) {
                            return const Text('No active terms found');
                          }
                          return Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.3,
                              borderRadius: 12,
                              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: terms.any((t) => t['id'].toString() == _selectedTermId)
                                  ? _selectedTermId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Select Term',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                              ),
                              items: terms.map((term) {
                                return DropdownMenuItem<String>(
                                  value: term['id'].toString(),
                                  child: Text(term['term_name'] ?? 'Unknown Term'),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedTermId = value),
                              validator: (value) => value == null ? 'Please select a term' : null,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    // Class Dropdown (shown for class or student scope)
                    if (_selectedScope == FeeScope.classScope || _selectedScope == FeeScope.student)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: classService.getClasses(
                          sectionId: int.tryParse(widget.sectionId),
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final classes = snapshot.data!;
                          return Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.3,
                              borderRadius: 12,
                              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedClassId,
                              decoration: const InputDecoration(
                                labelText: 'Select Class',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                prefixIcon: Icon(Icons.school, color: AppTheme.primaryColor),
                              ),
                              items: classes.map((classData) {
                                return DropdownMenuItem<String>(
                                  value: classData['id'].toString(),
                                  child: Text(classData['class_name'] ?? 'Unknown Class'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedClassId = value;
                                  _selectedStudentId = null;
                                });
                              },
                              validator: (value) =>
                              value == null ? 'Please select a class' : null,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    // Student Dropdown (shown for student scope)
                    if (_selectedScope == FeeScope.student && _selectedClassId != null)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: studentService.getStudents(
                          classId: int.tryParse(_selectedClassId!) ?? 0,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final students = snapshot.data!;
                          return Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.3,
                              borderRadius: 12,
                              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStudentId,
                              decoration: const InputDecoration(
                                labelText: 'Select Student',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                              ),
                              items: students.map((studentData) {
                                return DropdownMenuItem<String>(
                                  value: studentData['id'].toString(),
                                  child: Text(studentData['student_name'] ?? 'Unknown Student'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStudentId = value;
                                });
                              },
                              validator: (value) =>
                              value == null ? 'Please select a student' : null,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: AppTheme.glassDecoration(
                        context: context,
                        opacity: 0.3,
                        borderRadius: 12,
                        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      child: TextFormField(
                        initialValue: _feeType,
                        decoration: const InputDecoration(
                          labelText: 'Fee Type',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.label, color: AppTheme.primaryColor),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter a fee type' : null,
                        onSaved: (value) => _feeType = value,
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
                      child: TextFormField(
                        initialValue: _amount?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Amount (Negative for Discounts/Scholarships)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryColor),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter an amount';
                          final amount = double.tryParse(value);
                          if (amount == null) return 'Please enter a valid amount';
                          return null;
                        },
                        onSaved: (value) => _amount = double.parse(value!),
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
                      child: TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.description, color: AppTheme.primaryColor),
                        ),
                        maxLines: 3,
                        onSaved: (value) => _description = value,
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
                          _dueDate == null
                              ? 'Select Due Date'
                              : 'Due Date: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _dueDate == null ? Colors.grey : AppTheme.primaryColor,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (selectedDate != null) {
                            setState(() => _dueDate = selectedDate);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          
                          if (_selectedSessionId == null || _selectedTermId == null || _dueDate == null || _selectedScope == null) {
                              AppSnackbar.showError(context, message: 'Please fill all required fields');
                              return;
                          }
    
                          setState(() => _isLoading = true);
    
                          try {
                            await feeService.updateFee(
                              int.parse(widget.feeId),
                              sectionId: int.parse(widget.sectionId),
                              sessionId: int.parse(_selectedSessionId!),
                              termId: int.parse(_selectedTermId!),
                              classId: _selectedClassId != null ? int.tryParse(_selectedClassId!) : null,
                              studentId: _selectedStudentId != null ? int.tryParse(_selectedStudentId!) : null,
                              feeName: _feeType,
                              amount: _amount,
                              feeScope: _selectedScope! == FeeScope.classScope ? 'class' : _selectedScope!.toString().split('.').last,
                              dueDate: _dueDate!.toIso8601String().split('T')[0],
                              description: _description,
                            );
    
                            if (mounted) {
                              AppSnackbar.showSuccess(context, message: 'Fee updated successfully');
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            if (mounted) {
                              AppSnackbar.showError(context, message: 'Error updating fee: $e');
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Update Fee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
