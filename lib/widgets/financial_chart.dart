import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils/formatters.dart';

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
