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
      final dataRows = _csvData!.length > 1 && _csvData![0].any((e) => e.toString().toLowerCase().contains('admission')) 
          ? _csvData!.sublist(1) 
          : _csvData!;

      for (final row in dataRows) {
        if (row.length >= 2) {
          final admissionNumber = row[0].toString().trim();
          final score = row[1].toString().trim();

          final student = _students.firstWhere(
            (s) => s['admission_number']?.toString().trim().toLowerCase() == admissionNumber.toLowerCase(),
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
    return Scaffold(
      appBar: const CustomAppBar(title: 'High-Scale Result Migration'),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildInstructionsCard(),
                      const SizedBox(height: 24),
                      _buildFileZone(),
                      if (_scoreMapping.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildMappingList(),
                        const SizedBox(height: 40),
                        _buildSubmitButton(),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.neonBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "AUTOMATED GRADING",
            style: TextStyle(color: AppTheme.neonBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.examTitle,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 24,
        borderColor: AppTheme.neonBlue.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded, color: AppTheme.neonBlue, size: 20),
              const SizedBox(width: 12),
              const Text('Template Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionPoint("Format: Standard CSV only"),
          _buildInstructionPoint("Col 1: Student Admission ID"),
          _buildInstructionPoint("Col 2: Numerical Raw Score"),
        ],
      ),
    );
  }

  Widget _buildInstructionPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.neonBlue, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFileZone() {
    final hasFile = _fileName != null;
    final color = hasFile ? AppTheme.neonEmerald : AppTheme.primaryColor;

    return InkWell(
      onTap: _isProcessing ? null : _pickFile,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.05,
          borderRadius: 28,
          borderColor: color.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            Icon(hasFile ? Icons.task_rounded : Icons.file_upload_outlined, size: 54, color: color),
            const SizedBox(height: 20),
            Text(
              hasFile ? _fileName! : 'Select Migration File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasFile) ...[
              const SizedBox(height: 8),
              Text(
                '${_scoreMapping.length} records identified',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMappingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mapping Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        ..._scoreMapping.entries.take(5).map((entry) {
          final student = _students.firstWhere((s) => s['id'] == entry.key, orElse: () => {});
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration(context: context, opacity: 0.1, borderRadius: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(student['student_name']?[0] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student['student_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(student['admission_number'] ?? '-', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.neonEmerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonEmerald)),
                ),
              ],
            ),
          );
        }),
        if (_scoreMapping.length > 5)
           Center(
             child: Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text("+ ${_scoreMapping.length - 5} more records identified", style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
             ),
           ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitResults,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonEmerald,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          shadowColor: AppTheme.neonEmerald.withValues(alpha: 0.3),
        ),
        child: const Text('PROCEED WITH IMPORT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
      ),
    );
  }
}
