import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/services/timetable_service_api.dart';
import '../core/models/timetable_model.dart';
import '../core/utils/app_theme.dart';
import 'loading_indicator.dart';

class TeacherScheduleCard extends StatefulWidget {
  const TeacherScheduleCard({super.key});

  @override
  State<TeacherScheduleCard> createState() => _TeacherScheduleCardState();
}

class _TeacherScheduleCardState extends State<TeacherScheduleCard> {
  bool _isLoading = true;
  List<TimetableModel> _schedule = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final service = Provider.of<TimetableServiceApi>(context, listen: false);
      final today = DateFormat('EEEE').format(DateTime.now());
      final data = await service.getTimetable(dayOfWeek: today);
      if (mounted) {
        setState(() {
          _schedule = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(context: context, opacity: 0.1),
        child: Text('Error loading schedule: $_errorMessage', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_schedule.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 20),
        child: Column(
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              'No classes scheduled for today!',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                "Today's Schedule (${DateFormat('MMM d').format(DateTime.now())})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _schedule.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _schedule[index];
            final startTime = DateFormat.jm().format(DateFormat('HH:mm:ss').parse(item.startTime));
            final endTime = DateFormat.jm().format(DateFormat('HH:mm:ss').parse(item.endTime));

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(
                context: context,
                opacity: 0.1,
                borderRadius: 16,
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subjectName ?? 'Unknown Subject',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.className} - ${item.sectionName}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(startTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(endTime, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
