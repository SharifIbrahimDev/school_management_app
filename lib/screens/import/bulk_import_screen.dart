import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import '../../core/services/import_service_api.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/success_sheet.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/config/api_config.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  String _selectedType = 'students';
  PlatformFile? _pickedFile;
  bool _isLoading = false;
  List<List<dynamic>> _previewData = [];
  List<List<dynamic>> _fullData = [];
  String? _uploadStatus;
  
  // Mapping logic
  Map<String, int> _fieldMapping = {};
  bool _showMapping = false;

  final Map<String, List<String>> _importTypeConfigs = {
    'students': ['first_name', 'last_name', 'parent_email', 'admission_number', 'dob', 'gender'],
    'parents': ['name', 'email', 'phone', 'address'],
    'teachers': ['name', 'email', 'phone', 'department'],
    'sections': ['section_name', 'description'],
    'classes': ['class_name', 'section_id', 'capacity'],
    'fees': ['fee_name', 'amount', 'fee_scope', 'section_id', 'class_id', 'session_id', 'term_id'],
    'map_parents': ['parent_email', 'student_admission_number'],
    'assign_teachers': ['teacher_email', 'class_id'],
    'ultimate_students': ['section_name', 'class_name', 'teacher_email', 'student_first_name', 'student_last_name', 'parent_email', 'admission_number'],
  };

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          _previewData = [];
          _fullData = [];
          _uploadStatus = null;
          _showMapping = false;
          _fieldMapping = {};
        });
        _parseAndProcessData();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  Future<void> _parseAndProcessData() async {
    if (_pickedFile == null) return;
    
    try {
      String csvString;
      if (kIsWeb) {
        final bytes = _pickedFile!.bytes!;
        csvString = utf8.decode(bytes);
      } else {
        final file = File(_pickedFile!.path!);
        csvString = await file.readAsString();
      }

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (csvTable.isEmpty) return;

      // Detect headers and build initial mapping
      final headers = csvTable[0].map((e) => e.toString().trim().toLowerCase()).toList();
      final requiredFields = _importTypeConfigs[_selectedType]!;
      
      for (var field in requiredFields) {
        int index = headers.indexOf(field.replaceAll('_', ' '));
        if (index == -1) index = headers.indexOf(field);
        if (index != -1) {
          _fieldMapping[field] = index;
        }
      }

      setState(() {
        _fullData = csvTable;
        _previewData = csvTable.take(15).toList();
        _showMapping = true;
      });
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
      if (mounted) AppSnackbar.showError(context, message: 'Invalid CSV format or encoding.');
    }
  }

  Future<void> _initiateImport() async {
    if (_fullData.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final service = Provider.of<ImportServiceApi>(context, listen: false);
      
      // 1. Prepare Data based on mapping
      List<List<dynamic>> processedData = [];
      final requiredFields = _importTypeConfigs[_selectedType]!;
      
      // Add Headers
      processedData.add(requiredFields);
      
      // Add Content rows
      for (int i = 1; i < _fullData.length; i++) {
        final row = _fullData[i];
        final List<dynamic> newRow = [];
        for (var field in requiredFields) {
          final index = _fieldMapping[field];
          if (index != null && index < row.length) {
            newRow.add(row[index]);
          } else {
            // Special handling for student admission if missing
            if (_selectedType == 'students' && field == 'admission_number') {
               newRow.add('SCH-${DateTime.now().year}-${1000 + i}');
            } else {
               newRow.add('');
            }
          }
        }
        processedData.add(newRow);
      }

      final String csvData = const ListToCsvConverter().convert(processedData);
      final Uint8List fileBytes = Uint8List.fromList(utf8.encode(csvData));

      String endpoint = ApiConfig.importStudentsBulk;
      Map<String, String> fields = {};

      switch (_selectedType) {
        case 'students':
          endpoint = ApiConfig.importStudentsBulk;
          break;
        case 'parents':
          endpoint = ApiConfig.importUsers;
          fields['role'] = 'parent';
          break;
        case 'teachers':
          endpoint = ApiConfig.importUsers;
          fields['role'] = 'teacher';
          break;
        case 'sections':
          endpoint = ApiConfig.importSections;
          break;
        case 'classes':
          endpoint = ApiConfig.importClasses;
          break;
        case 'fees':
          endpoint = ApiConfig.importFees;
          break;
        case 'map_parents':
          endpoint = ApiConfig.importMapParents;
          break;
        case 'assign_teachers':
          endpoint = ApiConfig.importAssignTeachers;
          break;
        case 'ultimate_students':
          endpoint = ApiConfig.importUltimateStudents;
          break;
      }

      final result = await service.bulkImport(
        endpoint: endpoint,
        file: File(''),
        fileBytes: fileBytes,
        fileName: 'import_${_selectedType}.csv',
        fields: fields,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = 'Success! Processed ${result['imported_count']} records.';
        });
        
        SuccessSheet.show(
          context,
          title: 'Import Successful',
          message: 'Successfully processed ${result['imported_count']} records into the system.',
          onButtonPressed: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = 'Import Failed: ${e.toString().replaceAll('Exception:', '')}';
        });
        AppSnackbar.showError(context, message: _uploadStatus!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'High-Volume Data Import'),
      body: Container(
        decoration: AppTheme.mainGradientDecoration(context),
        child: SingleChildScrollView(
          padding: AppTheme.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProjectHeader(),
              const SizedBox(height: 24),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildFormatDiscovery(),
              const SizedBox(height: 32),
              _buildFileDropZone(),
              if (_showMapping) ...[
                const SizedBox(height: 40),
                _buildFieldMappingSection(),
              ],
              if (_previewData.isNotEmpty) ...[
                const SizedBox(height: 40),
                _buildPreviewSection(),
              ],
              const SizedBox(height: 48),
              if (_uploadStatus != null) _buildStatusCard(),
              _buildActionSuite(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("AUTOMATED", style: TextStyle(color: AppTheme.neonEmerald, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            const Text("ENTERPRISE MIGRATION TOOL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondaryColor)),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "Import Core Databases",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.8, borderRadius: 28, hasGlow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SELECT WORKSTREAM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondaryColor, letterSpacing: 2.0)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'students', child: Text('Basic Students')),
              DropdownMenuItem(value: 'parents', child: Text('Parent Directory')),
              DropdownMenuItem(value: 'teachers', child: Text('Staff Roster')),
              DropdownMenuItem(value: 'sections', child: Text('School Sections')),
              DropdownMenuItem(value: 'classes', child: Text('Academic Classes')),
              DropdownMenuItem(value: 'fees', child: Text('Fee Structures')),
              DropdownMenuItem(value: 'map_parents', child: Text('Parent-Student Linking')),
              DropdownMenuItem(value: 'assign_teachers', child: Text('Teacher Assignments')),
              DropdownMenuItem(value: 'ultimate_students', child: Text('Ultimate Unified Import')),
            ],
            onChanged: _isLoading ? null : (val) => setState(() {
              _selectedType = val!;
              _pickedFile = null;
              _fullData = [];
              _previewData = [];
              _showMapping = false;
              _uploadStatus = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatDiscovery() {
    final fields = _importTypeConfigs[_selectedType]!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal_rounded, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text("Expected Schema", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fields.map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Text(f, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileDropZone() {
    final hasFile = _pickedFile != null;
    return InkWell(
      onTap: _isLoading ? null : _pickFile,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 180,
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.05,
          borderRadius: 32,
          borderColor: hasFile ? AppTheme.neonEmerald.withValues(alpha: 0.3) : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFile ? Icons.task_alt_rounded : Icons.snippet_folder_rounded,
              size: 48,
              color: hasFile ? AppTheme.neonEmerald : AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              hasFile ? _pickedFile!.name : "Synchronize Local File",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: hasFile ? AppTheme.neonEmerald : AppTheme.primaryColor),
            ),
            if (!hasFile)
              const Text("CSV or TXT documents supported", style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldMappingSection() {
    final requiredFields = _importTypeConfigs[_selectedType]!;
    final csvHeaders = _fullData[0].map((e) => e.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Field Mapping Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.4, borderRadius: 28),
          child: Column(
            children: requiredFields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(field, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        value: _fieldMapping[field],
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        hint: const Text("Select Column", style: TextStyle(fontSize: 12)),
                        items: List.generate(csvHeaders.length, (i) => DropdownMenuItem(
                          value: i,
                          child: Text(csvHeaders[i], style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis)),
                        )),
                        onChanged: (val) => setState(() => _fieldMapping[field] = val!),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final headers = _fullData[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Data Intelligence Preview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.2, borderRadius: 24),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor.withValues(alpha: 0.05)),
              columns: headers.map((e) => DataColumn(label: Text(e.toString().toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)))).toList(),
              rows: _previewData.skip(1).map((row) => DataRow(
                cells: row.map((c) => DataCell(Text(c.toString(), style: const TextStyle(fontSize: 12)))).toList(),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final isSuccess = _uploadStatus!.contains('Success');
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: (isSuccess ? AppTheme.neonEmerald : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isSuccess ? AppTheme.neonEmerald : Colors.red).withValues(alpha: 0.2)),
      ),
      child: Text(_uploadStatus!, style: TextStyle(fontWeight: FontWeight.bold, color: isSuccess ? AppTheme.successColorDark : Colors.red)),
    );
  }

  Widget _buildActionSuite() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _fullData.isNotEmpty && !_isLoading ? _initiateImport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
            child: _isLoading 
              ? const LoadingIndicator(size: 24, color: Colors.white)
              : const Text("EXECUTE MIGRATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5, color: Colors.white)),
          ),
        ),
        if (_pickedFile != null)
          TextButton(
            onPressed: () => setState(() { _pickedFile = null; _fullData = []; _previewData = []; _showMapping = false; }),
            child: const Text("Cancel Migration", style: TextStyle(color: Colors.redAccent)),
          ),
      ],
    );
  }
}
