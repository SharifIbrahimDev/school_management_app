import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/custom_app_bar.dart';

class StudentReportCardScreen extends StatefulWidget {
  final int? studentId;

  const StudentReportCardScreen({super.key, this.studentId});

  @override
  State<StudentReportCardScreen> createState() => _StudentReportCardScreenState();
}

class _StudentReportCardScreenState extends State<StudentReportCardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, List<dynamic>> _groupedResults = {};

  @override
  void initState() {
    super.initState();
    _loadReportCard();
  }

  Future<void> _loadReportCard() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthServiceApi>(context, listen: false);
      final reportService = Provider.of<ReportServiceApi>(context, listen: false);
      
      // Determine student ID
      // If none provided, assume current user ID (parsed to int)
      final targetId = widget.studentId ?? int.tryParse(auth.currentUserModel?.id ?? '') ?? 0;

      if (targetId == 0) {
        throw Exception('Student ID could not be determined');
      }

      final data = await reportService.getAcademicReportCard(targetId);
      final results = data['results'] as List? ?? [];

      _groupResults(results);
      
      if (mounted) {
        setState(() => _isLoading = false);
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

  void _groupResults(List<dynamic> results) {
    _groupedResults = {};
    for (var r in results) {
      final exam = r['exam']?['title'] ?? 'Unknown Exam';
      if (!_groupedResults.containsKey(exam)) {
        _groupedResults[exam] = [];
      }
      _groupedResults[exam]!.add({
        'subject': r['exam']?['subject']?['subject_name'] ?? 'Unknown Subject',
        'score': r['score'] ?? 0.0,
        'grade': r['grade'] ?? '-',
        'remark': r['remark'] ?? '-',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Report Card',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ErrorDisplayWidget(error: _error!, onRetry: _loadReportCard)
                  : _groupedResults.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.assignment_outlined,
                          title: 'No Results',
                          message: 'Exam results will appear here.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _groupedResults.keys.length,
                          itemBuilder: (context, index) {
                            final examTitle = _groupedResults.keys.elementAt(index);
                            final exams = _groupedResults[examTitle]!;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: AppTheme.glassDecoration(
                                context: context,
                                opacity: 0.6,
                                borderRadius: 16,
                                hasGlow: true,
                                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.school, color: AppTheme.primaryColor),
                                        const SizedBox(width: 12),
                                        Text(
                                          examTitle,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Table(
                                      columnWidths: const {
                                        0: FlexColumnWidth(2.5),
                                        1: FlexColumnWidth(1),
                                        2: FlexColumnWidth(1),
                                        3: FlexColumnWidth(1.5),
                                      },
                                      border: TableBorder(
                                        horizontalInside: BorderSide(
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      children: [
                                        const TableRow(
                                          children: [
                                            Padding(padding: EdgeInsets.all(8), child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Remark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                          ],
                                        ),
                                        ...exams.map((r) => TableRow(
                                          children: [
                                            Padding(padding: const EdgeInsets.all(12), child: Text(r['subject'], style: const TextStyle(fontWeight: FontWeight.w500))),
                                            Padding(padding: const EdgeInsets.all(12), child: Text(r['score'].toString())),
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getGradeColor(r['grade']).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  r['grade'],
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _getGradeColor(r['grade']),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(padding: const EdgeInsets.all(12), child: Text(r['remark'], style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                                          ],
                                        )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.amber;
      case 'E': return Colors.deepOrange;
      case 'F': return Colors.red;
      default: return Colors.black;
    }
  }
}
