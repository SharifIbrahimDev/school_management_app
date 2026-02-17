import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_service_api.dart';
import '../../widgets/custom_app_bar.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _methodDist = [];
  Map<String, dynamic> _collectionStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<ReportServiceApi>(context, listen: false);
      
      final monthly = await service.getFinancialSummary();
      final methods = await service.getPaymentMethods();
      final stats = await service.getCollectionStats();

      if (mounted) {
        setState(() {
          _monthlyData = monthly;
          _methodDist = methods;
          _collectionStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Financial Reports'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Financial Reports'),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Financial Reports',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards
                Row(
                  children: [
                    Expanded(child: _buildKpiCard('Collected', _collectionStats['collected'], Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKpiCard('Outstanding', _collectionStats['outstanding'], Colors.red)),
                  ],
                ),
                const SizedBox(height: 24),

                // Line Chart
                Text('Monthly Income Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.4,
                    borderRadius: 16,
                    borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                            spots: _monthlyData.asMap().entries.map((e) {
                             final income = (e.value['income'] ?? 0.0) as num;
                             return FlSpot(e.key.toDouble(), income.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: AppTheme.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pie Chart
                Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.4,
                    borderRadius: 16,
                    borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: _methodDist.map((e) {
                        final method = (e['payment_method'] ?? 'unknown').toString();
                        final count = (e['count'] ?? 0) as num;
                        final isCard = method == 'card' || method == 'paystack' || method == 'bank_transfer';
                        return PieChartSectionData(
                          color: isCard ? AppTheme.primaryColor : Colors.orange,
                          value: count.toDouble(),
                          title: '$method\n${count.toInt()}',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Jan'; break;
      case 2: text = 'Mar'; break;
      case 4: text = 'May'; break;
      case 6: text = 'Jul'; break;
      case 8: text = 'Sep'; break;
      case 10: text = 'Nov'; break;
      default: return Container();
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }

  Widget _buildKpiCard(String title, num? value, Color color) {
    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 16,
        hasGlow: true,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              '₦${(value ?? 0).toStringAsFixed(0)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
