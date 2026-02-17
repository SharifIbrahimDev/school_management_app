import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/homework_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/subject_service_api.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';

class AddHomeworkScreen extends StatefulWidget {
  const AddHomeworkScreen({super.key});

  @override
  State<AddHomeworkScreen> createState() => _AddHomeworkScreenState();
}

class _AddHomeworkScreenState extends State<AddHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Data
  List<dynamic> _classes = [];
  List<dynamic> _sections = [];
  List<dynamic> _subjects = [];
  
  // Selection
  int? _selectedClassId;
  int? _selectedSectionId;
  int? _selectedSubjectId;
  
  // Form Fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  
  bool _isLoading = false;
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classes = await classService.getClasses();
      
      if (mounted) {
        setState(() {
          _classes = classes;
          _isInitLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading classes: $e')));
      }
    }
  }

  Future<void> _loadDependentData() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final subjectService = Provider.of<SubjectServiceApi>(context, listen: false);
      
      // Load Sections
      final allSections = await sectionService.getSections(isActive: true);
      final classSections = allSections.where((s) => s['class_id'].toString() == _selectedClassId.toString()).toList();
      
      // Load Subjects
      // Assuming subjects are linked to class or just school wide. 
      // Using generic getSubjects which likely returns list for the school.
      final subjects = await subjectService.getSubjects(classId: _selectedClassId);

      if (mounted) {
        setState(() {
          _sections = classSections;
          _subjects = subjects;
          _selectedSectionId = null; // Reset selection
          _selectedSubjectId = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Clean error handling needed here?
      }
    }
  }

  Future<void> _saveHomework() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }
    // Section is optional? Usually yes, if for whole class. But let's enforce if sections exist.
    if (_sections.isNotEmpty && _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a section')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<HomeworkServiceApi>(context, listen: false);
      
      final Map<String, dynamic> payload = {
        'class_id': _selectedClassId,
        'subject_id': _selectedSubjectId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
      };
      
      if (_selectedSectionId != null) {
        payload['section_id'] = _selectedSectionId;
      }

      await service.createHomework(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Homework assigned successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) return const Scaffold(body: Center(child: LoadingIndicator()));

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Assign Homework',
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.accentColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Audience
                  Text('Target Audience', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                          items: _classes.map<DropdownMenuItem<int>>((c) {
                             return DropdownMenuItem(value: c['id'], child: Text(c['class_name'] ?? c['name'] ?? 'Class'));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedClassId = val);
                            _loadDependentData();
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedSectionId,
                          decoration: const InputDecoration(labelText: 'Section (Optional for whole class)', border: OutlineInputBorder()),
                          items: _sections.map<DropdownMenuItem<int>>((s) {
                             return DropdownMenuItem(value: s['id'], child: Text(s['section_name'] ?? s['name'] ?? 'Section'));
                          }).toList(),
                          onChanged: _sections.isEmpty ? null : (val) {
                            setState(() => _selectedSectionId = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Assignment Details
                  Text('Assignment Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: _selectedSubjectId,
                          decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                          items: _subjects.map<DropdownMenuItem<int>>((s) {
                             return DropdownMenuItem(value: s['id'], child: Text(s['subject_name'] ?? s['name'] ?? 'Subject'));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSubjectId = val);
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Homework Title', border: OutlineInputBorder()),
                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                          maxLines: 4,
                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMM d, yyyy').format(_dueDate)),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveHomework,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Assign Homework', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
