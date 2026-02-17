import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/homework_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/section_service_api.dart'; // Added
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state_widget.dart'; // Added
import 'add_homework_screen.dart';
import '../../widgets/custom_app_bar.dart';

class TeacherHomeworkScreen extends StatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> {
  bool _isLoading = true;
  List<dynamic> _homeworkList = [];
  List<dynamic> _classes = [];
  List<dynamic> _sections = []; // Added
  int? _selectedClassId;
  int? _selectedSectionId; // Added

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classes = await classService.getClasses();
      
      setState(() {
        _classes = classes;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
        }
      });
      
      if (_selectedClassId != null) {
        await _loadSections(); // Load sections first
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading filters: $e')));
      }
    }
  }

  Future<void> _loadSections() async {
    if (_selectedClassId == null) return;
    
    // Don't show loading here to avoid screen flicker during filter change
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      // Fetch all active sections
      final allSections = await sectionService.getSections(isActive: true);
      // Filter by class_id
      final classSections = allSections.where((s) => s['class_id'].toString() == _selectedClassId.toString()).toList();
      
      if (mounted) {
        setState(() {
          _sections = classSections;
          _selectedSectionId = null; 
          if (_sections.isNotEmpty) {
             _selectedSectionId = _sections.first['id'];
          }
        });
        await _loadHomework(); // Then load homework
      }
    } catch (e) {
      if (mounted) {
         // Fallback
         await _loadHomework();
      }
    }
  }

  Future<void> _loadHomework() async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<HomeworkServiceApi>(context, listen: false);
      final data = await service.getHomework(
        classId: _selectedClassId,
        sectionId: _selectedSectionId,
      );
      if (mounted) {
        setState(() {
          _homeworkList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Don't show error snackbar on first load empty state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Manage Homework',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddHomeworkScreen()),
          ).then((_) => _loadHomework()); // Refresh on return
        },
        label: const Text('Assign Homework'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
          child: Column(
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: AppTheme.glassDecoration(
                     context: context, 
                     opacity: 0.6, 
                     borderRadius: 12,
                     borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                   ),
                   child: Column(
                     children: [
                       DropdownButton<int>(
                         value: _selectedClassId,
                         isExpanded: true,
                         underline: Container(),
                         hint: const Text('Select Class'),
                         items: _classes.map<DropdownMenuItem<int>>((c) {
                           return DropdownMenuItem(value: c['id'], child: Text(c['class_name'] ?? c['name'] ?? 'Class'));
                         }).toList(),
                         onChanged: (val) {
                           setState(() => _selectedClassId = val);
                           _loadSections();
                         },
                       ),
                       if (_sections.isNotEmpty) ...[
                         const Divider(height: 1),
                         DropdownButton<int>(
                           value: _selectedSectionId,
                           isExpanded: true,
                           underline: Container(),
                           hint: const Text('Select Section'),
                           items: _sections.map<DropdownMenuItem<int>>((s) {
                             return DropdownMenuItem(value: s['id'], child: Text(s['section_name'] ?? s['name'] ?? 'Section'));
                           }).toList(),
                           onChanged: (val) {
                             setState(() => _selectedSectionId = val);
                             _loadHomework();
                           },
                         ),
                       ],
                     ],
                   ),
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: LoadingIndicator())
                    : _homeworkList.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.menu_book,
                            title: 'No Homework Found',
                            message: 'Assign homework using the button below.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _homeworkList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final hw = _homeworkList[index];
                              final dueDate = DateTime.parse(hw['due_date']);
                              return Container(
                                decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 16),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.assignment, color: AppTheme.primaryColor),
                                  ),
                                  title: Text(hw['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(hw['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Due: ${DateFormat('MMM d, y').format(dueDate)}',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      // TODO: Implement delete
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
