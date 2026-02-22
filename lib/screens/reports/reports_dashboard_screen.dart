import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/report_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/financial_chart.dart';
import '../../widgets/analytics_charts.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/responsive_widgets.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/utils/error_handler.dart';
import '../../widgets/error_display_widget.dart';
import '../../core/services/auth_service_api.dart';
import 'debtors_list_screen.dart';
import 'financial_report_screen.dart';
import '../transactions/transactions_list_screen.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _collectionStats;
  List<Map<String, dynamic>> _monthlySummary = [];
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
      
      final results = await Future.wait([
        reportService.getCollectionStats(),
        reportService.getFinancialSummary(),
        reportService.getPaymentMethods(),
      ]);

      if (mounted) {
        setState(() {
          _collectionStats = results[0] as Map<String, dynamic>;
          _monthlySummary = results[1] as List<Map<String, dynamic>>;
          _paymentMethods = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
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
        title: 'Financial Intelligence',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
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
        child: _isLoading
            ? const Center(child: LoadingIndicator(message: 'Generating financial intelligence...'))
            : AppTheme.constrainedContent(
                context: context,
                child: SingleChildScrollView(
                  padding: AppTheme.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveRowColumn(
                        rowOnMobile: false,
                        rowOnTablet: true,
                        rowOnDesktop: true,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!context.isMobile)
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildCollectionRateCard(),
                                  const SizedBox(height: 24),
                                  _buildMonthlyRevenueCard(),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                _buildCollectionRateCard(),
                                const SizedBox(height: 24),
                                _buildMonthlyRevenueCard(),
                              ],
                            ),
                          SizedBox(
                            width: context.isMobile ? 0 : 24,
                            height: context.isMobile ? 24 : 0,
                          ),
                          if (!context.isMobile)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildPaymentMethodsCard(),
                                  const SizedBox(height: 24),
                                  _buildReportActions(),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                _buildPaymentMethodsCard(),
                                const SizedBox(height: 24),
                                _buildReportActions(),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCollectionRateCard() {
    if (_collectionStats == null) return const SizedBox();

    final totalTarget = (_collectionStats!['total_expected'] as num?)?.toDouble() ?? 0.0;
    final totalCollected = (_collectionStats!['total_collected'] as num?)?.toDouble() ?? 0.0;
    final percentage = totalTarget > 0 ? (totalCollected / totalTarget) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 32,
        hasGlow: true,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fee Collection Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Overall session performance', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonEmerald.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart_rounded, color: AppTheme.neonEmerald),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 15,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonEmerald),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text('Collected', style: TextStyle(color: AppTheme.textSecondaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat('Expected', Formatters.formatCurrency(totalTarget), Colors.blue),
              _buildSimpleStat('Collected', Formatters.formatCurrency(totalCollected), AppTheme.neonEmerald),
              _buildSimpleStat('Outstanding', Formatters.formatCurrency(totalTarget - totalCollected), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMonthlyRevenueCard() {
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
          const Text('Revenue Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: NeonLineChart(
              title: 'Revenue History',
              spots: _monthlySummary.asMap().entries.map((e) {
                return FlSpot(
                  e.key.toDouble(), 
                  (e.value['total_amount'] as num?)?.toDouble() ?? 0.0
                );
              }).toList(),
              neonColor: AppTheme.neonEmerald,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
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
          const Text('Payment Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ..._paymentMethods.map((m) {
            final label = m['payment_method'] ?? 'Unknown';
            final amount = (m['total_amount'] as num?)?.toDouble() ?? 0.0;
            final count = m['transaction_count'] ?? 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payment_rounded, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('$count Transactions', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                      ],
                    ),
                  ),
                  Text(Formatters.formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReportActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('On-Demand Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildActionTile('Debtors Analysis', 'View students with outstanding balances', Icons.money_off_rounded, Colors.red, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtorsListScreen()));
        }),
        const SizedBox(height: 12),
        _buildActionTile('Inventory Report', 'School supply and asset tracking', Icons.inventory_2_rounded, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FinancialReportScreen()));
        }),
        const SizedBox(height: 12),
        _buildActionTile('Staff Payroll', 'Monthly salary and allowance summary', Icons.badge_rounded, Colors.blue, () {
          final authService = Provider.of<AuthServiceApi>(context, listen: false);
          final schoolId = authService.currentUserModel?.schoolId ?? '';
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => TransactionsListScreen(schoolId: schoolId)
            )
          );
        }),
      ],
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.05,
          borderRadius: 20,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
