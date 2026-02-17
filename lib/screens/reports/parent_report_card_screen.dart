import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/report_service_api.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';

class ParentReportCardScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const ParentReportCardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ParentReportCardScreen> createState() => _ParentReportCardScreenState();
}

class _ParentReportCardScreenState extends State<ParentReportCardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final reportService = Provider.of<ReportServiceApi>(context, listen: false);
      final data = await reportService.getAcademicReportCard(widget.studentId);
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report card: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_reportData.isEmpty) return;
    
    final results = _reportData['results'] as List? ?? [];
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No results to export')));
      return;
    }

    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final schoolName = "School Name";
    final student = _reportData['student'] ?? {};
    final className = student['class_model']?['class_name'] ?? "N/A";
    final sectionName = student['section']?['section_name'] ?? "N/A";

    // Detect term/session from first result if available
    String? termName;
    String? sessionName;
    if (results.isNotEmpty) {
      termName = results.first['exam']?['term']?['term_name'];
      sessionName = results.first['exam']?['session']?['session_name'];
    }

    await PdfExportService().exportReportCard(
      schoolName: schoolName,
      studentName: widget.studentName,
      className: className,
      sectionName: sectionName,
      results: results,
      termName: termName,
      sessionName: sessionName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _reportData['results'] as List? ?? [];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Report Card: ${widget.studentName}',
        actions: [
          if (!_isLoading && results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              onPressed: _exportPdf,
              tooltip: 'Download PDF',
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
        child: SafeArea(
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('No exam results found for this student.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildStudentSummary(),
                        const SizedBox(height: 24),
                        const Text('Subject Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        const SizedBox(height: 12),
                        ...results.map((res) => _buildResultCard(res)),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildStudentSummary() {
    final student = _reportData['student'] ?? {};
    final className = student['class_model']?['class_name'] ?? "N/A";
    final sectionName = student['section']?['section_name'] ?? "N/A";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.7, borderRadius: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(widget.studentName[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Class: $className | Section: $sectionName', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic res) {
    final subject = res['exam']?['subject']?['subject_name'] ?? 'Unknown Subject';
    final score = res['score']?.toString() ?? '-';
    final grade = res['grade']?.toString() ?? '-';
    final remark = res['remark']?.toString() ?? '-';
    final maxScore = res['exam']?['max_score']?.toString() ?? '100';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.5, borderRadius: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
               _ResultBadge(label: 'Score', value: '$score/$maxScore', color: Colors.blue),
               const SizedBox(width: 12),
               _ResultBadge(label: 'Grade', value: grade, color: _getGradeColor(grade)),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Remark', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(remark, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      case 'F': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: color),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.normal)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
