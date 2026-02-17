import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/lesson_plan_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/subject_service_api.dart';
import '../../core/models/section_model.dart';
import '../../core/models/class_model.dart';
import '../../core/models/subject_model.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';

class AddLessonPlanScreen extends StatefulWidget {
  const AddLessonPlanScreen({super.key});

  @override
  State<AddLessonPlanScreen> createState() => _AddLessonPlanScreenState();
}

class _AddLessonPlanScreenState extends State<AddLessonPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _weekController = TextEditingController(text: '1');

  String? _selectedSectionId;
  String? _selectedClassId;
  String? _selectedSubjectId;

  List<SectionModel> _sections = [];
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _weekController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final sectionsData = await sectionService.getSections(isActive: true);
      setState(() {
        _sections = sectionsData.map((d) => SectionModel.fromMap(d)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.showError(context, message: 'Error loading sections: $e');
      }
    }
  }

  Future<void> _loadClasses(String sectionId) async {
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(sectionId: int.tryParse(sectionId));
      setState(() {
        _classes = classesData.map((d) => ClassModel.fromMap(d)).toList();
        _selectedClassId = null;
        _selectedSubjectId = null;
        _subjects = [];
      });
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error loading classes: $e');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final subjectService = Provider.of<SubjectServiceApi>(context, listen: false);
      final subjectsData = await subjectService.getSubjects();
      setState(() {
        _subjects = subjectsData;
        _selectedSubjectId = null;
      });
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error loading subjects: $e');
    }
  }

  Future<void> _submitPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSectionId == null || _selectedClassId == null || _selectedSubjectId == null) {
      AppSnackbar.showError(context, message: 'Please select Section, Class, and Subject');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final lessonService = Provider.of<LessonPlanServiceApi>(context, listen: false);
      await lessonService.createLessonPlan({
        'section_id': int.parse(_selectedSectionId!),
        'class_id': int.parse(_selectedClassId!),
        'subject_id': int.parse(_selectedSubjectId!),
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'week_number': int.tryParse(_weekController.text) ?? 1,
      });

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Lesson plan submitted successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.showError(context, message: 'Error submitting plan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Create Lesson Plan',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Submit your weekly teaching plan',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),
                        _buildDropdown(
                          label: 'Section',
                          value: _selectedSectionId,
                          items: _sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.sectionName))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSectionId = val);
                            if (val != null) _loadClasses(val);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Class',
                          value: _selectedClassId,
                          items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedClassId = val);
                            _loadSubjects();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Subject',
                          value: _selectedSubjectId,
                          items: _subjects.map((s) => DropdownMenuItem(value: s.id.toString(), child: Text(s.name))).toList(),
                          onChanged: (val) => setState(() => _selectedSubjectId = val),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _weekController,
                          decoration: InputDecoration(
                            labelText: 'Week Number',
                            hintText: 'e.g., 1',
                            prefixIcon: const Icon(Icons.calendar_today_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Week number is required';
                            if (int.tryParse(val) == null) return 'Must be a valid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Lesson Title',
                            hintText: 'e.g., Introduction to Photosynthesis',
                            prefixIcon: const Icon(Icons.title_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            labelText: 'Lesson Content',
                            hintText: 'Objectives, activities, and materials...',
                            prefixIcon: const Icon(Icons.notes_rounded, size: 24),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          maxLines: 8,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Content is required' : null,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitPlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Submit Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: items,
        onChanged: onChanged,
        validator: (val) => val == null ? '$label is required' : null,
      ),
    );
  }
}
