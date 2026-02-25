import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/utils/formatters.dart';
import '../core/utils/app_theme.dart';

/// A professional bar chart widget for displaying financial data
class FinancialBarChart extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double cashInHand;
  final double bankBalance;

  const FinancialBarChart({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.cashInHand,
    required this.bankBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue() == 0 ? 10.0 : _getMaxValue() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => isDark 
                          ? const Color(0xFF334155) 
                          : Colors.white,
                      tooltipBorder: BorderSide(
                        color: isDark 
                            ? const Color(0xFF475569) 
                            : const Color(0xFFE2E8F0),
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_getLabel(group.x.toInt())}\n',
                          TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: Formatters.formatCurrency(rod.toY),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getLabel(value.toInt()),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCurrency(value),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getMaxValue() == 0 ? 1.0 : _getMaxValue() / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark 
                            ? const Color(0xFF334155) 
                            : const Color(0xFFE2E8F0),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _buildBarGroup(0, totalIncome, const Color(0xFF10B981)),
                    _buildBarGroup(1, totalExpenses, const Color(0xFFEF4444)),
                    _buildBarGroup(2, cashInHand, const Color(0xFF3B82F6)),
                    _buildBarGroup(3, bankBalance, const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _getMaxValue() * 1.2,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    // final theme = Theme.of(context);
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: const Color(0xFF10B981),
          label: 'Income',
          value: totalIncome,
        ),
        _LegendItem(
          color: const Color(0xFFEF4444),
          label: 'Expenses',
          value: totalExpenses,
        ),
        _LegendItem(
          color: const Color(0xFF3B82F6),
          label: 'Cash',
          value: cashInHand,
        ),
        _LegendItem(
          color: const Color(0xFF8B5CF6),
          label: 'Bank',
          value: bankBalance,
        ),
      ],
    );
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Income';
      case 1:
        return 'Expenses';
      case 2:
        return 'Cash';
      case 3:
        return 'Bank';
      default:
        return '';
    }
  }

  double _getMaxValue() {
    return [totalIncome, totalExpenses, cashInHand, bankBalance]
        .reduce((a, b) => a > b ? a : b);
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '₦${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '₦${(value / 1000).toStringAsFixed(0)}K';
    }
    return '₦${value.toStringAsFixed(0)}';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// A premium line chart for showing financial growth trends
class FinancialGrowthChart extends StatelessWidget {
  final List<double> incomeData;
  final List<double> expenseData;
  final List<String> months;

  const FinancialGrowthChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Growth Analysis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[value.toInt()],
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₦${value.toInt()}K',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          );
                        },
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: expenseData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: const Color(0xFFEF4444),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A specialized donut chart for showing fee collection progress
class FeeCollectionDonutChart extends StatelessWidget {
  final double collected;
  final double remaining;

  const FeeCollectionDonutChart({
    super.key,
    required this.collected,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = collected + remaining;
    final collectionPercentage = total > 0 ? (collected / total) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collection Status',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.neonTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${collectionPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppTheme.neonTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.neonEmerald,
                          value: collected,
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: AppTheme.errorColor.withValues(alpha: 0.2),
                          value: remaining,
                          title: '',
                          radius: 15,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Revenue',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        Text(
                          Formatters.formatCurrency(total),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Collected', collected, AppTheme.neonEmerald),
                _buildLegendItem('Outstanding', remaining, AppTheme.errorColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double amount, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
