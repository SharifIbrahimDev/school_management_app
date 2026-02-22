import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/fee_scope.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/class_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/term_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../class/class_list_screen.dart';
import '../fees/fee_list_screen.dart';
import '../reports/debtors_list_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/recent_transactions_widget.dart';
import '../../widgets/financial_chart.dart';
import '../../widgets/skeleton_loader.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import '../student/add_student_screen.dart';
import 'analytics_dashboard_screen.dart';
import '../transactions/transactions_list_screen.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../sections/add_section_screen.dart';
import '../sessions/add_session_screen.dart';

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
  }

  @override
  void didUpdateWidget(DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSectionId != oldWidget.selectedSectionId || widget.sections != oldWidget.sections) {
      _activeSectionId = widget.selectedSectionId ?? widget.sections.firstOrNull?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final schoolId = authService.currentUserModel?.schoolId;

    if (schoolId == null) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.lock_person_rounded,
          title: 'Session Expired',
          message: 'Please log in again to access your dashboard.',
          actionButtonText: 'Go to Login',
          onActionPressed: () async {
            await authService.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
            }
          },
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
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(context, authService),
                    const SizedBox(height: 32),
                    if ((widget.role == 'Proprietor' || widget.role == 'Principal') &&
                        (widget.sections.isEmpty || widget.sessions.isEmpty)) ...[
                      _buildSetupGuide(context),
                      const SizedBox(height: 24),
                    ],
                    ResponsiveRowColumn(
                      rowOnMobile: false,
                      rowOnTablet: false,
                      rowOnDesktop: true,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (context.isDesktop)
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildQuickActions(context),
                                const SizedBox(height: 32),
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
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildQuickActions(context),
                              const SizedBox(height: 32),
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
                        if (context.isDesktop) const SizedBox(width: 32),
                        if (context.isDesktop)
                          Expanded(
                            flex: 1,
                            child: _buildFinancialSummarySidePanel(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildFinancialOverview(context),
                    const SizedBox(height: 32),
                    _buildRecentTransactions(context, schoolId),
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
          const SizedBox(height: 24),
          const CardSkeletonLoader(),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: const [
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
              DashboardCardSkeletonLoader(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, AuthServiceApi authService) {
    final user = authService.currentUserModel;
    final name = user?.fullName.split(' ').first ?? widget.role;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 28,
        hasGlow: true,
      ).copyWith(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.neonBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.neonBlue],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome back,",
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRoleBadge(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    final colorMap = {
      'Proprietor': AppTheme.neonEmerald,
      'Principal': AppTheme.neonBlue,
      'Bursar': AppTheme.neonPurple,
      'Teacher': AppTheme.neonAmber,
    };
    final color = colorMap[widget.role] ?? AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            widget.role,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final schoolId = authService.currentUserModel?.schoolId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              if (widget.role == 'Bursar')
                _ActionItem(
                  label: "Add Entry",
                  icon: Icons.add_circle_outline_rounded,
                  color: AppTheme.neonEmerald,
                  onTap: () => _navigateToAddEntry(context),
                ),
              _ActionItem(
                label: "History",
                icon: Icons.receipt_long_rounded,
                color: AppTheme.neonBlue,
                onTap: () => _navigateToHistory(context, schoolId),
              ),
              if (widget.role == 'Bursar')
                _ActionItem(
                  label: "Debtors",
                  icon: Icons.error_outline_rounded,
                  color: AppTheme.neonAmber,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtorsListScreen())),
                ),
              _ActionItem(
                label: "Fees",
                icon: Icons.payments_rounded,
                color: AppTheme.neonPurple,
                onTap: () => _handleViewFees(context, schoolId),
              ),
              if (widget.role == 'Proprietor') ...[
                _ActionItem(
                  label: "Reports",
                  icon: Icons.bar_chart_rounded,
                  color: AppTheme.neonTeal,
                  onTap: () => _navigateToReports(context, schoolId),
                ),
                _ActionItem(
                  label: "Classes",
                  icon: Icons.school_rounded,
                  color: AppTheme.neonBlue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassListScreen())),
                ),
                _ActionItem(
                  label: "Students",
                  icon: Icons.person_add_rounded,
                  color: AppTheme.neonAmber,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentScreen())),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummarySidePanel(BuildContext context) {
    return Column(
      children: [
        _buildBalanceCard(context),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.1,
            borderRadius: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Active Snapshot",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildSnapshotItem("Transactions", "Real-time", AppTheme.neonBlue),
              _buildSnapshotItem("Compliance", "98%", AppTheme.neonEmerald),
              _buildSnapshotItem("Reporting", "Standard", AppTheme.neonPurple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final theme = Theme.of(context);
    final termService = Provider.of<TermServiceApi>(context, listen: false);
    final classService = Provider.of<ClassServiceApi>(context, listen: false);
    final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final schoolId = authService.currentUserModel?.schoolId ?? '';

    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.5,
        borderRadius: 28,
        hasGlow: false,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(
          'Filter Analysis',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        leading: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          ResponsiveRowColumn(
            rowOnMobile: false,
            rowOnTablet: true,
            children: context.isMobile
                ? [
                    _buildSectionDropdown(context, sectionService, schoolId),
                    _buildSessionDropdown(context),
                  ]
                : [
                    Expanded(child: _buildSectionDropdown(context, sectionService, schoolId)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSessionDropdown(context)),
                  ],
          ),
          const SizedBox(height: 16),
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
          if (_activeSectionId != null && ['Proprietor', 'Principal', 'Bursar'].contains(widget.role)) ...[
            const SizedBox(height: 16),
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

  Widget _buildFinancialOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 20),
        FinancialBarChart(
          totalIncome: widget.dashboardStats['totalGenerated'] ?? 0.0,
          totalExpenses: widget.dashboardStats['totalSpent'] ?? 0.0,
          cashInHand: widget.dashboardStats['cashInHand'] ?? 0.0,
          bankBalance: widget.dashboardStats['cashInAccount'] ?? 0.0,
        ),
        const SizedBox(height: 24),
        ResponsiveGridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mobileColumns: 2,
          tabletColumns: 2,
          desktopColumns: 4,
          runSpacing: 20,
          spacing: 20,
          childAspectRatio: context.isMobile ? 0.95 : 1.3,
          children: [
            DashboardCard(
              title: 'Total Income',
              value: Formatters.formatCurrency((widget.dashboardStats['totalGenerated'] ?? 0).toDouble()),
              icon: Icons.trending_up_rounded,
              color: AppTheme.neonEmerald,
              trend: '+12%',
              isPositive: true,
            ),
            DashboardCard(
              title: 'Total Expenses',
              value: Formatters.formatCurrency((widget.dashboardStats['totalSpent'] ?? 0).toDouble()),
              icon: Icons.trending_down_rounded,
              color: Colors.redAccent,
              trend: '-5%',
              isPositive: false,
            ),
            DashboardCard(
              title: 'Cash In Hand',
              value: Formatters.formatCurrency((widget.dashboardStats['cashInHand'] ?? 0).toDouble()),
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.neonBlue,
            ),
            DashboardCard(
              title: 'Bank Balance',
              value: Formatters.formatCurrency((widget.dashboardStats['cashInAccount'] ?? 0).toDouble()),
              icon: Icons.account_balance_rounded,
              color: AppTheme.neonPurple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final balance = widget.dashboardStats['balanceRemaining'] ?? 0.0;
    final isPositive = balance >= 0;
    final color = isPositive ? AppTheme.neonEmerald : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 24,
        borderColor: color.withValues(alpha: 0.3),
        hasGlow: isPositive && balance > 0,
      ).copyWith(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            Colors.transparent,
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
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.account_balance_rounded : Icons.warning_amber_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Surplus',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(balance),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dropdown Builders ---

  Widget _buildSectionDropdown(BuildContext context, SectionServiceApi sectionService, String schoolId) {
    return _buildDropdownWrapper(
      context,
      label: 'Academic Section',
      icon: Icons.school_rounded,
      child: DropdownButtonFormField<String>(
        initialValue: widget.sections.isEmpty ? null : _activeSectionId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          if (widget.sections.isEmpty) const DropdownMenuItem(value: null, child: Text('No Sections Available')),
          if (widget.role == 'Proprietor') const DropdownMenuItem(value: 'all', child: Text('All Sections')),
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
        initialValue: widget.sessions.isEmpty ? null : widget.selectedSessionId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          if (widget.sessions.isEmpty) const DropdownMenuItem(value: null, child: Text('No Sessions')),
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
        initialValue: currentTerms.isEmpty ? null : widget.selectedTermId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          if (currentTerms.isEmpty) const DropdownMenuItem(value: null, child: Text('No Terms Available')),
          ...currentTerms.map((term) => DropdownMenuItem(
                value: term.id,
                child: Text(term.termName),
              )),
        ],
        onChanged: widget.isLoading ? null : (value) => widget.onTermChanged(value),
        isExpanded: true,
      ),
    );
  }

  Widget _buildClassDropdown(BuildContext context, List<ClassModel> currentClasses) {
    return _buildDropdownWrapper(
      context,
      label: 'Class Filter',
      icon: Icons.class_outlined,
      child: DropdownButtonFormField<String>(
        initialValue: currentClasses.isEmpty ? null : widget.selectedClassId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Classes')),
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

  Widget _buildDropdownWrapper(BuildContext context, {required String label, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.glassColor(context, 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  void _navigateToAddEntry(BuildContext context) {
    if (_activeSectionId == null || widget.selectedTermId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a section and term first.')));
      return;
    }
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
      if (result == true) widget.onRefresh();
    });
  }

  void _navigateToHistory(BuildContext context, String schoolId) {
    Navigator.push(
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
    );
  }

  void _handleViewFees(BuildContext context, String schoolId) {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final userSectionId = authService.currentUserModel?.sectionId;
    final userRole = authService.currentUserModel?.role.toString().split('.').last.toLowerCase();
    
    String? effectiveSectionId = _activeSectionId ?? userSectionId;
    FeeScope selectedScope;

    if (widget.selectedStudentId != null && widget.selectedTermId != null && effectiveSectionId != null) {
      selectedScope = FeeScope.student;
    } else if (widget.selectedClassId != null && widget.selectedTermId != null && effectiveSectionId != null) {
      selectedScope = FeeScope.classScope;
    } else if (effectiveSectionId != null) {
      selectedScope = FeeScope.section;
    } else if (userRole == 'proprietor' && widget.selectedSessionId != null) {
      selectedScope = FeeScope.school;
      effectiveSectionId = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select the required parameters (e.g., section, class, or student)')));
      return;
    }

    _navigateToFeeList(
      context,
      selectedScope,
      schoolId,
      effectiveSectionId,
      widget.selectedSessionId,
      widget.selectedTermId,
      widget.selectedClassId,
      widget.selectedStudentId,
      null,
    );
  }

  void _navigateToReports(BuildContext context, String schoolId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDashboardScreen(
          schoolId: schoolId,
          sectionId: _activeSectionId,
        ),
      ),
    );
  }

  void _navigateToFeeList(BuildContext context, FeeScope scope, String schoolId, String? sectionId, String? sessionId, String? termId, String? classId, String? studentId, String? parentId) {
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

  Widget _buildErrorCard(BuildContext context) {
    return ErrorDisplayWidget(
      error: widget.errorMessage!,
      onRetry: widget.onRefresh,
    );
  }

  Widget _buildSetupGuide(BuildContext context) {
    final steps = [
      _SetupStepData(
        title: 'School Sections',
        subtitle: 'Create your academic departments or levels (e.g., Primary, Secondary)',
        isDone: widget.sections.isNotEmpty,
        icon: Icons.account_tree_rounded,
        actionLabel: 'Add Section',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddSectionScreen(),
          ),
        ).then((_) => widget.onRefresh()),
        route: '/sections',
      ),
      _SetupStepData(
        title: 'Academic Sessions',
        subtitle: 'Define your school years (e.g., 2024/2025)',
        isDone: widget.sessions.isNotEmpty,
        icon: Icons.calendar_month_rounded,
        actionLabel: 'Add Session',
        onAction: widget.sections.isNotEmpty
            ? () {
                final authService = Provider.of<AuthServiceApi>(context, listen: false);
                final schoolId = authService.currentUserModel?.schoolId ?? '';
                final sectionId = widget.selectedSectionId ?? widget.sections.first.id;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSessionScreen(
                      schoolId: schoolId,
                      selectedSectionId: sectionId,
                      onSuccess: () { widget.onRefresh(); },
                    ),
                  ),
                ).then((_) => widget.onRefresh());
              }
            : null,
        route: '/sessions',
      ),
      _SetupStepData(
        title: 'School Terms',
        subtitle: 'Set up terms within each session (e.g., First Term)',
        isDone: widget.terms.isNotEmpty,
        icon: Icons.assignment_rounded,
        actionLabel: 'Add Term',
        onAction: null,
        route: null,
      ),
    ];

    final completedCount = steps.where((s) => s.isDone).length;
    final totalCount = steps.length;
    final progress = completedCount / totalCount;

    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        borderRadius: 28,
        borderColor: AppTheme.neonAmber.withValues(alpha: 0.4),
        hasGlow: true,
      ).copyWith(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonAmber.withValues(alpha: 0.08),
            AppTheme.primaryColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.neonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.neonAmber, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Initialization Required',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$completedCount of $totalCount steps completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Circular progress indicator
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: AppTheme.neonAmber.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonAmber),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Complete the steps below to unlock full analytics and dashboard features.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.neonAmber.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonAmber),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Steps
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _buildSetupStep(context, step, index, steps.length);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSetupStep(BuildContext context, _SetupStepData step, int index, int total) {
    final isDone = step.isDone;
    final isLast = index == total - 1;
    final stepColor = isDone ? AppTheme.neonEmerald : AppTheme.neonAmber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Timeline column
            SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppTheme.neonEmerald.withValues(alpha: 0.15)
                          : AppTheme.neonAmber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stepColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : step.icon,
                      color: stepColor,
                      size: 16,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.neonEmerald.withValues(alpha: 0.3)
                            : AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.neonEmerald.withValues(alpha: 0.05)
                        : AppTheme.glassColor(context, 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone
                          ? AppTheme.neonEmerald.withValues(alpha: 0.2)
                          : AppTheme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                decorationColor: AppTheme.neonEmerald,
                                color: isDone ? AppTheme.textSecondaryColor : null,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              step.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textHintColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isDone && step.onAction != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: step.onAction,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              step.actionLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (isDone) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.neonEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: AppTheme.neonEmerald,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildPrincipalAnalytics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                context,
                title: 'Attendance',
                value: widget.attendanceSummary != null ? '${widget.attendanceSummary!['percentage_present']}%' : '...',
                subtitle: widget.attendanceSummary != null ? '${widget.attendanceSummary!['present_count']} Pupils' : 'Loading...',
                icon: Icons.people_alt_rounded,
                color: AppTheme.neonBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, {required String title, required String value, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, String schoolId) {
    return RecentTransactionsWidget(
      sectionId: _activeSectionId ?? widget.sections.firstOrNull?.id ?? '',
      sessionId: widget.selectedSessionId,
      termId: widget.selectedTermId,
      schoolId: schoolId,
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 90,
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.05,
            borderRadius: 24,
            borderColor: color.withValues(alpha: 0.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for a setup step in the initialization guide
class _SetupStepData {
  final String title;
  final String subtitle;
  final bool isDone;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? route;

  const _SetupStepData({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.route,
  });
}
