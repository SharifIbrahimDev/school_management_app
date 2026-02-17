import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/utils/app_theme.dart';

class NeonLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final String title;
  final Color neonColor;
  final bool isCurved;

  const NeonLineChart({
    super.key,
    required this.spots,
    required this.title,
    this.neonColor = AppTheme.neonTeal,
    this.isCurved = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: isDark ? 0.05 : 0.4,
        borderColor: neonColor.withValues(alpha: 0.3),
        hasGlow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: neonColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: neonColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: isCurved,
                    color: neonColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          neonColor.withValues(alpha: 0.3),
                          neonColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceCircleChart extends StatelessWidget {
  final double percentage;
  final String label;

  const AttendanceCircleChart({
    super.key,
    required this.percentage,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonColor = AppTheme.neonTeal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.05, hasGlow: true, borderColor: neonColor.withValues(alpha: 0.3)),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 10,
                      backgroundColor: neonColor.withValues(alpha: 0.1),
                      color: neonColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percentage.toInt()}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Present',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class ResultProgressBar extends StatelessWidget {
  final String subject;
  final double score;
  final Color color;

  const ResultProgressBar({
    super.key,
    required this.subject,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(subject, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${score.toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
          ),
        ),
      ],
    );
  }
}
