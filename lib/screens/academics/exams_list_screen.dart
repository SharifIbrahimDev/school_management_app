import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/exam_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/subject_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/models/class_model.dart';
import '../../core/models/subject_model.dart';
import 'add_exam_screen.dart';
import 'exam_result_screen.dart';
import '../../widgets/custom_app_bar.dart';

class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  List<ClassModel> _classes = [];
  List<dynamic> _sections = [];
  List<SubjectModel> _subjects = [];
  List<dynamic> _exams = [];

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
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses();
      if (!mounted) return;
      _classes = classesData.map((d) => ClassModel.fromMap(d)).toList();

      final subjectService = Provider.of<SubjectServiceApi>(context, listen: false);
      final subjectsData = await subjectService.getSubjects();
      _subjects = subjectsData;
      
      if (_classes.isNotEmpty) {
        _selectedClassId = _classes.first.id;
        await _loadSections();
      }
      
      if (_subjects.isNotEmpty) {
        _selectedSubjectId = _subjects.first.id.toString();
      }

      if (_selectedClassId != null && _selectedSubjectId != null) {
        await _loadExams();
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSections() async {
    if (_selectedClassId == null) return;
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final allSections = await sectionService.getSections(isActive: true);
      final classSections = allSections.where((s) => s['class_id'].toString() == _selectedClassId).toList();
      
      setState(() {
        _sections = classSections;
        if (_sections.isNotEmpty) {
           _selectedSectionId = _sections.first['id'].toString();
        } else {
           _selectedSectionId = null;
        }
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  Future<void> _loadExams() async {
    if (_selectedClassId == null || _selectedSubjectId == null) return;
    
    setState(() => _isFiltering = true);
    try {
      final examService = Provider.of<ExamServiceApi>(context, listen: false);
      _exams = await examService.getExams(
        classId: int.parse(_selectedClassId!),
        subjectId: int.parse(_selectedSubjectId!),
      );
    } catch (e) {
      debugPrint('Error loading exams: $e');
    } finally {
      if (mounted) setState(() => _isFiltering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Exams',
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _loadExams),
        ],
      ),
      body: Container(
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilters(),
                  Expanded(
                    child: _isFiltering 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildExamList(),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExamScreen()),
          );
          if (result == true) {
             _loadInitialData();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Exam', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilters() {
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
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(labelText: 'Class', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedClassId = v);
                    _loadSections().then((_) => _loadExams());
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                   initialValue: _selectedSectionId,
                   decoration: const InputDecoration(labelText: 'Section', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                   items: _sections.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text(s['section_name'] ?? 'Section', overflow: TextOverflow.ellipsis))).toList(),
                   onChanged: (v) {
                     setState(() => _selectedSectionId = v);
                   },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedSubjectId,
            decoration: const InputDecoration(labelText: 'Subject', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            items: _subjects.map((s) => DropdownMenuItem(value: s.id.toString(), child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              setState(() => _selectedSubjectId = v);
              _loadExams();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamList() {
    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No exams found for this class/subject.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddExamScreen()),
                  );
                  if (!mounted) return;
                  if (result == true) _loadInitialData();
              }, 
              child: const Text('Create New Exam')
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        final date = DateTime.tryParse(exam['date']) ?? DateTime.now();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamResultScreen(
                    examId: exam['id'],
                    classId: int.parse(_selectedClassId!),
                    sectionId: _selectedSectionId != null ? int.parse(_selectedSectionId!) : null,
                    examTitle: exam['title'],
                  ),
                ),
              );
            },
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.grade_rounded, color: AppTheme.primaryColor),
            ),
            title: Text(exam['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                     Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                     const SizedBox(width: 4),
                     Text(DateFormat('MMM dd, yyyy').format(date), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Max Score: ${exam['max_score']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
        );
      },
    );
  }
}
