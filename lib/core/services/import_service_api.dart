import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class ImportServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Import Users (Parents/Teachers)
  Future<Map<String, dynamic>> importUsers({
    required File file,
    required String role,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final fields = {'role': role};
      final List<http.MultipartFile> files = [];

      if (fileBytes != null) {
        files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'import.csv',
          contentType: MediaType('text', 'csv'),
        ));
      } else if (file.path.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('text', 'csv'),
        ));
      } else {
        throw Exception('No file or data provided for import');
      }

      return await _apiService.multipart(
        ApiConfig.importUsers,
        fields: fields,
        files: files,
      );
    } catch (e) {
      throw Exception('Error importing users: $e');
    }
  }

  /// Import Students
  Future<Map<String, dynamic>> importStudents({
    required File file,
    int? schoolId,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    return await bulkImport(
      endpoint: ApiConfig.importStudentsBulk,
      file: file,
      fileBytes: fileBytes,
      fileName: fileName ?? 'students.csv',
      schoolId: schoolId,
    );
  }

  /// Generic Bulk Import
  Future<Map<String, dynamic>> bulkImport({
    required String endpoint,
    required File file,
    Uint8List? fileBytes,
    String? fileName,
    Map<String, String>? fields,
    int? schoolId,
  }) async {
    try {
      final effectiveFields = fields ?? <String, String>{};
      
      if (!effectiveFields.containsKey('school_id')) {
        final sid = schoolId ?? await StorageHelper.getSchoolId();
        if (sid != null) {
          effectiveFields['school_id'] = sid.toString();
        }
      }

      final List<http.MultipartFile> multipartFiles = [];

      if (fileBytes != null) {
        multipartFiles.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'import.csv',
          contentType: MediaType('text', 'csv'),
        ));
      } else if (file.path.isNotEmpty) {
        multipartFiles.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('text', 'csv'),
        ));
      } else {
        throw Exception('No file or data provided for import');
      }

      return await _apiService.multipart(
        endpoint,
        fields: effectiveFields,
        files: multipartFiles,
      );
    } catch (e) {
      throw Exception('Import error: $e');
    }
  }
}
