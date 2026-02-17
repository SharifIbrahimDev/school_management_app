import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../core/utils/app_theme.dart';
import '../../core/services/exam_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../widgets/app_snackbar.dart';

import '../../widgets/custom_app_bar.dart';

class BulkResultUploadScreen extends StatefulWidget {
  final int examId;
  final int classId;
  final int? sectionId;
  final String examTitle;

  const BulkResultUploadScreen({
    super.key,
    required this.examId,
    required this.classId,
    this.sectionId,
    required this.examTitle,
  });

  @override
  State<BulkResultUploadScreen> createState() => _BulkResultUploadScreenState();
}

class _BulkResultUploadScreenState extends State<BulkResultUploadScreen> {
  String? _fileName;
  List<List<dynamic>>? _csvData;
  List<Map<String, dynamic>> _students = [];
  final Map<int, String> _scoreMapping = {}; // studentId -> score
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final studentsData = await studentService.getStudents(
        classId: widget.classId,
        sectionId: widget.sectionId,
      );
      if (!mounted) return;
      setState(() {
        _students = studentsData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.showError(context, message: 'Error loading students: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final csvString = await file.readAsString();
        final csvData = const CsvToListConverter().convert(csvString);

        setState(() {
          _fileName = result.files.single.name;
          _csvData = csvData;
          _scoreMapping.clear();
        });

        _processCSV();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error reading CSV: $e');
      }
    }
  }

  void _processCSV() {
    if (_csvData == null || _csvData!.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Assume CSV format: Admission Number, Score
      // Skip header row if present
      final dataRows = _csvData!.length > 1 && _csvData![0].contains('Admission') 
          ? _csvData!.sublist(1) 
          : _csvData!;

      for (final row in dataRows) {
        if (row.length >= 2) {
          final admissionNumber = row[0].toString().trim();
          final score = row[1].toString().trim();

          // Find matching student
          final student = _students.firstWhere(
            (s) => s['admission_number']?.toString().trim() == admissionNumber,
            orElse: () => {},
          );

          if (student.isNotEmpty && student['id'] != null) {
            _scoreMapping[student['id']] = score;
          }
        }
      }

      setState(() => _isProcessing = false);
      
      if (_scoreMapping.isEmpty) {
        AppSnackbar.showError(context, message: 'No matching students found in CSV');
      } else {
        AppSnackbar.showSuccess(context, message: '${_scoreMapping.length} results mapped successfully');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error processing CSV: $e');
      }
    }
  }

  Future<void> _submitResults() async {
    if (_scoreMapping.isEmpty) {
      AppSnackbar.showError(context, message: 'No results to submit');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final examService = Provider.of<ExamServiceApi>(context, listen: false);
      
      // Prepare payload
      final List<Map<String, dynamic>> payload = [];
      for (final entry in _scoreMapping.entries) {
        payload.add({
          'student_id': entry.key,
          'score': double.tryParse(entry.value) ?? 0.0,
        });
      }

      await examService.saveResults(widget.examId, payload);

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Results uploaded successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.showError(context, message: 'Error uploading results: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Bulk Upload Results',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.accentColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.examTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload exam results via CSV file',
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      _buildInstructions(),
                      const SizedBox(height: 24),
                      _buildFilePickerSection(),
                      if (_csvData != null) ...[
                        const SizedBox(height: 24),
                        _buildMappingPreview(),
                      ],
                      const SizedBox(height: 32),
                      if (_scoreMapping.isNotEmpty)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitResults,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Submit Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('CSV Format Instructions', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your CSV file should have two columns:\n'
            '1. Admission Number\n'
            '2. Score\n\n'
            'Example:\n'
            'Admission Number, Score\n'
            'BHS-STU-001, 85\n'
            'BHS-STU-002, 92',
            style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 16),
      child: Column(
        children: [
          Icon(Icons.upload_file_rounded, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          if (_fileName != null) ...[
            Text(_fileName!, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_scoreMapping.length} results mapped', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
            label: Text(_fileName == null ? 'Select CSV File' : 'Change File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mapped Results Preview', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 12),
          if (_scoreMapping.isEmpty)
            Text('No results mapped. Check CSV format.', style: TextStyle(color: Colors.red[700]))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scoreMapping.length > 5 ? 5 : _scoreMapping.length,
              itemBuilder: (context, index) {
                final studentId = _scoreMapping.keys.elementAt(index);
                final score = _scoreMapping[studentId];
                final student = _students.firstWhere((s) => s['id'] == studentId, orElse: () => {});
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          student['student_name'] ?? student['name'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        student['admission_number'] ?? '-',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(score ?? '0', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (_scoreMapping.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('... and ${_scoreMapping.length - 5} more', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
        ],
      ),
    );
  }
}
