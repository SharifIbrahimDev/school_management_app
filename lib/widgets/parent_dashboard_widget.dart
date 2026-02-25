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

             // 3. Fetch Fees and calculate balance
            double globalTotal = 0.0;
            Map<String, double> balances = {};

            for (var student in _students) {
               final sId = int.tryParse(student.id);
               if (sId != null) {
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
                            childAspectRatio: 2.0,
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

              const SizedBox(height: 32),
              
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildQuickAction(context, Icons.event_available_rounded, "Calendar", AppTheme.neonBlue),
                   _buildQuickAction(context, Icons.photo_library_rounded, "Gallery", AppTheme.neonPurple),
                   _buildQuickAction(context, Icons.menu_book_rounded, "Handbook", AppTheme.neonPink),
                   _buildQuickAction(context, Icons.contact_support_rounded, "Support", AppTheme.neonEmerald),
                ],
              ),

              const SizedBox(height: 32),
              
              // Recent Activity or Info Card
              _buildInfoCard(
                context,
                title: "School Announcements",
                message: "Reminder: Mid-term holidays start next week Friday. Check the calendar for details.",
                icon: Icons.campaign_rounded,
                color: AppTheme.neonBlue,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.1,
            borderRadius: 18,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String message, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 28,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
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
                const SizedBox(height: 8),
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

