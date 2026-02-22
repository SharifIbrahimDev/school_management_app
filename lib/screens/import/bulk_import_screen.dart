import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import '../../core/services/import_service_api.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/responsive_widgets.dart';

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
        });
        _parseAndProcessData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _parseAndProcessData() async {
    if (_pickedFile == null) return;
    
    try {
      String csvString;
      if (kIsWeb) {
        final bytes = _pickedFile!.bytes!;
        csvString = String.fromCharCodes(bytes);
      } else {
        final file = File(_pickedFile!.path!);
        csvString = await file.readAsString();
      }

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (_selectedType == 'students' && csvTable.isNotEmpty) {
        final header = csvTable[0].map((e) => e.toString().trim().toLowerCase()).toList();
        int admIndex = header.indexOf('admission_number');
        if (admIndex == -1) admIndex = header.indexOf('admission number');
        
        if (admIndex == -1) {
          csvTable[0].add('admission_number');
          admIndex = csvTable[0].length - 1;
        }

        final currentYear = DateTime.now().year;
        
        for (int i = 1; i < csvTable.length; i++) {
          while (csvTable[i].length < csvTable[0].length) {
            csvTable[i].add('');
          }
          
          final val = csvTable[i][admIndex].toString().trim();
          if (val.isEmpty) {
            final generated = 'SCH-$currentYear-${(1000 + i).toString()}';
            csvTable[i][admIndex] = generated;
          }
        }
      }

      setState(() {
        _fullData = csvTable;
        _previewData = csvTable.take(10).toList(); // Show more rows in preview
      });
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_fullData.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final service = Provider.of<ImportServiceApi>(context, listen: false);
      Map<String, dynamic> result;

      final String csvData = const ListToCsvConverter().convert(_fullData);
      final List<int> csvBytes = csvData.codeUnits;
      final Uint8List fileBytes = Uint8List.fromList(csvBytes);

      if (_selectedType == 'students') {
        result = await service.importStudents(
          file: File(''),
          fileBytes: fileBytes,
          fileName: 'processed_students.csv',
        );
      } else {
        result = await service.importUsers(
          file: File(''),
          fileBytes: fileBytes,
          fileName: 'processed_users.csv',
          role: _selectedType == 'teachers' ? 'teacher' : 'parent',
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = 'Success! Imported ${result['imported_count']} records.';
          if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
             _uploadStatus = '$_uploadStatus\nErrors: ${(result['errors'] as List).length}';
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Import completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = 'Failed: ${e.toString().replaceAll('Exception:', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Data Migration Suite'),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildGuidelineCard(),
              const SizedBox(height: 32),
              _buildFilePicker(),
              if (_previewData.isNotEmpty) ...[
                const SizedBox(height: 40),
                _buildPreviewSection(),
              ],
              const SizedBox(height: 48),
              if (_uploadStatus != null) _buildStatusMessage(),
              _buildActionButtons(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SELECT DATA CATEGORY",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 1.5,
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
            items: const [
              DropdownMenuItem(value: 'students', child: Text('Student Database')),
              DropdownMenuItem(value: 'parents', child: Text('Parent Profiles')),
              DropdownMenuItem(value: 'teachers', child: Text('Faculty Members')),
            ],
            onChanged: _isLoading ? null : (val) {
              if (val != null) {
                setState(() {
                  _selectedType = val;
                  _pickedFile = null;
                  _previewData = [];
                  _uploadStatus = null;
                });
              }
            },
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neonBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.neonBlue, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Import Guidelines',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getFormatGuide(),
            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    final hasFile = _pickedFile != null;
    final color = hasFile ? AppTheme.neonEmerald : AppTheme.neonBlue;

    return InkWell(
      onTap: _isLoading ? null : _pickFile,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 200,
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.05,
          borderRadius: 32,
          borderColor: color.withValues(alpha: 0.3),
        ).copyWith(
          border: Border.all(color: color.withValues(alpha: 0.4), style: BorderStyle.solid, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              hasFile ? _pickedFile!.name : 'Drop file or Click to Browse',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFile ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB' : 'Standard CSV or TXT format supported',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Data Preview",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.2,
            borderRadius: 24,
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              columns: _previewData[0].map((e) => DataColumn(label: Text(e.toString().toUpperCase()))).toList(),
              rows: _previewData.skip(1).map((row) {
                return DataRow(cells: row.map((cell) => DataCell(Text(cell.toString()))).toList());
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    final isSuccess = _uploadStatus!.startsWith('Success');
    final color = isSuccess ? AppTheme.neonEmerald : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(isSuccess ? Icons.check_circle_rounded : Icons.error_rounded, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _uploadStatus!,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _fullData.isNotEmpty && !_isLoading ? _uploadFile : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            child: _isLoading 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 16),
                      Text("PROCESSING...", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ) 
                : const Text('INITIATE SYSTEM IMPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)),
          ),
        ),
        if (!_isLoading && _fullData.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : () => setState(() {
              _pickedFile = null;
              _fullData = [];
              _previewData = [];
              _uploadStatus = null;
            }),
            child: const Text("Clear Selection", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ],
    );
  }

  String _getFormatGuide() {
    if (_selectedType == 'students') {
      return '• Columns: first_name, last_name, parent_email\n• Optional: admission_number (Automatic if blank), dob, gender';
    } else {
      return '• Columns: name, email, phone\n• Optional: address, department';
    }
  }
}
