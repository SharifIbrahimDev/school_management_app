import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/homework_service_api.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';

class ParentHomeworkScreen extends StatefulWidget {
  final int classId;
  final int sectionId;
  final String studentName;

  const ParentHomeworkScreen({
    super.key,
    required this.classId,
    required this.sectionId,
    required this.studentName,
  });

  @override
  State<ParentHomeworkScreen> createState() => _ParentHomeworkScreenState();
}

class _ParentHomeworkScreenState extends State<ParentHomeworkScreen> {
  bool _isLoading = true;
  List<dynamic> _homeworkList = [];

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    try {
      final service = Provider.of<HomeworkServiceApi>(context, listen: false);
      final data = await service.getHomework(
        classId: widget.classId,
        sectionId: widget.sectionId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading homework: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.studentName}\'s Homework',
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
        child: SafeArea( // Added SafeArea
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _homeworkList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('No homework assigned yet!', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _homeworkList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final hw = _homeworkList[index];
                        final dueDate = DateTime.parse(hw['due_date']);
                        final isOverdue = DateTime.now().isAfter(dueDate) && !DateUtils.isSameDay(DateTime.now(), dueDate);
          
                        return Container(
                          decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 16),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor),
                            ),
                            title: Text(hw['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Subject: ${hw['subject']?['name'] ?? 'General'} • Due: ${DateFormat('MMM d').format(dueDate)}',
                              style: TextStyle(
                                color: isOverdue ? Colors.red : Colors.grey[700],
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.all(16),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(hw['description']),
                              ),
                              if (hw['attachment_url'] != null) ...[ // Fixed syntax
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // Handle attachment download/view
                                  },
                                  icon: const Icon(Icons.attachment, size: 18),
                                  label: const Text('View Attachment'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
