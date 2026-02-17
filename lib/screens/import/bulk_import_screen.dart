import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart'; // Add csv package to pubspec
import '../../core/services/import_service_api.dart';

import '../../widgets/custom_app_bar.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  String _selectedType = 'students'; // students, parents, teachers
  PlatformFile? _pickedFile;
  bool _isLoading = false;
  List<List<dynamic>> _previewData = []; // First few rows for display
  List<List<dynamic>> _fullData = []; // Full parsed and processed data
  String? _uploadStatus;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true, // Needed for web
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
      
      // Auto-generate admission numbers for students if missing
      if (_selectedType == 'students' && csvTable.isNotEmpty) {
        final header = csvTable[0].map((e) => e.toString().trim().toLowerCase()).toList();
        int admIndex = header.indexOf('admission_number');
        if (admIndex == -1) admIndex = header.indexOf('admission number');
        
        // If column doesn't exist, add it
        if (admIndex == -1) {
          csvTable[0].add('admission_number');
          admIndex = csvTable[0].length - 1;
        }

        final currentYear = DateTime.now().year;
        
        // Iterate rows (skip header)
        for (int i = 1; i < csvTable.length; i++) {
          // Ensure row has enough columns
          while (csvTable[i].length < csvTable[0].length) {
            csvTable[i].add('');
          }
          
          final val = csvTable[i][admIndex].toString().trim();
          if (val.isEmpty) {
            // Generate: SCH-YEAR-RANDOM (using i for uniqueness in batch)
            // In a real app, maybe fetch last ID from backend or use a UUID subset.
            // Using a simple sequence for bulk import context.
            final generated = 'SCH-$currentYear-${(1000 + i).toString()}';
            csvTable[i][admIndex] = generated;
          }
        }
      }

      setState(() {
        _fullData = csvTable;
        _previewData = csvTable.take(6).toList(); // Preview first 5 rows + header
      });
    } catch (e) {
      // Failed to parse
      debugPrint('Error parsing CSV: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_fullData.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final service = Provider.of<ImportServiceApi>(context, listen: false);
      Map<String, dynamic> result;

      // Convert processed data back to CSV
      final String csvData = const ListToCsvConverter().convert(_fullData);
      final List<int> csvBytes = csvData.codeUnits;
      // Convert List<int> to Uint8List for compatibility
      final Uint8List fileBytes = Uint8List.fromList(csvBytes);

      if (_selectedType == 'students') {
        result = await service.importStudents(
          file: File(''), // Not used when bytes provided
          fileBytes: fileBytes,
          fileName: 'processed_students.csv',
        );
      } else {
        // For users, simple upload (unless we want to process them too later)
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
      appBar: const CustomAppBar(
        title: 'Bulk Import',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Import Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'students', child: Text('Students')),
                DropdownMenuItem(value: 'parents', child: Text('Parents')),
                DropdownMenuItem(value: 'teachers', child: Text('Teachers')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),
            
            // Guidelines
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CSV Format Guide:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_getFormatGuide()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Picker Area
            InkWell(
              onTap: _pickFile,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
                     const SizedBox(height: 8),
                     Text(
                       _pickedFile != null ? _pickedFile!.name : 'Click to select CSV file',
                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                     ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preview Table
            if (_previewData.isNotEmpty) ...[
               const Text('Preview (First 5 rows):', style: TextStyle(fontWeight: FontWeight.bold)),
               SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 child: DataTable(
                   columns: _previewData[0].map((e) => DataColumn(label: Text(e.toString()))).toList(),
                   rows: _previewData.skip(1).map((row) {
                     return DataRow(cells: row.map((cell) => DataCell(Text(cell.toString()))).toList());
                   }).toList(),
                 ),
               ),
               const SizedBox(height: 24),
            ],

            // Action Button
            if (_uploadStatus != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _uploadStatus!.startsWith('Success') ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_uploadStatus!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),

             FilledButton(
               onPressed: _fullData.isNotEmpty && !_isLoading ? _uploadFile : null,
               style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
               child: _isLoading 
                   ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                   : const Text('Start Import'),
             ),
          ],
        ),
      ),
    );
  }

  String _getFormatGuide() {
    if (_selectedType == 'students') {
      return 'Required columns: first_name, last_name, parent_email\nOptional: admission_number (Auto-generated if empty), dob, gender';
    } else {
      return 'Required columns: name, email, phone';
    }
  }
}
