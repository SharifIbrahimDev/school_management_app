import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/enums/fee_scope.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/class_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/student_model.dart';
import '../../core/models/term_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/models/user_model.dart';
import '../class/class_list_screen.dart';
import '../fees/fee_list_screen.dart';
import '../reports/debtors_list_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/recent_transactions_widget.dart';
import '../../widgets/financial_chart.dart';
import '../../widgets/analytics_charts.dart';
import '../../widgets/skeleton_loader.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import '../academics/timetable_screen.dart';
import '../student/add_student_screen.dart';
import 'analytics_dashboard_screen.dart';
import '../academics/lesson_plan_screen.dart';
import '../academics/syllabus_progress_screen.dart';
import '../messages/broadcast_screen.dart';
import '../transactions/transactions_list_screen.dart';

class DashboardContent extends StatefulWidget {
  final List<SectionModel> sections;
  final List<AcademicSessionModel> sessions;
  final List<ClassModel> classes;
  final List<TermModel> terms;
  final String? selectedSectionId;
  final String? selectedSessionId;
  final String? selectedTermId;
  final String? selectedClassId;
  final String? selectedStudentId;
  final Map<String, double> dashboardStats;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onSessionChanged;
  final ValueChanged<String?> onTermChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onStudentChanged;
  final RefreshCallback onRefresh;
  final String role;
  final Map<String, dynamic>? attendanceSummary;
  final Map<String, dynamic>? academicAnalytics;

  const DashboardContent({
    super.key,
    required this.sections,
    required this.sessions,
    required this.classes,
    required this.terms,
    required this.selectedSectionId,
    required this.selectedSessionId,
    required this.selectedTermId,
    required this.selectedClassId,
    required this.selectedStudentId,
    required this.dashboardStats,
    required this.isLoading,
    required this.errorMessage,
    required this.onSectionChanged,
    required this.onSessionChanged,
    required this.onTermChanged,
    required this.onClassChanged,
    required this.onStudentChanged,
    required this.onRefresh,
    required this.role,
    this.attendanceSummary,
    this.academicAnalytics,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String? _activeSectionId;

  @override
  void initState() {
    super.initState();
    _activeSectionId = widget.selectedSectionId ?? widget.sections.firstOrNull?.id;
    debugPrint('DashboardContent initState - activeSectionId: $_activeSectionId, sections: ${widget.sections.map((s) => s.id).toList()}');
  }

  @override
  void didUpdateWidget(DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSectionId != oldWidget.selectedSectionId || widget.sections != oldWidget.sections) {
      _activeSectionId = widget.selectedSectionId ?? widget.sections.firstOrNull?.id;
      debugPrint('DashboardContent didUpdateWidget - activeSectionId: $_activeSectionId');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DashboardContent build - sections: ${widget.sections.map((s) => s.id).toList()}, activeSectionId: $_activeSectionId');
    final theme = Theme.of(context);
    final authService = Provider.of<AuthServiceApi>(context);
    final userMap = authService.currentUser;
    final user = userMap != null ? UserModel.fromMap(userMap) : null;
    final schoolId = user?.schoolId;

    if (schoolId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'School ID not found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                }
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    return widget.isLoading
        ? _buildLoadingState()
        : RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: AppTheme.constrainedContent(
        context: context,
        child: SingleChildScrollView(
          padding: AppTheme.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildWelcomeCard(context, authService),
              const SizedBox(height: 24),
              if ((widget.role == 'Proprietor' || widget.role == 'Principal') && 
                  (widget.sections.isEmpty || widget.sessions.isEmpty)) ...[
                _buildSetupGuide(context),
                const SizedBox(height: 24),
              ],
              
              // Filter section can be side-by-side with analytics on large screens
              ResponsiveRowColumn(
                rowOnMobile: false,
                rowOnTablet: false,
                rowOnDesktop: true,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(context),
                        if (widget.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorCard(context),
                        ],
                        if (widget.role == 'Principal' && _activeSectionId != null) ...[
                          const SizedBox(height: 24),
                          _buildPrincipalAnalytics(context),
                        ],
                      ],
                    ),
                  ),
                  if (context.isDesktop) const SizedBox(width: 24),
                  if (context.isDesktop)
                    Expanded(
                      flex: 1,
                      child: _buildQuickActions(context),
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Multi-column layout for financial data on large screens
              ResponsiveRowColumn(
                rowOnMobile: false,
                rowOnTablet: true,
                rowOnDesktop: true,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildFinancialOverview(context),
                        const SizedBox(height: 24),
                        _buildRecentTransactions(context, schoolId),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: context.isMobile ? 0 : 24,
                    height: context.isMobile ? 24 : 0,
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildBalanceCard(context),
                        if (!context.isDesktop) ...[
                          const SizedBox(height: 24),
                          if (widget.role == 'Bursar' ||
                              widget.role == 'Proprietor' ||
                              widget.role == 'Principal')
                            _buildQuickActions(context),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80), // Final spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CardSkeletonLoader(),
          const SizedBox(height: 16),
          const CardSkeletonLoader(),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: const [
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
            ],
          ),
          const SizedBox(height: 24),
          const CardSkeletonLoader(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, AuthServiceApi authService) {
    final theme = Theme.of(context);
    final userMap = authService.currentUser;
    final user = userMap != null ? UserModel.fromMap(userMap) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.school_rounded,
              size: 120,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          user?.fullName ?? widget.role,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildGlassIconButton(
                    context: context,
                    icon: Icons.notifications_none_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _buildHeaderStat(
                    context,
                    'Sections',
                    widget.sections.length.toString(),
                    Icons.grid_view_rounded,
                  ),
                  const SizedBox(width: 32),
                  _buildHeaderStat(
                    context,
                    'Status',
                    'Active',
                    Icons.verified_user_rounded,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildHeaderStat(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSetupGuide(BuildContext context) {
    final hasSession = widget.sessions.isNotEmpty;
    final hasSection = widget.sections.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        borderRadius: 20,
        borderColor: AppTheme.accentColor.withValues(alpha: 0.3),
        hasGlow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: AppTheme.accentColor),
              const SizedBox(width: 12),
              const Text(
                'Let\'s Get Started!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete these steps to set up your school:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildSetupStep(
            context, 
            '1. Create Academic Session', 
            'Define your current school year (e.g., 2024/2025).',
            hasSession,
            Icons.calendar_month,
          ),
          const SizedBox(height: 12),
          _buildSetupStep(
            context, 
            '2. Create Sections', 
            'Add sections like "Primary 1" or "JSS 1".',
            hasSection,
            Icons.class_outlined,
          ),
         const SizedBox(height: 16),
         if (!hasSession || !hasSection)
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppTheme.primaryColor,
                 foregroundColor: Colors.white,
               ),
               onPressed: () {
                 // The navigation tabs are available, so we just guide them textually or 
                 // we could switch tabs if we had access to the TabController, but generic advice is fine.
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Use the "Sessions" or "Sections" tab below to continue setup.'))
                 );
               },
               child: const Text('Go to Setup Tabs'),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSetupStep(BuildContext context, String title, String subtitle, bool isDone, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDone ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check : icon,
            color: isDone ? Colors.green : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDone ? Colors.green : null,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final termService = Provider.of<TermServiceApi>(context, listen: false);
    final classService = Provider.of<ClassServiceApi>(context, listen: false);
    final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final schoolId = authService.currentUserModel?.schoolId ?? '';

    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isDark ? 0.3 : 0.7,
        borderRadius: 24,
        hasGlow: true,
        borderColor: theme.dividerColor.withOpacity(0.1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          'Filter Analysis',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        leading: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Row(
            children: [
              Expanded(child: _buildSectionDropdown(context, sectionService, schoolId)),
              const SizedBox(width: 12),
              Expanded(child: _buildSessionDropdown(context)),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: (_activeSectionId != null && widget.selectedSessionId != null)
                ? termService.getTerms(
              sectionId: int.tryParse(_activeSectionId!),
              sessionId: int.tryParse(widget.selectedSessionId!),
            )
                : Future.value([]),
            builder: (context, snapshot) {
              final termsData = snapshot.data ?? [];
              final currentTerms = termsData.map((data) => TermModel.fromMap(data)).toList();
              return _buildTermDropdown(context, currentTerms);
            },
          ),
          if (_activeSectionId != null &&
              ['Proprietor', 'Principal', 'Bursar'].contains(widget.role)) ...[
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: classService.getClasses(sectionId: int.tryParse(_activeSectionId!)),
              builder: (context, snapshot) {
                final classesData = snapshot.data ?? [];
                final currentClasses = classesData.map((data) => ClassModel.fromMap(data)).toList();
                return _buildClassDropdown(context, currentClasses);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrincipalAnalytics(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic & Attendance Insights',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                context,
                title: 'Today\'s Attendance',
                value: widget.attendanceSummary != null
                    ? '${widget.attendanceSummary!['percentage_present']}%'
                    : '...',
                subtitle: widget.attendanceSummary != null
                    ? '${widget.attendanceSummary!['present_count']} / ${widget.attendanceSummary!['total_students']} present'
                    : 'Loading...',
                icon: Icons.people_alt_rounded,
                color: Colors.blue,
              ),
            ),
            // Performance stats hidden for V1 Release
            /*
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                context,
                title: 'Avg. Performance',
                value: widget.academicAnalytics != null && (widget.academicAnalytics!['class_averages'] as List).isNotEmpty
                    ? '${'${(widget.academicAnalytics!['class_averages'] as List).map((e) => e['average_score'] as num).reduce((a, b) => a + b) / (widget.academicAnalytics!['class_averages'] as List).length}%'.split('.').first}%'
                    : '...',
                subtitle: 'Section Average',
                icon: Icons.auto_graph_rounded,
                color: Colors.purple,
              ),
            ),
            */
          ],
        ),
        /* // At risk students hidden for V1
        if (widget.academicAnalytics != null && (widget.academicAnalytics!['at_risk_students'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAtRiskList(context, widget.academicAnalytics!['at_risk_students'] as List),
        ],
        */
      ],
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isDark ? 0.3 : 0.8,
        borderRadius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskList(BuildContext context, List<dynamic> students) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isDark ? 0.3 : 0.8,
        borderRadius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Students at Risk',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Spacer(),
              Text(
                'Low Average',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...students.take(3).map((student) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    student['student_name'][0],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    student['student_name'],
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Text(
                  '${(student['average_score'] as num).toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionDropdown(
      BuildContext context, SectionServiceApi sectionService, String schoolId) {
    return _buildDropdownWrapper(
      context,
      label: 'Academic Section',
      icon: Icons.school_rounded,
      child: DropdownButtonFormField<String>(
        value: widget.sections.isEmpty ? null : _activeSectionId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          if (widget.sections.isEmpty)
            const DropdownMenuItem(value: null, child: Text('No Sections Available')),
          if (widget.role == 'Proprietor')
            const DropdownMenuItem(value: 'all', child: Text('All Sections')),
          ...widget.sections.map((section) => DropdownMenuItem(
            value: section.id,
            child: Text(section.sectionName),
          )),
        ],
        onChanged: widget.isLoading || widget.sections.isEmpty
            ? null
            : (value) {
          setState(() {
            _activeSectionId = value == 'all' ? null : value;
          });
          widget.onSectionChanged(value == 'all' ? null : value);
          widget.onClassChanged(null);
          widget.onStudentChanged(null);
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildSessionDropdown(BuildContext context) {
    return _buildDropdownWrapper(
      context,
      label: 'Academic Session',
      icon: Icons.calendar_month_rounded,
      child: DropdownButtonFormField<String>(
        value: widget.sessions.isEmpty ? null : widget.selectedSessionId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          const DropdownMenuItem(value: null, child: Text('No Sessions Available')),
          ...widget.sessions.map((session) => DropdownMenuItem(
            value: session.id,
            child: Text(session.sessionName),
          )),
        ],
        onChanged: widget.isLoading
            ? null
            : (value) {
          widget.onSessionChanged(value);
          widget.onTermChanged(null);
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildTermDropdown(BuildContext context, List<TermModel> currentTerms) {
    return _buildDropdownWrapper(
      context,
      label: 'School Term',
      icon: Icons.assignment_rounded,
      child: DropdownButtonFormField<String>(
        value: currentTerms.isEmpty ? null : widget.selectedTermId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          const DropdownMenuItem(value: null, child: Text('No Terms Available')),
          ...currentTerms.map((term) => DropdownMenuItem(
            value: term.id,
            child: Text(term.termName),
          )),
        ],
        onChanged: widget.isLoading
            ? null
            : (value) {
          widget.onTermChanged(value);
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildClassDropdown(BuildContext context, List<ClassModel> currentClasses) {
    return _buildDropdownWrapper(
      context,
      label: 'Class (Optional)',
      icon: Icons.class_outlined,
      child: DropdownButtonFormField<String>(
        value: currentClasses.isEmpty ? null : widget.selectedClassId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select Class (Optional)')),
          ...currentClasses.map((classModel) => DropdownMenuItem(
            value: classModel.id,
            child: Text(classModel.name),
          )),
        ],
        onChanged: widget.isLoading
            ? null
            : (value) {
          widget.onClassChanged(value);
          widget.onStudentChanged(null);
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildStudentDropdown(BuildContext context, List<StudentModel> currentStudents) {
    return _buildDropdownWrapper(
      context,
      label: 'Specific Student',
      icon: Icons.person_search_rounded,
      child: DropdownButtonFormField<String>(
        value: currentStudents.isEmpty ? null : widget.selectedStudentId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select Student (Optional)')),
          ...currentStudents.map((student) => DropdownMenuItem(
            value: student.id,
            child: Text(student.fullName),
          )),
        ],
        onChanged: widget.isLoading ? null : widget.onStudentChanged,
        isExpanded: true,
      ),
    );
  }

  Widget _buildDropdownWrapper(BuildContext context, {required String label, required IconData icon, required Widget child}) {
    final theme = Theme.of(context);
    // Use surface for container background to ensure contrast against page background
    final containerColor = theme.brightness == Brightness.dark 
        ? theme.colorScheme.surface 
        : AppTheme.surfaceColor;
        
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding slightly
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensure compact height
              children: [
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodySmall?.color, // Use theme body color for label
                    fontSize: 11,
                  ),
                ),
                Flexible(
                  child: Theme(
                    data: theme.copyWith(
                      // Ensure dropdown menu matches container surface
                      canvasColor: containerColor,
                      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.isLoading ? null : widget.onRefresh,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add the interactive chart
        // Hidden mock chart for V1 to keep it clean and focused on real data
        /*
        if (widget.role == 'Proprietor' || widget.role == 'Principal') ...[
          const NeonLineChart(
            title: 'Fee Collection Trends',
            spots: [
              FlSpot(0, 20),
              FlSpot(1, 35),
              FlSpot(2, 28),
              FlSpot(3, 45),
              FlSpot(4, 38),
              FlSpot(5, 52),
              FlSpot(6, 48),
            ],
            neonColor: AppTheme.neonTeal,
          ),
          const SizedBox(height: 24),
        ],
        */
        FinancialBarChart(
          totalIncome: widget.dashboardStats['totalGenerated'] ?? 0.0,
          totalExpenses: widget.dashboardStats['totalSpent'] ?? 0.0,
          cashInHand: widget.dashboardStats['cashInHand'] ?? 0.0,
          bankBalance: widget.dashboardStats['cashInAccount'] ?? 0.0,
        ),
        const SizedBox(height: 24),
        // Keep the card grid for quick reference
        const SizedBox(height: 32),
        Text(
          'Financial Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGridView(
          mobileColumns: 2,
          tabletColumns: 2,
          desktopColumns: 4,
          runSpacing: 16,
          spacing: 16,
          childAspectRatio: context.isMobile ? 1.2 : 1.3,
          children: [
            DashboardCard(
              title: 'Total Income',
              value: '₦${widget.dashboardStats['totalGenerated']?.toStringAsFixed(0) ?? '0'}',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF10B981),
              trend: '+12%',
              isPositive: true,
            ),
            DashboardCard(
              title: 'Total Expenses',
              value: '₦${widget.dashboardStats['totalSpent']?.toStringAsFixed(0) ?? '0'}',
              icon: Icons.trending_down_rounded,
              color: const Color(0xFFEF4444),
              trend: '-5%',
              isPositive: false,
            ),
            DashboardCard(
              title: 'Cash In Hand',
              value: '₦${widget.dashboardStats['cashInHand']?.toStringAsFixed(0) ?? '0'}',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF3B82F6),
            ),
            DashboardCard(
              title: 'Bank Balance',
              value: '₦${widget.dashboardStats['cashInAccount']?.toStringAsFixed(0) ?? '0'}',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final balance = widget.dashboardStats['balanceRemaining'] ?? 0.0;
    final isPositive = balance >= 0;

    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.5,
        borderRadius: 12,
        borderColor: theme.dividerColor.withOpacity(0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Balance',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${balance.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.role == 'Bursar' || widget.role == 'Proprietor')
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                onPressed: widget.isLoading ? null : () => _showBalanceInfo(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showBalanceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Balance Information'),
        content: const Text(
          'Net Balance = Total Income - Total Expenses\n\n'
              'Positive balance indicates surplus funds\n'
              'Negative balance indicates deficit',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, String schoolId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecentTransactionsWidget(
          sectionId: _activeSectionId ?? widget.sections.firstOrNull?.id ?? '',
          sessionId: widget.selectedSessionId,
          termId: widget.selectedTermId,
          schoolId: schoolId,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthServiceApi>(context);
    final schoolId = authService.currentUserModel?.schoolId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (widget.role == 'Bursar')
              FilledButton.icon(
                onPressed: widget.isLoading ||
                    _activeSectionId == null ||
                    widget.selectedTermId == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        sectionId: _activeSectionId!,
                        termId: widget.selectedTermId!,
                        sessionId: widget.selectedSessionId,
                        classId: widget.selectedClassId ?? '',
                      ),
                    ),
                  ).then((result) {
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction added successfully!')),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Transaction'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            OutlinedButton.icon(
              onPressed: widget.isLoading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionsListScreen(
                            schoolId: schoolId,
                            sectionId: _activeSectionId,
                            sessionId: widget.selectedSessionId,
                            termId: widget.selectedTermId,
                            studentId: widget.selectedStudentId,
                          ),
                        ),
                      ),
              icon: const Icon(Icons.receipt, size: 18),
              label: const Text('View All'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            if (widget.role == 'Bursar')
              OutlinedButton.icon(
                onPressed: widget.isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DebtorsListScreen()),
                        ),
                icon: const Icon(Icons.priority_high_rounded, size: 18),
                label: const Text('View Debtors'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                ),
              ),
            if (widget.role == 'Proprietor' ||
                widget.role == 'Principal' ||
                widget.role == 'Bursar')
              OutlinedButton.icon(
                onPressed: widget.isLoading
                    ? null
                    : () async {
                  final authService = Provider.of<AuthServiceApi>(context, listen: false);
                  final userRole = authService.currentUserModel?.role.toString().split('.').last;
                  final userSectionId = authService.currentUserModel?.sectionId;
                  final userId = authService.currentUserModel?.id;

                  FeeScope selectedScope;
                  String? effectiveSectionId = _activeSectionId ?? userSectionId;
                  String? effectiveStudentId = widget.selectedStudentId;
                  String? effectiveParentId;

                  if (widget.selectedStudentId != null &&
                      widget.selectedTermId != null &&
                      effectiveSectionId != null) {
                    selectedScope = FeeScope.student;
                  } else if (widget.selectedClassId != null &&
                      widget.selectedTermId != null &&
                      effectiveSectionId != null) {
                    selectedScope = FeeScope.classScope;
                  } else if (_activeSectionId != null && widget.selectedSessionId != null) {
                    selectedScope = FeeScope.section;
                  } else if (userRole == 'proprietor' && widget.selectedSessionId != null) {
                    selectedScope = FeeScope.school;
                    effectiveSectionId = null;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please select the required parameters (e.g., section, class, or student)')),
                    );
                    return;
                  }

                  if (userRole == 'parent' &&
                      effectiveStudentId == null &&
                      userId != null) {
                    selectedScope = FeeScope.parent;
                    effectiveParentId = userId;
                    if (widget.selectedSessionId == null || effectiveSectionId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a session and section')),
                      );
                      return;
                    }
                  }

                  if (userRole == 'teacher' &&
                      widget.selectedClassId == null &&
                      widget.selectedStudentId == null) {
                    
                    final teacherClassId = authService.currentUserModel?.assignedClasses.firstOrNull;
                    
                    if (teacherClassId == null ||
                        widget.selectedTermId == null ||
                        effectiveSectionId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'No class or term assigned. Please contact the administrator.')),
                      );
                      return;
                    }
                    _navigateToFeeList(
                      context,
                      FeeScope.classScope,
                      schoolId,
                      effectiveSectionId,
                      widget.selectedSessionId,
                      widget.selectedTermId,
                      teacherClassId,
                      null,
                      null,
                    );
                  } else {
                    _navigateToFeeList(
                      context,
                      selectedScope,
                      schoolId,
                      effectiveSectionId,
                      widget.selectedSessionId,
                      widget.selectedTermId,
                      widget.selectedClassId,
                      effectiveStudentId,
                      effectiveParentId,
                    );
                  }
                },
                icon: const Icon(Icons.monetization_on_outlined, size: 18),
                label: const Text('View Fees'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            if (widget.role == 'Proprietor')
              OutlinedButton.icon(
                onPressed: widget.isLoading
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnalyticsDashboardScreen(
                      schoolId: schoolId,
                      sectionId: _activeSectionId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.bar_chart, size: 18),
                label: const Text('View Reports'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            if (widget.role == 'Proprietor')
              OutlinedButton.icon(
                onPressed: widget.isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddStudentScreen()),
                        ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Register Student'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            // Communication and Academic features hidden for V1 Release
            /*
            if (widget.role == 'Principal')
              OutlinedButton.icon(
                onPressed: widget.isLoading || _activeSectionId == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BroadcastScreen(sectionId: _activeSectionId),
                          ),
                        ),
                icon: const Icon(Icons.campaign_outlined, size: 18),
                label: const Text('Broadcast'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            */
            /*
            if (widget.role == 'Principal' || widget.role == 'Teacher') ...[
              OutlinedButton.icon(
                onPressed: widget.isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SyllabusProgressScreen()),
                        ),
                icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                label: const Text('Syllabus'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LessonPlanScreen()),
                        ),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Lesson Plans'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
            */
            /*
            OutlinedButton.icon(
              onPressed: widget.isLoading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TimetableScreen()),
                      ),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('View Timetable'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            */
          ],
        ),
      ],
    );
  }

  void _navigateToFeeList(
      BuildContext context,
      FeeScope scope,
      String schoolId,
      String? sectionId,
      String? sessionId,
      String? termId,
      String? classId,
      String? studentId,
      String? parentId,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeeListScreen(
          scope: scope,
          schoolId: schoolId,
          sectionId: sectionId,
          sessionId: sessionId,
          termId: termId,
          classId: classId,
          studentId: studentId,
          parentId: parentId,
        ),
      ),
    );
  }
}
