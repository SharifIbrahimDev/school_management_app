import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/services/exam_service_api.dart';
import '../../core/services/student_service_api.dart'; // To get students list
import '../../core/services/notification_service_api.dart';
import 'bulk_result_upload_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state_widget.dart';
import '../../core/utils/error_handler.dart';

class ExamResultScreen extends StatefulWidget {
  final int examId;
  final int classId;
  final int? sectionId;
  final String examTitle;

  const ExamResultScreen({
    super.key,
    required this.examId,
    required this.classId,
    this.sectionId,
    required this.examTitle,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  bool _isLoading = true;
  List<dynamic> _students = []; // Merged student + result data
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch students in class (and optional section)
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final students = await studentService.getStudents(
        classId: widget.classId, 
        sectionId: widget.sectionId
      );
      if (!mounted) return;

      // 2. Fetch existing results
      final examService = Provider.of<ExamServiceApi>(context, listen: false);
      final results = await examService.getResults(widget.examId);
      if (!mounted) return;

      // 3. Merge
      _students = students.map((s) {
        final result = results.firstWhere(
          (r) => r['student_id'].toString() == s['id']?.toString(),
          orElse: () => null,
        );
        return {
          'id': s['id'],
          'user_id': s['user_id'],
          'name': s['student_name'] ?? s['name'] ?? 'Unknown',
          'admission_number': s['admission_number'] ?? '-',
          'score': result != null ? result['score'].toString() : '',
          'remark': result != null ? result['remark'] ?? '' : '',
        };
      }).toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  Future<void> _saveResults() async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<ExamServiceApi>(context, listen: false);
      
      // Filter out empty scores or modified ones
      final payload = _students.where((s) => s['score'].toString().isNotEmpty).map((s) {
        return {
          'student_id': s['id'],
          'score': double.tryParse(s['score'].toString()) ?? 0.0,
          'remark': s['remark'] ?? '',
        };
      }).toList();

      if (payload.isEmpty) {
        AppSnackbar.showWarning(context, message: 'No scores to save');
        setState(() => _isLoading = false);
        return;
      }

      await service.saveResults(widget.examId, payload);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDirty = false;
        });
        AppSnackbar.showSuccess(
          context, 
          message: 'Results saved successfully',
          actionLabel: 'NOTIFY',
          onActionPressed: _showNotifyDialog,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Grading: ${widget.examTitle}',
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
            tooltip: 'Bulk Upload CSV',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BulkResultUploadScreen(
                    examId: widget.examId,
                    classId: widget.classId,
                    sectionId: widget.sectionId,
                    examTitle: widget.examTitle,
                  ),
                ),
              );
              if (result == true) _loadData();
            },
          ),
          if (_isDirty)
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _isLoading ? null : _saveResults,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          const SizedBox(width: 8),
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
              ? const Center(child: LoadingIndicator(message: 'Loading candidate records...'))
              : _students.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.people_outline,
                      title: 'No Students Found',
                      message: 'No students are assigned to this class or section.',
                      actionButtonText: 'Refresh',
                      onActionPressed: _loadData,
                    )
                  : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Container(
                      decoration: AppTheme.glassDecoration(
                        context: context,
                        opacity: 0.6,
                        borderRadius: 16,
                        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(student['admission_number'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(height: 12),
                                  // Remark Field
                                  Container(
                                    decoration: AppTheme.glassDecoration(
                                      context: context,
                                      opacity: 0.2,
                                      borderRadius: 8,
                                      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                                    ),
                                    child: TextFormField(
                                      initialValue: student['remark'],
                                      decoration: const InputDecoration(
                                        hintText: 'Add remark...',
                                        hintStyle: TextStyle(fontSize: 12),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onChanged: (val) {
                                        _students[index]['remark'] = val;
                                        _isDirty = true;
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: Column(
                                children: [
                                  const Text('Score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: AppTheme.glassDecoration(
                                      context: context,
                                      opacity: 0.3,
                                      borderRadius: 12,
                                      borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                    ),
                                    child: TextFormField(
                                      initialValue: student['score'],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                        isDense: true,
                                      ),
                                      onChanged: (val) {
                                        _students[index]['score'] = val;
                                        _isDirty = true;
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showNotifyDialog() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Notify Parents/Students?',
      content: 'Send a push notification to ${_students.length} students about these results? This will also notify their parents.',
      confirmText: 'Send Notifications',
      confirmColor: AppTheme.primaryColor,
      icon: Icons.notifications_active_rounded,
    );

    if (confirmed == true) {
      _sendNotifications();
    }
  }

  Future<void> _sendNotifications() async {
    final userIds = _students
        .where((s) => s['user_id'] != null)
        .map((s) => s['user_id'] as int)
        .toList();

    if (userIds.isEmpty) {
      AppSnackbar.showWarning(context, message: 'No linked users found to notify');
      return;
    }

    try {
      final notificationService = Provider.of<NotificationServiceApi>(context, listen: false);
      await notificationService.broadcastNotification(
        userIds: userIds,
        type: 'exam_result',
        title: 'New Exam Results: ${widget.examTitle}',
        message: 'Results for ${widget.examTitle} have been published. Check your report card.',
        data: {'exam_id': widget.examId, 'type': 'result'},
      );
      if (mounted) {
         AppSnackbar.showSuccess(context, message: 'Notifications sent successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }
}
