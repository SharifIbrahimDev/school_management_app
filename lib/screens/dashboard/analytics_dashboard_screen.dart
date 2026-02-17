import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/analytics_charts.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/responsive_widgets.dart';
import '../../core/services/report_service_api.dart';
import '../../core/services/transaction_service_api.dart';
import '../../widgets/custom_app_bar.dart';

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
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reportService = Provider.of<ReportServiceApi>(context, listen: false);
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      
      final financials = await reportService.getFinancialSummary();
      final transactions = await transactionService.getTransactions(limit: 5);
      final paymentMethods = await reportService.getPaymentMethods();

      double income = 0;
      double expense = 0;
      List<FlSpot> spots = [];

      // Process monthly data (Assuming API returns list of {month: int, income: double, expense: double})
      // If API returns something else, we adapt. Based on typical patterns:
      
      // Initialize 12 months with 0
      Map<int, double> monthlyIncome = {for (var i = 1; i <= 12; i++) i: 0.0};

      for (var item in financials) {
        final double inc = (item['income'] ?? 0).toDouble();
        final double exp = (item['expense'] ?? 0).toDouble();
        final int month = item['month'] ?? 0; // 1-12
        
        income += inc;
        expense += exp;
        
        if (month >= 1 && month <= 12) {
          monthlyIncome[month] = inc;
        }
      }

      monthlyIncome.forEach((month, value) {
        spots.add(FlSpot((month - 1).toDouble(), value));
      });

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          _netProfit = income - expense;
          _incomeSpots = spots;
          _recentTransactions = transactions;
          _paymentMethods = paymentMethods;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Advanced Analytics',
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
              ? const Center(child: LoadingIndicator())
              : AppTheme.constrainedContent(
                  context: context,
                  maxWidth: 1600,
                  child: SingleChildScrollView(
                    padding: AppTheme.responsivePadding(context),
                    child: ResponsiveRowColumn(
                      rowOnMobile: false,
                      rowOnTablet: false, // Column on tablet for more width for charts
                      rowOnDesktop: true, // Split only on desktop
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Analytics Area
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text(context.isMobile ? 'Report' : 'Generate Detailed Report'),
        icon: const Icon(Icons.description_rounded),
        backgroundColor: AppTheme.neonEmerald,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Responsive summary grid instead of horizontal scroll
  Widget _buildSummaryGrid(BuildContext context) {
    final columns = context.isMobile ? 1 : (context.isTablet ? 3 : 3);
    
    final summaryCards = [
      _buildSummaryCard(
        context,
        'Total Income',
        NumberFormat.currency(symbol: '₦', decimalDigits: 0).format(_totalIncome),
        '+12.5%',
        AppTheme.neonEmerald,
        Icons.account_balance_wallet_rounded,
      ),
      _buildSummaryCard(
        context,
        'Expenses',
        NumberFormat.currency(symbol: '₦', decimalDigits: 0).format(_totalExpense),
        '-5.2%',
        AppTheme.errorColor,
        Icons.trending_down_rounded,
      ),
      _buildSummaryCard(
        context,
        'Net Profit',
        NumberFormat.currency(symbol: '₦', decimalDigits: 0).format(_netProfit),
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
        Expanded(child: _buildAttendanceBarChart(context)),
        if (context.isMobile) const SizedBox(height: 16),
        Expanded(child: _buildPaymentMethodPieChart(context)),
      ],
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
                  color: (trend.contains('+') ? AppTheme.neonEmerald : AppTheme.errorColor).withOpacity(0.1),
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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.2,
        borderRadius: 24,
      ),
      child: NeonLineChart(
        title: 'Fee Collection Trends (Yearly)',
        spots: _incomeSpots.isNotEmpty 
            ? _incomeSpots 
            : const [FlSpot(0, 0), FlSpot(11, 0)], // Empty state
        neonColor: AppTheme.neonBlue,
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

  Widget _buildPaymentMethodPieChart(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<PieChartSectionData> sections = [];
    if (_paymentMethods.isNotEmpty) {
      final colors = [AppTheme.neonTeal, AppTheme.neonBlue, AppTheme.neonPurple, Colors.orange];
      for (int i = 0; i < _paymentMethods.length; i++) {
        final pm = _paymentMethods[i];
        final val = (pm['percentage'] ?? pm['value'] ?? 10).toDouble();
        final title = (pm['method'] ?? 'Other').toString();
        sections.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: val,
            title: title.substring(0, 3).toUpperCase(),
            radius: 40,
            showTitle: true,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    } else {
       sections = [
        PieChartSectionData(color: Colors.grey, value: 100, title: 'N/A', radius: 40, showTitle: false),
      ];
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isDark ? 0.05 : 0.4,
        borderColor: AppTheme.neonPurple.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Sources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 20,
                sections: sections,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                child: _buildTransactionCard(context, name, NumberFormat.currency(symbol: '₦').format(amount), type, color),
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
