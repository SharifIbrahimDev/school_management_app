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
    try {
      final effectiveSchoolId = schoolId ?? await StorageHelper.getSchoolId();
      final fields = <String, String>{};
      if (effectiveSchoolId != null) {
        fields['school_id'] = effectiveSchoolId.toString();
      }

      final List<http.MultipartFile> files = [];

      if (fileBytes != null) {
        files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'students.csv',
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
        ApiConfig.importStudentsBulk,
        fields: fields,
        files: files,
      );
    } catch (e) {
      throw Exception('Error importing students: $e');
    }
  }
}
