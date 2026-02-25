import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/attendance_service_api.dart';
import '../../../core/services/student_service_api.dart';
import '../../../core/utils/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_display_widget.dart';
import '../../../widgets/notification_badge.dart';
import '../../../widgets/skeleton_loader.dart';

class ParentAttendanceScreen extends StatefulWidget {
  final String parentId;
  final String schoolId;

  const ParentAttendanceScreen({
    super.key,
    required this.parentId,
    required this.schoolId,
  });

  @override
  State<ParentAttendanceScreen> createState() =>
      _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState
    extends State<ParentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<StudentModel> _students = [];

  // Summary stats per student id
  final Map<String, Map<String, dynamic>> _summaryMap = {};

  // Detailed history per student id
  final Map<String, List<dynamic>> _historyMap = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    if (_students.isNotEmpty) _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentService =
          Provider.of<StudentServiceApi>(context, listen: false);
      final attendanceService =
          Provider.of<AttendanceServiceApi>(context, listen: false);

      final studentsData = await studentService.getStudents(
        parentId: int.tryParse(widget.parentId),
      );
      _students =
          studentsData.map((data) => StudentModel.fromMap(data)).toList();

      _tabController = TabController(
          length: _students.length, vsync: this);

      // Fetch summary + history for every child in parallel
      final futures = _students.map((student) async {
        final sId = int.tryParse(student.id);
        if (sId == null) return;

        // Summary
        final summary =
            await attendanceService.getStudentAttendanceSummary(sId);
        _summaryMap[student.id] = {
          'percentage':
              (summary['percentage'] as num?)?.toDouble() ?? 0.0,
          'present': summary['present'] ?? 0,
          'total': summary['total'] ?? 0,
        };

        // Detailed history (last 3 months)
        final history =
            await attendanceService.getStudentAttendanceHistory(
          sId,
          from: DateTime.now().subtract(const Duration(days: 90)),
          to: DateTime.now(),
        );
        // Sort descending by date
        history.sort((a, b) {
          final da = DateTime.tryParse(
                  a['date']?.toString() ?? '') ??
              DateTime(2000);
          final db = DateTime.tryParse(
                  b['date']?.toString() ?? '') ??
              DateTime(2000);
          return db.compareTo(da);
        });
        _historyMap[student.id] = history;
      });

      await Future.wait(futures);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Attendance Tracking',
        actions: [NotificationBadge()],
      ),
      body: Container(
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? ErrorDisplayWidget(
                      error: _errorMessage!, onRetry: _loadData)
                  : _students.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: 'No Children Found',
                          message:
                              'No student records are linked to your account.',
                        )
                      : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tab bar (one tab per child)
        if (_students.length > 1)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: AppTheme.glassDecoration(
              context: context,
              opacity: 0.4,
              borderRadius: 16,
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: _students.length > 2,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: _students
                  .map((s) => Tab(
                        text: s.fullName.split(' ').first,
                      ))
                  .toList(),
            ),
          ),
        Expanded(
          child: _students.length > 1
              ? TabBarView(
                  controller: _tabController,
                  children: _students
                      .map((s) => _buildStudentPage(s))
                      .toList(),
                )
              : _buildStudentPage(_students.first),
        ),
      ],
    );
  }

  Widget _buildStudentPage(StudentModel student) {
    final summary = _summaryMap[student.id] ?? {};
    final percentage =
        (summary['percentage'] as double?) ?? 0.0;
    final present = summary['present'] ?? 0;
    final total = summary['total'] ?? 0;
    final absent = total - present;
    final history = _historyMap[student.id] ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Summary card ──────────────────────────────
          _buildSummaryCard(
              student, percentage, present, absent, total),

          const SizedBox(height: 24),

          // ── Daily History ─────────────────────────────
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Attendance Log',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Last 90 days',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(
                context: context,
                opacity: 0.3,
                borderRadius: 16,
              ),
              child: const Center(
                child: Text(
                  'No attendance records found for this period.',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...history.map((record) =>
                _buildHistoryRow(record)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(StudentModel student,
      double percentage, int present, int absent, int total) {
    final rateColor = percentage >= 80
        ? AppTheme.neonEmerald
        : percentage >= 60
            ? Colors.orange
            : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 28,
        hasGlow: percentage > 75,
        borderColor: rateColor.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          // Student name row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  student.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      student.prettyId ?? 'ID: ${student.id}',
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Big percentage pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    color: rateColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor:
                  rateColor.withValues(alpha: 0.1),
              color: rateColor,
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statChip(
                  'Present', present, AppTheme.neonEmerald),
              _statChip('Absent', absent, AppTheme.errorColor),
              _statChip('Total', total, AppTheme.neonBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(Map<dynamic, dynamic> record) {
    final rawDate = record['date']?.toString() ?? '';
    final date = DateTime.tryParse(rawDate);
    final status =
        (record['status'] ?? '').toString().toLowerCase();
    final isPresent = status == 'present';
    final isLate = status == 'late';
    final dotColor = isPresent
        ? AppTheme.neonEmerald
        : isLate
            ? Colors.orange
            : AppTheme.errorColor;
    final label = isPresent
        ? 'Present'
        : isLate
            ? 'Late'
            : 'Absent';
    final remark = record['remark']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.35,
        borderRadius: 14,
        borderColor: dotColor.withValues(alpha: 0.15),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date != null
                      ? DateFormat('EEEE, d MMMM yyyy')
                          .format(date)
                      : rawDate,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (remark.isNotEmpty)
                  Text(
                    remark,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor),
                  ),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: dotColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) =>
          const DashboardCardSkeletonLoader(),
    );
  }
}
