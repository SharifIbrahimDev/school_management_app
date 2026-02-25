import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/attendance_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_indicator.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  /// If provided, history is pre-filtered to this class (teacher use-case).
  final int? preselectedClassId;
  final String? preselectedClassName;

  /// If provided, only sections with this id are shown (principal use-case).
  final int? preselectedSectionId;

  const AttendanceHistoryScreen({
    super.key,
    this.preselectedClassId,
    this.preselectedClassName,
    this.preselectedSectionId,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  // Filters
  int? _selectedClassId;
  String _selectedClassName = 'All Classes';
  int? _selectedSectionId;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  List<dynamic> _classes = [];

  // History data: list of { date, present, absent, total, records: [...] }
  List<Map<String, dynamic>> _historyByDay = [];

  bool _isLoadingFilters = true;
  bool _isLoadingHistory = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.preselectedClassId;
    _selectedClassName =
        widget.preselectedClassName ?? 'All Classes';
    _selectedSectionId = widget.preselectedSectionId;
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoadingFilters = true);
    try {
      final classService =
          Provider.of<ClassServiceApi>(context, listen: false);

      final classesRaw = await classService.getClasses(
        sectionId: _selectedSectionId,
      );

      if (mounted) {
        setState(() {
          _classes = classesRaw;
          _isLoadingFilters = false;
        });
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _error = null;
      _historyByDay = [];
    });

    try {
      final attendanceService = Provider.of<AttendanceServiceApi>(context, listen: false);

      final records = await attendanceService.getAttendanceHistory(
        classId: _selectedClassId,
        sectionId: _selectedSectionId,
        from: _fromDate,
        to: _toDate,
      );

      final Map<String, Map<String, dynamic>> dayMap = {};

      for (var r in records) {
        final dateStr = r['date']?.toString();
        if (dateStr == null) continue;
        
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        dayMap[dateKey] ??= {
          'date': DateTime(date.year, date.month, date.day),
          'present': 0,
          'absent': 0,
          'late': 0,
          'total': 0,
          'classBreakdown': {},
        };

        final status = (r['status'] ?? '').toString().toLowerCase();
        if (status == 'present') {
          dayMap[dateKey]!['present'] = (dayMap[dateKey]!['present'] as int) + 1;
        } else if (status == 'absent') {
          dayMap[dateKey]!['absent'] = (dayMap[dateKey]!['absent'] as int) + 1;
        } else if (status == 'late') {
          dayMap[dateKey]!['late'] = (dayMap[dateKey]!['late'] as int) + 1;
        }
        
        dayMap[dateKey]!['total'] = (dayMap[dateKey]!['total'] as int) + 1;

        // Group by class if showing multiple classes
        final className = r['class_name'] ?? 'Class ${r['class_id']}';
        final breakdown = dayMap[dateKey]!['classBreakdown'] as Map<String, dynamic>;
        
        breakdown[className] ??= {
          'present': 0,
          'absent': 0,
          'late': 0,
          'total': 0,
          'records': [],
        };

        if (status == 'present') {
          breakdown[className]['present']++;
        } else if (status == 'absent') {
          breakdown[className]['absent']++;
        } else if (status == 'late') {
          breakdown[className]['late']++;
        }
        
        breakdown[className]['total']++;
        (breakdown[className]['records'] as List).add(r);
      }

      // Sort by date descending
      final sortedDays = dayMap.values.toList()
        ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _historyByDay = sortedDays;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _error = 'Error loading history: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance History',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded,
                color: Colors.white),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: _isLoadingFilters
              ? const LoadingIndicator(message: 'Loading...')
              : Column(
                  children: [
                    _buildFilterBar(theme),
                    Expanded(child: _buildBody(theme)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.5,
        borderRadius: 20,
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded,
              size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedClassId != null
                  ? _selectedClassName
                  : 'All Classes',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.date_range_rounded,
              size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            '${DateFormat('d MMM').format(_fromDate)} – ${DateFormat('d MMM yy').format(_toDate)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showFilterSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoadingHistory) {
      return const LoadingIndicator(message: 'Loading attendance records...');
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_historyByDay.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy_rounded,
        title: 'No Records Found',
        message:
            'No attendance was recorded for the selected class and date range.',
        actionButtonText: 'Change Filters',
        onActionPressed: _showFilterSheet,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _historyByDay.length,
        itemBuilder: (context, index) {
          final day = _historyByDay[index];
          return _buildDayCard(theme, day);
        },
      ),
    );
  }

  Widget _buildDayCard(ThemeData theme, Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final present = day['present'] as int;
    final absent = day['absent'] as int;
    final late = day['late'] as int;
    final total = day['total'] as int;
    final breakdown =
        day['classBreakdown'] as Map<String, dynamic>;
    final rate = total > 0 ? (present / total * 100).round() : 0;

    final rateColor = rate >= 80
        ? AppTheme.neonEmerald
        : rate >= 60
            ? Colors.orange
            : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.4,
        borderRadius: 20,
        borderColor: rateColor.withValues(alpha: 0.2),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              // Date block
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(date),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(date).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(date),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _miniStat('P', present,
                            AppTheme.neonEmerald),
                        const SizedBox(width: 8),
                        _miniStat('A', absent, AppTheme.errorColor),
                        if (late > 0) ...[
                          const SizedBox(width: 8),
                          _miniStat('L', late, Colors.orange),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Rate badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$rate%',
                  style: TextStyle(
                    color: rateColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          // Drill-down breakdown
          children: breakdown.isEmpty
              ? [
                  Text('No detailed data',
                      style: theme.textTheme.bodySmall),
                ]
              : breakdown.entries.map((entry) {
                  final cls = entry.key;
                  final stats =
                      entry.value as Map<String, dynamic>;
                  final records =
                      (stats['records'] as List?) ?? [];
                  return _buildClassBreakdown(
                      theme, cls, stats, records);
                }).toList(),
        ),
      ),
    );
  }

  Widget _buildClassBreakdown(ThemeData theme, String className,
      Map<String, dynamic> stats, List records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.class_rounded,
                size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              className,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Spacer(),
            _miniStat('P', stats['present'] as int,
                AppTheme.neonEmerald),
            const SizedBox(width: 6),
            _miniStat(
                'A', stats['absent'] as int, AppTheme.errorColor),
          ],
        ),
        const SizedBox(height: 10),
        ...records.map<Widget>((r) {
          final status =
              (r['status'] ?? '').toString().toLowerCase();
          final isPresent = status == 'present';
          final isAbsent = status == 'absent';
          final dotColor = isPresent
              ? AppTheme.neonEmerald
              : isAbsent
                  ? AppTheme.errorColor
                  : Colors.orange;
          final name = r['student_name'] ??
              r['name'] ??
              'Student #${r['student_id']}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: dotColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _showFilterSheet() async {
    int? tempClassId = _selectedClassId;
    String tempClassName = _selectedClassName;
    DateTime tempFrom = _fromDate;
    DateTime tempTo = _toDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setBS) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                MediaQuery.of(ctx2).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filter Attendance History',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Class picker
                if (widget.preselectedClassId == null) ...[
                  const Text('Class',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: tempClassId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ..._classes.map((c) => DropdownMenuItem<int?>(
                            value: c['id'] as int,
                            child: Text(c['class_name'] ??
                                'Class ${c['id']}'),
                          )),
                    ],
                    onChanged: (v) {
                      setBS(() {
                        tempClassId = v;
                        tempClassName = v == null
                            ? 'All Classes'
                            : (_classes.firstWhere(
                                    (c) => c['id'] == v,
                                    orElse: () =>
                                        {'class_name': 'Class $v'})[
                                'class_name'] ??
                                'Class $v');
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Date range
                const Text('Date Range',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _datePickerTile(
                        ctx2,
                        label: 'From',
                        date: tempFrom,
                        onPicked: (d) =>
                            setBS(() => tempFrom = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _datePickerTile(
                        ctx2,
                        label: 'To',
                        date: tempTo,
                        onPicked: (d) => setBS(() => tempTo = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedClassId = tempClassId;
                        _selectedClassName = tempClassName;
                        _fromDate = tempFrom;
                        _toDate = tempTo;
                      });
                      Navigator.pop(ctx2);
                      _loadHistory();
                    },
                    child: const Text('Apply Filters',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _datePickerTile(
    BuildContext ctx, {
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                Text(
                  DateFormat('dd MMM yy').format(date),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
