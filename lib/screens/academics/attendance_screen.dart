import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/attendance_service_api.dart';
import '../../core/services/notification_service.dart' as fcm_service;
import '../../core/services/student_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/responsive_widgets.dart';
import '../../widgets/app_snackbar.dart';
import 'attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedClassId;
  int? _selectedSectionId;
  
  bool _isLoading = false;
  
  List<dynamic> _classes = [];
  List<dynamic> _sections = [];
  List<dynamic> _students = [];
  
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classes = await classService.getClasses();
      
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
        
        // Auto-select first class if available
        if (_classes.isNotEmpty) {
          setState(() => _selectedClassId = _classes.first['id']);
          _loadSections();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  Future<void> _loadSections() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final allSections = await sectionService.getSections(isActive: true);
      final classSections = allSections.where((s) => s['class_id'].toString() == _selectedClassId.toString()).toList();

      if (mounted) {
        setState(() {
          _sections = classSections;
          _selectedSectionId = null;
        });
        
        if (_sections.isNotEmpty) {
          setState(() => _selectedSectionId = _sections.first['id']);
          _loadAttendanceData();
        } else {
           // No sections found for class, maybe try loading purely by class (if allowed)
           _loadAttendanceData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback: try loading data without sections
        _loadAttendanceData();
      }
    }
  }

  Future<void> _loadAttendanceData() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final attendanceService = Provider.of<AttendanceServiceApi>(context, listen: false);

      // 1. Fetch Students
      // If we have a section, filter by it. Else filter by class.
      List<dynamic> students = [];
      if (_selectedSectionId != null) {
        students = await studentService.getStudents(sectionId: _selectedSectionId);
      } else {
        students = await studentService.getStudents(classId: _selectedClassId);
      }
      
      // 2. Fetch Existing Attendance
      List<dynamic> existingAttendance = [];
      try {
        existingAttendance = await attendanceService.getAttendance(
          classId: _selectedClassId!,
          sectionId: _selectedSectionId,
          date: _selectedDate,
        );
      } catch (e) {
        // Ignore 404 or empty
      }

      if (!mounted) return;

      // 3. Merge
      _students = students.map((student) {
        final record = existingAttendance.firstWhere(
          (a) => a['student_id'] == student['id'],
          orElse: () => null,
        );
        return {
          'id': student['id'], 
          'student_id': student['id'],
          'name': student['student_name'] ?? student['name'] ?? 'Unknown',
          'admission_number': student['admission_number'] ?? 'N/A',
          'status': record != null ? record['status'] : 'present',
          'remark': record != null ? record['remark'] : '',
        };
      }).toList();

      setState(() {
        _isLoading = false;
        _isDirty = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null) return;

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<AttendanceServiceApi>(context, listen: false);
      final payload = _students.map((s) => {
        'student_id': s['student_id'],
        'status': s['status'],
        'remark': s['remark'],
      }).toList();

      await service.saveAttendance(
        classId: _selectedClassId!,
        sectionId: _selectedSectionId,
        date: _selectedDate,
        attendances: payload,
      );

      // Trigger notifications for absentees
      int notificationCount = 0;
      for (var s in _students) {
         if (s['status'] == 'absent') {
            fcm_service.NotificationService.sendAttendanceNotification(
                parentId: s['student_id'].toString(), 
                studentName: s['name'] ?? 'Student',
                status: 'absent'
            );
            notificationCount++;
         }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDirty = false;
        });
        AppSnackbar.showSuccess(context, message: 'Attendance saved! $notificationCount notifications sent.');
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
        title: 'Daily Attendance',
        actions: [
          // History button
          IconButton(
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceHistoryScreen(
                    preselectedClassId: _selectedClassId,
                    preselectedClassName: _selectedClassId == null
                        ? null
                        : (_classes.firstWhere(
                              (c) => c['id'] == _selectedClassId,
                              orElse: () => {'class_name': 'Class'},
                            )['class_name'] ??
                            'Class'),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: (_isDirty && !_isLoading) ? _saveAttendance : null,
            icon: Icon(
              Icons.save_rounded, 
              color: (_isDirty && !_isLoading) ? Colors.white : Colors.white.withValues(alpha: 0.5)
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
          child: AppTheme.constrainedContent(
            context: context,
            child: Column(
              children: [
                // Filters
                Padding(
                  padding: AppTheme.responsivePadding(context),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: AppTheme.glassDecoration(
                      context: context,
                      opacity: 0.6,
                      borderRadius: 24,
                      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                     child: Column(
                      children: [
                        ResponsiveRowColumn(
                          rowOnMobile: false,
                          rowOnTablet: true,
                          rowOnDesktop: true,
                          children: [
                            if (!context.isMobile)
                              Expanded(
                                flex: 1,
                                child: _buildFilterChip(
                                  context,
                                  label: _selectedClassId == null 
                                    ? 'Select Class' 
                                    : _classes.firstWhere((c) => c['id'] == _selectedClassId, orElse: () => {'name': 'Class'})['class_name'] ?? 'Class',
                                  icon: Icons.school_rounded,
                                  onTap: () => _showFilterDialog('class'),
                                ),
                              )
                            else
                              _buildFilterChip(
                                context,
                                label: _selectedClassId == null 
                                  ? 'Select Class' 
                                  : _classes.firstWhere((c) => c['id'] == _selectedClassId, orElse: () => {'name': 'Class'})['class_name'] ?? 'Class',
                                icon: Icons.school_rounded,
                                onTap: () => _showFilterDialog('class'),
                              ),
                            if (context.isMobile) const SizedBox(height: 12),
                            if (!context.isMobile) const SizedBox(width: 16),
                            if (!context.isMobile)
                              Expanded(
                                flex: 1,
                                child: _buildFilterChip(
                                  context,
                                  label: DateFormat('dd MMM, yyyy').format(_selectedDate),
                                  icon: Icons.calendar_today_rounded,
                                  onTap: () => _showDatePicker(),
                                ),
                              )
                            else
                              _buildFilterChip(
                                context,
                                label: DateFormat('dd MMM, yyyy').format(_selectedDate),
                                icon: Icons.calendar_today_rounded,
                                onTap: () => _showDatePicker(),
                              ),
                          ],
                        ),
                        if (_sections.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildFilterChip(
                            context,
                            label: _selectedSectionId == null 
                              ? 'Select Section' 
                              : _sections.firstWhere((s) => s['id'] == _selectedSectionId, orElse: () => {'name': 'Section'})['section_name'] ?? 'Section',
                            icon: Icons.grid_view_rounded,
                            onTap: () => _showFilterDialog('section'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                for (var s in _students) {
                                  s['status'] = 'present';
                                }
                                _isDirty = true;
                              });
                            },
                            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                            label: const Text('Mark All Present', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColorDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
  
                // List / Grid
                Expanded(
                  child: _isLoading
                      ? const LoadingIndicator(size: 50)
                      : _students.isEmpty
                          ? const EmptyStateWidget(
                              icon: Icons.people_outline,
                              title: 'No Students',
                              message: 'Select a class and section to mark attendance',
                            )
                          : ListView.builder(
                              padding: AppTheme.responsivePadding(context).copyWith(top: 0),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final isPresent = student['status'] == 'present';
                                final isAbsent = student['status'] == 'absent';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: AppTheme.glassDecoration(
                                    context: context,
                                    opacity: 0.6,
                                    borderRadius: 16,
                                    hasGlow: isPresent,
                                    borderColor: isPresent
                                      ? AppTheme.neonEmerald.withValues(alpha: 0.3)
                                      : isAbsent
                                        ? AppTheme.errorColor.withValues(alpha: 0.3)
                                        : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        child: Text(
                                          student['name'].isNotEmpty ? student['name'][0] : '?',
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['name'],
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'ID: ${student['admission_number'] ?? 'N/A'}',
                                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Attendance Buttons
                                      _buildAttendanceButton(
                                        icon: Icons.check_circle_rounded,
                                        label: 'P',
                                        isSelected: isPresent,
                                        activeColor: AppTheme.neonEmerald,
                                        onTap: () => _updateStatus(index, 'present'),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildAttendanceButton(
                                        icon: Icons.cancel_rounded,
                                        label: 'A',
                                        isSelected: isAbsent,
                                        activeColor: AppTheme.errorColor,
                                        onTap: () => _updateStatus(index, 'absent'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateStatus(int index, String status) {
    setState(() {
      _students[index]['status'] = status;
      _isDirty = true;
    });
  }

  Widget _buildFilterChip(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.3,
          borderRadius: 16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              isSelected ? label : '', // Text only when selected? No, mockup shows both options as buttons.
              style: TextStyle(
                color: activeColor,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAttendanceData();
    }
  }

  void _showFilterDialog(String type) {
    // Show a modern bottom sheet or simple dialog for selection
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final List<dynamic> items = type == 'class' ? _classes : _sections;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select ${type.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ...items.map((item) {
                return ListTile(
                  title: Text(item['class_name'] ?? item['section_name'] ?? item['name']),
                  onTap: () {
                    setState(() {
                      if (type == 'class') {
                        _selectedClassId = item['id'];
                        _loadSections();
                      } else {
                        _selectedSectionId = item['id'];
                        _loadAttendanceData();
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
