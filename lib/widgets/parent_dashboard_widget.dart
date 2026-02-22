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
import '../screens/fees/parent_fee_screen.dart';
import 'analytics_charts.dart';
import '../core/services/attendance_service_api.dart';
import '../core/services/exam_service_api.dart';
import 'responsive_widgets.dart';
import '../core/services/auth_service_api.dart';
import 'error_display_widget.dart';
import 'empty_state_widget.dart';
import 'skeleton_loader.dart';

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
  Map<int, List<Map<String, dynamic>>> _studentResults = {};
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

      if (!mounted) return;

      // Fetch stats for all students
      final attendanceService = Provider.of<AttendanceServiceApi>(context, listen: false);
      final examService = Provider.of<ExamServiceApi>(context, listen: false);

      _studentStats = {}; // Reset
      _studentResults = {};
      
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

            // 2. Fetch Recent Results
            try {
              final results = await examService.getStudentRecentResults(sId);
              _studentResults[sId] = results;
            } catch (e) {
              debugPrint('Error loading results for student $sId: $e');
            }

            // 3. Fetch Fees and calculate balance
            try {
               final fees = await feeService.getFees(studentId: sId);
               double studentTotal = 0.0;
               for (var fee in fees) {
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
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        error: _errorMessage!,
        onRetry: _loadData,
      );
    }

    if (_students.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.family_restroom_rounded,
        title: 'No Children Linked',
        message: 'No student records are linked to your account. Please contact the school office to link your children.',
        onActionPressed: _loadData,
        actionButtonText: 'Refresh',
      );
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
              _buildWelcomeHeader(),
              const SizedBox(height: 32),
              
              Text(
                "Quick Overview",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(section.sectionName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedSection = section);
                              // We don't necessarily need to reload everything if we have the data
                            }
                          },
                          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 12),
                          ResponsiveGridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mobileColumns: 1,
                            tabletColumns: 1,
                            desktopColumns: 2,
                            runSpacing: 16,
                            spacing: 16,
                            childAspectRatio: 2.2,
                            children: _students
                                .where((s) => s.sectionIds.contains(selectedSection!.id))
                                .map((student) => _buildStudentCard(student))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!context.isMobile) const SizedBox(width: 24),
                  if (context.isMobile) const SizedBox(height: 24),
                  Expanded(
                    flex: 2,
                    child: _buildFeesOverview(context),
                  ),
                ],
              ),

              const SizedBox(height: 48),

                const SizedBox(height: 32),

                // Attendance Section
                if (selectedSection != null) ...[
                  Text(
                    "Attendance Tracking",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ResponsiveGridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mobileColumns: 1,
                    tabletColumns: 2,
                    desktopColumns: 3,
                    runSpacing: 24,
                    spacing: 24,
                    childAspectRatio: 1.2,
                    children: _students
                        .where((s) => s.sectionIds.contains(selectedSection!.id))
                        .map((student) {
                      final sId = int.tryParse(student.id) ?? 0;
                      final stats = _studentStats[sId] ?? {'attendance': 0.0};
                      final attendance = (stats['attendance'] as double);

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.1,
                          borderRadius: 28,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              student.fullName, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),
                            AttendanceCircleChart(
                              percentage: attendance,
                              label: 'Attendance',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 32),

                // Academic Progress Section
                if (selectedSection != null) ...[
                  Text(
                    "Academic Progress",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: _students
                        .where((s) => s.sectionIds.contains(selectedSection!.id))
                        .map((student) {
                      final sId = int.tryParse(student.id) ?? 0;
                      final results = _studentResults[sId] ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.1,
                          borderRadius: 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.neonPink.withValues(alpha: 0.1),
                                  child: Text(
                                    student.fullName[0],
                                    style: const TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  student.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (results.isEmpty)
                              Center(
                                child: Text(
                                  "No recent exam results found",
                                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: results.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final res = results[index];
                                  final subject = res['exam']?['subject']?['subject_name'] ?? 'Unknown Subject';
                                  final score = (res['score'] as num?)?.toDouble() ?? 0.0;
                                  final grade = res['grade'] ?? '-';
                                  
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(subject, style: const TextStyle(fontWeight: FontWeight.w500)),
                                            Text(
                                              res['exam']?['exam_name'] ?? 'Exam',
                                              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.neonPink.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "$score / $grade",
                                          style: const TextStyle(
                                            color: AppTheme.neonPink,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CardSkeletonLoader(),
          const SizedBox(height: 32),
          const CardSkeletonLoader(),
          const SizedBox(height: 32),
          ResponsiveGridView(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            runSpacing: 24,
            spacing: 24,
            childAspectRatio: 1.3,
            children: const [
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final user = authService.currentUserModel;
    final name = user?.fullName.split(' ').first ?? 'Parent';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 32,
        hasGlow: true,
      ).copyWith(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonPurple.withValues(alpha: 0.1),
            AppTheme.neonBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.family_restroom_rounded, color: AppTheme.neonPurple, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello,",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
          if (_totalGlobalOutstanding > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    "Fees Due",
                    style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 24,
        borderColor: AppTheme.neonBlue.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.1),
            child: Text(
              student.fullName[0].toUpperCase(),
              style: const TextStyle(color: AppTheme.neonBlue, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  student.prettyId ?? 'ID: ${student.id}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SmallActionButton(
                      icon: Icons.receipt_long_rounded,
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
                    const SizedBox(width: 12),
                    _SmallActionButton(
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.neonEmerald,
                      onTap: () {
                        // Action for attendance
                      },
                    ),
                    const SizedBox(width: 12),
                    _SmallActionButton(
                      icon: Icons.bar_chart_rounded,
                      color: AppTheme.neonPink,
                      onTap: () {
                        // Action for performance
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fees Overview", 
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(
            context: context, 
            opacity: 0.1,
            borderRadius: 28,
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
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Outstanding", 
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(_totalGlobalOutstanding),
                        style: TextStyle(
                          fontSize: 32,
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
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.neonPurple, size: 28),
                  )
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              ...(_studentBalances.entries.isEmpty 
                  ? [Text("No fee records found", style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor))]
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
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.fullName, 
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                      Text(
                        Formatters.formatCurrency(entry.value), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 13,
                          color: entry.value > 0 ? AppTheme.errorColor : AppTheme.neonEmerald
                        )
                      ),
                    ],
                  ),
                );
              })),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text("Make Payment"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

