import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/syllabus_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/subject_service_api.dart';
import '../../core/models/section_model.dart';
import '../../core/models/class_model.dart';
import '../../core/models/subject_model.dart';
import 'add_syllabus_topic_screen.dart';
import '../../widgets/custom_app_bar.dart';

class SyllabusProgressScreen extends StatefulWidget {
  const SyllabusProgressScreen({super.key});

  @override
  State<SyllabusProgressScreen> createState() => _SyllabusProgressScreenState();
}

class _SyllabusProgressScreenState extends State<SyllabusProgressScreen> {
  String? _selectedSectionId;
  String? _selectedClassId;
  String? _selectedSubjectId;
  
  List<SectionModel> _sections = [];
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<dynamic> _syllabusTopics = [];
  
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
      final sectionsData = await sectionService.getSections(isActive: true);
      _sections = sectionsData.map((d) => SectionModel.fromMap(d)).toList();

      if (_sections.isNotEmpty) {
        _selectedSectionId = _sections.first.id.toString();
        await _loadClasses(_selectedSectionId!);
      }
    } catch (e) {
      debugPrint('Error loading sections: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClasses(String sectionId) async {
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(sectionId: int.tryParse(sectionId));
      setState(() {
        _classes = classesData.map((d) => ClassModel.fromMap(d)).toList();
        _selectedClassId = _classes.isNotEmpty ? _classes.first.id.toString() : null;
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
        await _loadSyllabus();
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  Future<void> _loadSyllabus() async {
    if (_selectedSectionId == null || _selectedClassId == null || _selectedSubjectId == null) return;
    
    setState(() => _isFiltering = true);
    try {
      final syllabusService = Provider.of<SyllabusServiceApi>(context, listen: false);
      _syllabusTopics = await syllabusService.getSyllabuses(
        sectionId: int.parse(_selectedSectionId!),
        classId: int.parse(_selectedClassId!),
        subjectId: int.parse(_selectedSubjectId!),
      );
    } catch (e) {
      debugPrint('Error loading syllabus: $e');
    } finally {
      setState(() => _isFiltering = false);
    }
  }

  Future<void> _toggleStatus(int id, String currentStatus) async {
    final nextStatus = currentStatus == 'completed' ? 'pending' : 'completed';
    try {
      final syllabusService = Provider.of<SyllabusServiceApi>(context, listen: false);
      await syllabusService.updateSyllabus(id, {
        'status': nextStatus,
        'completion_date': nextStatus == 'completed' ? DateTime.now().toIso8601String() : null,
      });
      await _loadSyllabus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = _syllabusTopics.where((t) => t['status'] == 'completed').length;
    final progress = _syllabusTopics.isEmpty ? 0.0 : completedCount / _syllabusTopics.length;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Syllabus Tracker',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadSyllabus,
          ),
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
                  _buildProgressOverview(theme, progress, completedCount),
                  Expanded(
                    child: _isFiltering 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTopicList(theme),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSyllabusTopicScreen()),
          );
          if (result == true) _loadSyllabus();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Topic', style: TextStyle(color: Colors.white)),
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
                    _loadSyllabus();
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
              _loadSyllabus();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(ThemeData theme, double progress, int completed) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Curriculum Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('$completed / ${_syllabusTopics.length} Topics Completed', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicList(ThemeData theme) {
    if (_syllabusTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No syllabus topics found for this selection.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _syllabusTopics.length,
      itemBuilder: (context, index) {
        final topic = _syllabusTopics[index];
        final isCompleted = topic['status'] == 'completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.1),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(topic['topic'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(topic['description'] ?? 'No description provided', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Checkbox(
              value: isCompleted,
              onChanged: (_) => _toggleStatus(topic['id'], topic['status']),
              activeColor: AppTheme.primaryColor,
            ),
          ),
        );
      },
    );
  }
}
