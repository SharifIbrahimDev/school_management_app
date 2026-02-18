import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/subject_model.dart';
import '../../core/services/subject_service_api.dart';
// Need classes to select from
// Need teachers to assign
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../core/utils/error_handler.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  bool _isLoading = true;
  String? _error;
  List<SubjectModel> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Provider.of<SubjectServiceApi>(context, listen: false);
      final subjects = await service.getSubjects(); // pass schoolId if needed
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showSubjectDialog({SubjectModel? subject}) {
    showDialog(
      context: context,
      builder: (context) => _SubjectDialog(
        subject: subject,
        onSave: () => _loadSubjects(),
      ),
    );
  }

  Future<void> _deleteSubject(SubjectModel subject) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Subject',
      content: 'Are you sure you want to delete ${subject.name}? This will affect all exam results linked to this subject.',
      confirmText: 'Delete Subject',
      confirmColor: Colors.red,
      icon: Icons.book_rounded,
    );

    if (confirm == true) {
      try {
        await Provider.of<SubjectServiceApi>(context, listen: false).deleteSubject(subject.id);
        _loadSubjects();
      } catch (e) {
        if (mounted) AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Subjects',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            onPressed: () => _showSubjectDialog(),
          ),
        ],
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
          child: _isLoading
              ? const Center(child: LoadingIndicator(message: 'Fetching curriculum...'))
              : _error != null
                  ? ErrorDisplayWidget(error: _error!, onRetry: _loadSubjects)
                  : _subjects.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.book,
                          title: 'No Subjects',
                          message: 'Add subjects to manage curriculum.',
                          actionButtonText: 'Add Subject',
                          onActionPressed: () => _showSubjectDialog(),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _subjects.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return Container(
                              decoration: AppTheme.glassDecoration(
                                context: context,
                                opacity: 0.6,
                                borderRadius: 16,
                                hasGlow: true,
                                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    subject.name.isNotEmpty ? subject.name[0] : '?',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  subject.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.class_, size: 14, color: AppTheme.textHintColor),
                                        const SizedBox(width: 4),
                                        Text(subject.className ?? 'No Class', style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 14, color: AppTheme.textHintColor),
                                        const SizedBox(width: 4),
                                        Text(subject.teacherName ?? 'No Teacher', style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showSubjectDialog(subject: subject);
                                    } else if (value == 'delete') {
                                      _deleteSubject(subject);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _SubjectDialog extends StatefulWidget {
  final SubjectModel? subject;
  final VoidCallback onSave;

  const _SubjectDialog({this.subject, required this.onSave});

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  
  int? _selectedClassId;
  int? _selectedTeacherId;
  bool _isLoading = false;
  
  // TODO: Load these lists from services
  // For now using mock/limited logic or assuming service will provided cached list
  // Ideally, initState should load classes and teachers
  List<dynamic> _classes = []; 
  List<dynamic> _teachers = [];

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _codeController.text = widget.subject!.code ?? '';
      _selectedClassId = widget.subject!.classId;
      _selectedTeacherId = widget.subject!.teacherId;
    }
    _loadDependencies();
  }
  
  Future<void> _loadDependencies() async {
    // Fetch classes and teachers
    // Requires ClassServiceApi and UserServiceApi
    // Dummy imp for now since we haven't implemented getTeachers in UserServiceApi explicitly (only getUsers/import) 
    // and ClassServiceApi exists but might need updating.
    
    // Simulating loading for UI structure validation
    setState(() {
       // Mock for now until linked services are confirmed to return proper lists
       _classes = [{'id': 1, 'name': 'Class 1'}, {'id': 2, 'name': 'Class 2'}]; 
       _teachers = [{'id': 2, 'name': 'Teacher A'}, {'id': 3, 'name': 'Teacher B'}]; // Assuming IDs
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      AppSnackbar.showWarning(context, message: 'Please select a class');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<SubjectServiceApi>(context, listen: false);
      final data = {
        'name': _nameController.text,
        'code': _codeController.text,
        'class_id': _selectedClassId,
        'teacher_id': _selectedTeacherId,
      };

      if (widget.subject != null) {
        await service.updateSubject(widget.subject!.id, data);
      } else {
        await service.createSubject(data);
      }
      
      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.9,
          borderRadius: 24,
          borderColor: theme.dividerColor.withValues(alpha: 0.1),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject != null ? 'Edit Subject' : 'Add Subject',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'Mathematics',
                    filled: true,
                    fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Code',
                    hintText: 'MAT101',
                    filled: true,
                    fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    filled: true,
                    fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ),
                  items: _classes.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem(value: c['id'], child: Text(c['name']));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClassId = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedTeacherId,
                  decoration: InputDecoration(
                    labelText: 'Teacher (Optional)',
                    filled: true,
                    fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ),
                  items: _teachers.map<DropdownMenuItem<int>>((t) {
                    return DropdownMenuItem(value: t['id'], child: Text(t['name']));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTeacherId = val),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
