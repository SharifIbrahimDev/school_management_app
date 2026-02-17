import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/section_model.dart';
import '../core/models/student_model.dart';
import '../core/services/section_service_api.dart';
import '../core/services/student_service_api.dart';
import '../core/services/fee_service_api.dart';
import '../core/services/session_service_api.dart';
import '../core/utils/formatters.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/responsive_utils.dart';
import 'loading_indicator.dart';
import '../screens/fees/parent_fee_screen.dart';
import 'analytics_charts.dart';
import '../core/services/attendance_service_api.dart';
import 'responsive_widgets.dart';


class ParentDashboardWidget extends StatefulWidget {
  final String parentId;
  final String schoolId;

  const ParentDashboardWidget({
    super.key,
    required this.parentId,
    required this.schoolId,
  });

  @override
  State<ParentDashboardWidget> createState() => _ParentDashboardWidgetState();
}

class _ParentDashboardWidgetState extends State<ParentDashboardWidget> {
  SectionModel? selectedSection;
  List<StudentModel> _students = [];
  List<SectionModel> _sections = [];


  Map<int, Map<String, dynamic>> _studentStats = {};
  Map<String, double> _studentBalances = {};
  double _totalGlobalOutstanding = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);

      // Get students for this parent using server-side filtering
      final studentsData = await studentService.getStudents(
        parentId: int.tryParse(widget.parentId),
      );
      _students = studentsData
          .map((data) => StudentModel.fromMap(data))
          .toList();

      if (_students.isNotEmpty) {
        // Get unique section IDs from all students' assigned sections
        final sectionIds = _students
            .expand((s) => s.sectionIds)
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toSet()
            .toList();
        
        // Get sections
        final sectionsData = await sectionService.getSections(isActive: true);
        _sections = sectionsData
            .map((data) => SectionModel.fromMap(data))
            .where((s) => sectionIds.contains(int.tryParse(s.id)))
            .toList();

        if (_sections.isNotEmpty) {
          selectedSection = _sections.first;
          
          // Get active session and fees
          try {
            final sessionsData = await sessionService.getSessions(
              sectionId: int.tryParse(selectedSection!.id),
              isActive: true,
            );
            
            if (sessionsData.isNotEmpty) {
              // Session logic if needed
            }
          } catch (e) {
            debugPrint('Error loading sessions: $e');
          }
        }
      }

      // Fetch stats for all students
      final attendanceService = Provider.of<AttendanceServiceApi>(context, listen: false);

      
      _studentStats = {}; // Reset
      
      double globalTotal = 0.0;
      Map<String, double> balances = {};

      for (var student in _students) {
         final sId = int.tryParse(student.id);
         if (sId != null) {
            // 1. Fetch Attendance Stats
            try {
              final attendance = await attendanceService.getStudentAttendanceSummary(sId);
              _studentStats[sId] = {
                'attendance': (attendance['percentage'] as num?)?.toDouble() ?? 0.0,
              };
            } catch (e) {
              debugPrint('Error loading stats for student $sId: $e');
            }

            // 2. Fetch Fees and calculate balance
            try {
               final fees = await feeService.getFees(studentId: sId);
               double studentTotal = 0.0;
               for (var fee in fees) {
                  // Assuming fee object has 'balance' or we calculate it. 
                  // If API returns 'balance', use it. Else 'amount'.
                  // Checking 'balance' existence.
                  final balance = (fee['balance'] ?? fee['amount'] ?? 0).toDouble();
                  if (balance > 0) studentTotal += balance;
               }
               balances[student.id] = studentTotal;
               globalTotal += studentTotal;
            } catch (e) {
               debugPrint('Error loading fees for student $sId: $e');
            }
         }
      }
      
      _totalGlobalOutstanding = globalTotal;
      _studentBalances = balances;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading students...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(
        child: Text('No students found. Please contact school admin.'),
      );
    }

    if (_sections.isEmpty) {
      return const Center(child: Text('No sections found'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: AppTheme.constrainedContent(
        context: context,
        child: SingleChildScrollView(
          padding: AppTheme.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Parental Overview",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Section switcher
              if (_sections.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sections.map((section) {
                      final isSelected = selectedSection?.id == section.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(section.sectionName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedSection = section);
                              _loadData();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              ResponsiveRowColumn(
                rowOnMobile: false,
                rowOnTablet: true,
                rowOnDesktop: true,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Students section
                        if (selectedSection != null) ...[
                          Text(
                            "Your Children", 
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 12),
                          ResponsiveGridView(
                            mobileColumns: 1,
                            tabletColumns: 2,
                            desktopColumns: 3,
                            runSpacing: 12,
                            spacing: 12,
                            childAspectRatio: 1.8,
                            children: _students
                                .where((s) => s.sectionIds.contains(selectedSection!.id))
                                .map((student) => _buildStudentCard(student))
                                .toList(),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
                  if (!context.isMobile) const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: _buildFeesOverview(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Attendance & Performance Section (Dynamic)
              if (selectedSection != null)
                ResponsiveGridView(
                  mobileColumns: 1,
                  tabletColumns: 1,
                  desktopColumns: 2,
                  runSpacing: 24,
                  spacing: 24,
                  childAspectRatio: context.isDesktop ? 2.5 : 2.0,
                  children: _students
                      .where((s) => s.sectionIds.contains(selectedSection!.id))
                      .map((student) {
                    final sId = int.tryParse(student.id) ?? 0;
                    final stats = _studentStats[sId] ?? {'attendance': 0.0};
                    final attendance = (stats['attendance'] as double);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance: ${student.fullName}', 
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 12),
                        AttendanceCircleChart(
                          percentage: attendance,
                          label: 'Term Attendance',
                        ),
                      ],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 24,
        hasGlow: true,
        borderColor: AppTheme.neonBlue.withOpacity(0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                student.fullName[0],
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              student.prettyId ?? 'ID: ${student.id}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Fees',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentFeeScreen(
                          studentId: int.parse(student.id),
                          studentName: student.fullName,
                        ),
                      ),
                    );
                  },
                ),
                _ActionButton(
                  icon: Icons.calendar_today_rounded,
                  label: 'Attendance',
                  color: AppTheme.neonEmerald,
                  onTap: () {
                    // Action for attendance
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesOverview(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fees Overview", 
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(
            context: context, 
            opacity: 0.05,
            borderRadius: 24,
            borderColor: AppTheme.neonPurple.withValues(alpha: 0.3),
            hasGlow: true,
          ).copyWith(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonPurple.withValues(alpha: 0.1),
                Colors.transparent 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Outstanding", 
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 13
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(_totalGlobalOutstanding),
                        style: TextStyle(
                          fontSize: 28, // Slightly smaller for better fit
                          fontWeight: FontWeight.bold, 
                          color: _totalGlobalOutstanding > 0 ? AppTheme.errorColor : AppTheme.neonEmerald,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppTheme.neonPurple, size: 28),
                  )
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...(_studentBalances.entries.isEmpty 
                  ? [const Text("No fee data available", style: TextStyle(fontSize: 12, color: Colors.grey))]
                  : _studentBalances.entries.map((entry) {
                final student = _students.firstWhere(
                  (s) => s.id == entry.key, 
                  orElse: () => StudentModel(
                    id: '0', 
                    fullName: 'Unknown', 
                    schoolId: '0',
                    classId: '0',
                    createdAt: DateTime.now(), 
                    lastModified: DateTime.now()
                  )
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Text(Formatters.formatCurrency(entry.value), style: TextStyle(fontWeight: FontWeight.bold, color: entry.value > 0 ? Colors.redAccent : Colors.green)),
                    ],
                  ),
                );
              })),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_students.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentFeeScreen(
                            studentId: int.parse(_students.first.id),
                            studentName: _students.first.fullName,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("View Details & Pay"),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
