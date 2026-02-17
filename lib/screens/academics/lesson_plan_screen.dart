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
import 'add_lesson_plan_screen.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';

class LessonPlanScreen extends StatefulWidget {
  const LessonPlanScreen({super.key});

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen> {
  String? _selectedSectionId;
  String? _selectedClassId;
  String? _selectedSubjectId;
  
  List<SectionModel> _sections = [];
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<dynamic> _lessonPlans = [];
  bool _isPrincipal = false;
  
  bool _isLoading = true;
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final authService = Provider.of<AuthServiceApi>(context, listen: false);

      final sectionsData = await sectionService.getSections(isActive: true);
      _sections = sectionsData.map((d) => SectionModel.fromMap(d)).toList();

      final user = await authService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _isPrincipal = user['role'] == 'principal' || user['role'] == 'admin';
        });
      }

      if (_sections.isNotEmpty) {
        _selectedSectionId = _sections.first.id;
        await _loadClasses(_selectedSectionId!);
      }
    } catch (e) {
      debugPrint('Error loading sections: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClasses(String sectionId) async {
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(sectionId: int.tryParse(sectionId));
      setState(() {
        _classes = classesData.map((d) => ClassModel.fromMap(d)).toList();
        _selectedClassId = _classes.isNotEmpty ? _classes.first.id : null;
      });
      if (_selectedClassId != null) {
        await _loadSubjects();
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final subjectService = Provider.of<SubjectServiceApi>(context, listen: false);
      final subjectsData = await subjectService.getSubjects();
      setState(() {
        _subjects = subjectsData;
        _selectedSubjectId = _subjects.isNotEmpty ? _subjects.first.id.toString() : null;
      });
      if (_selectedSubjectId != null) {
        await _loadLessonPlans();
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  Future<void> _loadLessonPlans() async {
    if (_selectedSectionId == null || _selectedClassId == null || _selectedSubjectId == null) return;
    
    setState(() => _isFiltering = true);
    try {
      final lessonService = Provider.of<LessonPlanServiceApi>(context, listen: false);
      _lessonPlans = await lessonService.getLessonPlans(
        sectionId: int.parse(_selectedSectionId!),
        classId: int.parse(_selectedClassId!),
        subjectId: int.parse(_selectedSubjectId!),
      );
    } catch (e) {
      debugPrint('Error loading lesson plans: $e');
    } finally {
      if (mounted) setState(() => _isFiltering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Lesson Plans',
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _loadLessonPlans),
        ],
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
            : Column(
                children: [
                  _buildFilters(theme),
                  Expanded(
                    child: _isFiltering 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPlanList(theme),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddLessonPlanScreen()),
          );
          if (result == true) _loadLessonPlans();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Plan', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSectionId,
                  decoration: const InputDecoration(labelText: 'Section', isDense: true),
                  items: _sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.sectionName))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedSectionId = v);
                    if (v != null) _loadClasses(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(labelText: 'Class', isDense: true),
                  items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedClassId = v);
                    _loadLessonPlans();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSubjectId,
            decoration: const InputDecoration(labelText: 'Subject', isDense: true),
            items: _subjects.map((s) => DropdownMenuItem(value: s.id.toString(), child: Text(s.name))).toList(),
            onChanged: (v) {
              setState(() => _selectedSubjectId = v);
              _loadLessonPlans();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(ThemeData theme) {
    if (_lessonPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No lesson plans found for this selection.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lessonPlans.length,
      itemBuilder: (context, index) {
        final plan = _lessonPlans[index];
        final teacherName = plan['teacher']?['name'] ?? 'Unknown Teacher';
        final status = plan['status'] ?? 'submitted';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
            ),
            title: Text(plan['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Text('Week ${plan['week_number']} | $teacherName', style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'approved' ? Colors.green.withValues(alpha: 0.1) 
                           : status == 'rejected' ? Colors.red.withValues(alpha: 0.1)
                           : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      color: status == 'approved' ? Colors.green
                             : status == 'rejected' ? Colors.red
                             : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  plan['content'] ?? 'No content provided.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (_isPrincipal && status == 'submitted') ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _updateStatus(plan['id'], 'rejected'),
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _updateStatus(plan['id'], 'approved'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      final lessonService = Provider.of<LessonPlanServiceApi>(context, listen: false);
      await lessonService.updateLessonPlan(id, {'status': status});
      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Plan marked as $status');
        _loadLessonPlans();
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error updating status: $e');
    }
  }
}
