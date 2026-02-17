import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';

import '../../widgets/custom_app_bar.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final List<String> times = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00'];

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Academic Timetable',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Schedule',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1),
                ),
                const SizedBox(height: 4),
                Text(
                  'Term 1 - 2025/2026',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: AppTheme.glassDecoration(
                      context: context, 
                      opacity: 0.6, 
                      blur: 20,
                      borderRadius: 24,
                      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 12,
                          headingRowHeight: 50,
                          dataRowMinHeight: 100,
                          dataRowMaxHeight: 120,
                          columns: [
                            const DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                            ...days.map((day) => DataColumn(label: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)))),
                          ],
                          rows: times.map((time) {
                            return DataRow(
                              cells: [
                                DataCell(Text(time, style: const TextStyle(fontWeight: FontWeight.w500))),
                                ...days.map((day) => DataCell(_buildSubjectBlock(day, time))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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

  Widget _buildSubjectBlock(String day, String time) {
    // Mock logic for displaying subjects
    final Map<String, dynamic>? subject = _getMockSubject(day, time);
    if (subject == null) return const SizedBox.shrink();

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: subject['gradient'],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (subject['color'] as Color).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            subject['name'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subject['room'],
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getMockSubject(String day, String time) {
    if (day == 'MON' && (time == '08:00' || time == '09:00')) {
      return {'name': 'MATH', 'room': 'RM 101', 'color': AppTheme.neonTeal, 'gradient': AppTheme.neonBlueGradient};
    }
    if (day == 'TUE' && (time == '10:00' || time == '11:00')) {
      return {'name': 'SCIENCE', 'room': 'LAB 2', 'color': AppTheme.neonPurple, 'gradient': AppTheme.neonPurpleGradient};
    }
    if (day == 'WED' && time == '09:00') {
      return {'name': 'ART', 'room': 'STUDIO', 'color': AppTheme.neonBlue, 'gradient': AppTheme.neonBlueGradient};
    }
    if (day == 'THU' && time == '12:00') {
      return {'name': 'HISTORY', 'room': 'RM 204', 'color': Colors.orange, 'gradient': const LinearGradient(colors: [Colors.orange, Colors.deepOrange])};
    }
    if (day == 'FRI' && time == '08:00') {
      return {'name': 'ENGLISH', 'room': 'RM 105', 'color': AppTheme.neonTeal, 'gradient': AppTheme.neonBlueGradient};
    }
    return null;
  }
}
