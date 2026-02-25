import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/responsive_widgets.dart';
import '../../core/services/report_service_api.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/transaction_service_api.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/notification_badge.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../widgets/custom_speed_dial.dart';
import '../../screens/transactions/add_transaction_screen.dart';
import '../../screens/student/add_student_screen.dart';
import '../../screens/academics/attendance_screen.dart';
import '../../widgets/financial_chart.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String schoolId;
  final String? sectionId;

  const AnalyticsDashboardScreen({
    super.key,
    required this.schoolId,
    this.sectionId,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _netProfit = 0;
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _expenseSpots = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  double _collectedRevenue = 0;
  double _outstandingRevenue = 0;
  final GlobalKey _growthChartKey = GlobalKey();
  final GlobalKey _collectionChartKey = GlobalKey();

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
      final reportService = Provider.of<ReportServiceApi>(context, listen: false);
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      
      final collectionStats = await reportService.getCollectionStats();
      final financials = await reportService.getFinancialSummary();
      final transactionsData = await transactionService.getTransactions(limit: 5);
      final paymentMethods = await reportService.getPaymentMethods();

      double income = 0;
      double expense = 0;
      // Initialize 12 months with 0
      Map<int, double> monthlyIncome = {for (var i = 1; i <= 12; i++) i: 0.0};
      Map<int, double> monthlyExpense = {for (var i = 1; i <= 12; i++) i: 0.0};

      for (var item in financials) {
        final double inc = (item['income'] ?? 0).toDouble();
        final double exp = (item['expense'] ?? 0).toDouble();
        
        final dynamic rawMonth = item['month'];
        final int month = rawMonth is int ? rawMonth : int.tryParse(rawMonth?.toString() ?? '0') ?? 0;
        
        income += inc;
        expense += exp;
        
        if (month >= 1 && month <= 12) {
          monthlyIncome[month] = inc;
          monthlyExpense[month] = exp;
        }
      }

      List<FlSpot> incomeSpots = [];
      List<FlSpot> expenseSpots = [];

      monthlyIncome.forEach((month, value) {
        incomeSpots.add(FlSpot((month - 1).toDouble(), value / 1000));
      });

      monthlyExpense.forEach((month, value) {
        expenseSpots.add(FlSpot((month - 1).toDouble(), value / 1000));
      });

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          _netProfit = income - expense;
          _incomeSpots = incomeSpots;
          _expenseSpots = expenseSpots;
          _recentTransactions = transactionsData;
          _collectedRevenue = (collectionStats['total_paid'] ?? 0).toDouble();
          _outstandingRevenue = (collectionStats['total_balance'] ?? 0).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Advanced Analytics',
        actions: [
          NotificationBadge(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
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
              ? _buildLoadingState()
              : _errorMessage != null
                ? Center(
                    child: ErrorDisplayWidget(
                      error: _errorMessage!,
                      onRetry: _loadData,
                    ),
                  )
                : AppTheme.constrainedContent(
                    context: context,
                    maxWidth: 1600,
                    child: SingleChildScrollView(
                      padding: AppTheme.responsivePadding(context),
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        child: ResponsiveRowColumn(
                          rowOnMobile: false,
                          rowOnTablet: false, // Column on tablet for more width for charts
                          rowOnDesktop: true, // Split only on desktop
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Analytics Area
                            if (context.isDesktop)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSummaryGrid(context),
                                    const SizedBox(height: 32),
                                    _buildFinancialTrendSection(context),
                                    const SizedBox(height: 32),
                                    _buildChartsSection(context),
                                    if (!context.isDesktop) ...[
                                      const SizedBox(height: 32),
                                      _buildRecentTransactionsSection(context),
                                    ],
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSummaryGrid(context),
                                  const SizedBox(height: 32),
                                  _buildFinancialTrendSection(context),
                                  const SizedBox(height: 32),
                                  _buildChartsSection(context),
                                  if (!context.isDesktop) ...[
                                    const SizedBox(height: 32),
                                    _buildRecentTransactionsSection(context),
                                  ],
                                  const SizedBox(height: 48),
                                ],
                              ),
                            
                            // Recent Transactions Side Panel (Desktop Only)
                            if (context.isDesktop) ...[
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 1,
                                child: _buildRecentTransactionsSection(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
        ),
      ),
      floatingActionButton: CustomSpeedDial(
        tooltip: 'Quick Actions',
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_shopping_cart_rounded),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'New Transaction',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(sectionId: widget.sectionId ?? '', termId: '', classId: ''))),
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_add_rounded),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Add Student',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen())),
          ),
          SpeedDialChild(
            child: const Icon(Icons.how_to_reg_rounded),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Mark Attendance',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
          ),
          SpeedDialChild(
            child: const Icon(Icons.description_rounded),
            backgroundColor: AppTheme.neonEmerald,
            foregroundColor: Colors.white,
            label: 'Generate Report',
            onTap: _generateDetailedReport,
          ),
        ],
      ),
    );
  }

  bool _isPrinting = false;
  Future<void> _generateDetailedReport() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      
      final allTransactions = await transactionService.getTransactions(
        limit: 100,
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );
      
      final pdfService = PdfExportService();
      
      // Capture charts as images
      final growthChartImage = await _captureWidget(_growthChartKey);
      final collectionChartImage = await _captureWidget(_collectionChartKey);

      await pdfService.exportAnalyticsReport(
        schoolName: 'Executive Financial Report',
        totalIncome: _totalIncome,
        totalExpense: _totalExpense,
        netProfit: _netProfit,
        collectedRevenue: _collectedRevenue,
        outstandingRevenue: _outstandingRevenue,
        recentTransactions: allTransactions,
        growthChartImage: growthChartImage,
        collectionChartImage: collectionChartImage,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const DashboardCardSkeletonLoader(),
          const SizedBox(height: 24),
          const ChartSkeletonLoader(),
          const SizedBox(height: 24),
          const ChartSkeletonLoader(),
          const SizedBox(height: 32),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => const ListItemSkeletonLoader(),
          ),
        ],
      ),
    );
  }

  // Responsive summary grid instead of horizontal scroll
  Widget _buildSummaryGrid(BuildContext context) {
    final summaryCards = [
      _buildSummaryCard(
        context,
        'Total Income',
        Formatters.formatCurrency(_totalIncome),
        '+12.5%',
        AppTheme.neonEmerald,
        Icons.account_balance_wallet_rounded,
      ),
      _buildSummaryCard(
        context,
        'Expenses',
        Formatters.formatCurrency(_totalExpense),
        '-5.2%',
        AppTheme.errorColor,
        Icons.trending_down_rounded,
      ),
      _buildSummaryCard(
        context,
        'Net Profit',
        Formatters.formatCurrency(_netProfit),
        '+18.3%',
        AppTheme.neonPurple,
        Icons.insights_rounded,
      ),
    ];

    return ResponsiveGridView(
      mobileColumns: 1,
      tabletColumns: 3,
      desktopColumns: 3,
      spacing: 16,
      runSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: context.isMobile ? 1.8 : 1.3,
      children: summaryCards,
    );
  }

  // Responsive charts section
  Widget _buildChartsSection(BuildContext context) {
    return ResponsiveRowColumn(
      rowOnMobile: false,
      rowOnTablet: true, // Side by side on tablet
      rowOnDesktop: true,
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        if (context.isTablet || context.isDesktop)
          Expanded(child: _buildAttendanceBarChart(context))
        else
          _buildAttendanceBarChart(context),
        if (context.isMobile) const SizedBox(height: 16),
        if (context.isTablet || context.isDesktop)
          Expanded(child: _buildCollectionDonutChart(context))
        else
          _buildCollectionDonutChart(context),
      ],
    );
  }

  Widget _buildCollectionDonutChart(BuildContext context) {
    return RepaintBoundary(
      key: _collectionChartKey,
      child: FeeCollectionDonutChart(
        collected: _collectedRevenue,
        remaining: _outstandingRevenue,
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, String trend, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isDark ? 0.05 : 0.4,
        borderColor: color.withValues(alpha: 0.3),
        hasGlow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (trend.contains('+') ? AppTheme.neonEmerald : AppTheme.errorColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      trend.contains('+') ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: trend.contains('+') ? AppTheme.neonEmerald : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: trend.contains('+') ? AppTheme.neonEmerald : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTrendSection(BuildContext context) {
    return RepaintBoundary(
      key: _growthChartKey,
      child: FinancialGrowthChart(
        incomeData: _incomeSpots.map((s) => s.y).toList(),
        expenseData: _expenseSpots.map((s) => s.y).toList(),
        months: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      ),
    );
  }

  Widget _buildAttendanceBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isDark ? 0.05 : 0.4,
        borderColor: AppTheme.neonTeal.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 92, AppTheme.neonTeal),
                  _makeGroupData(1, 85, AppTheme.neonBlue),
                  _makeGroupData(2, 95, AppTheme.neonPurple),
                  _makeGroupData(3, 88, AppTheme.neonEmerald),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }



  Widget _buildRecentTransactionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: context.isDesktop 
        ? AppTheme.glassDecoration(
            context: context,
            opacity: 0.6,
            borderRadius: 24,
            borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          )
        : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!context.isDesktop)
                TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No transactions found', style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else
            ..._recentTransactions.map((tx) {
              final name = tx['description'] ?? 'Transaction';
              final amount = (tx['amount'] ?? 0).toDouble();
              final type = tx['category'] ?? tx['type'] ?? 'Fee';
              final isIncome = (tx['type'] == 'income');
              final color = isIncome ? AppTheme.neonEmerald : AppTheme.errorColor;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTransactionCard(context, name, Formatters.formatCurrency(amount), type, color),
              );
            }),
          if (context.isDesktop) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('View All Transactions'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, String name, String amount, String type, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.05),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(color == AppTheme.neonEmerald ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(type, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
