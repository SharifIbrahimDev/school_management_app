import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/student_model.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class StudentServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get students
  Future<List<Map<String, dynamic>>> getStudents({
    int? sectionId,
    int? classId,
    int? parentId,
    bool? isActive,
    String? search,
    int? limit,
    int page = 1,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (parentId != null) queryParams['parent_id'] = parentId.toString();
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      if (search != null) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final response = await _apiService.get(
        ApiConfig.students(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final students = data['data'] as List;
        return students.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching students: $e');
    }
  }
  
  // Search students
  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    return getStudents(search: query);
  }
  
  // Get student by ID
  Future<Map<String, dynamic>?> getStudent(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.student(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching student: $e');
    }
  }
  
  // Add student
  Future<Map<String, dynamic>> addStudent({
    int? sectionId,
    int? classId,
    required String studentName,
    String? admissionNumber,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? photoUrl,
    int? parentId,
    bool isActive = true,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.students(schoolId),
        body: {
          if (sectionId != null) 'section_id': sectionId,
          if (classId != null) 'class_id': classId,
          'student_name': studentName,
          if (admissionNumber != null) 'admission_number': admissionNumber,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          if (gender != null) 'gender': gender,
          if (address != null) 'address': address,
          if (parentName != null) 'parent_name': parentName,
          if (parentPhone != null) 'parent_phone': parentPhone,
          if (parentEmail != null) 'parent_email': parentEmail,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (parentId != null) 'parent_id': parentId,
          'is_active': isActive,
        },
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to add student');
      }
    } catch (e) {
      throw Exception('Error adding student: $e');
    }
  }

  // Create student (alias for addStudent)
  Future<Map<String, dynamic>> createStudent({
    int? sectionId,
    int? classId,
    required String studentName,
    String? admissionNumber,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? photoUrl,
    int? parentId,
    bool isActive = true,
  }) => addStudent(
    sectionId: sectionId,
    classId: classId,
    studentName: studentName,
    admissionNumber: admissionNumber,
    dateOfBirth: dateOfBirth,
    gender: gender,
    address: address,
    parentName: parentName,
    parentPhone: parentPhone,
    parentEmail: parentEmail,
    photoUrl: photoUrl,
    parentId: parentId,
    isActive: isActive,
  );
  
  // Update student
  Future<Map<String, dynamic>> updateStudent(
    int id, {
    List<int>? sectionIds, // Changed to List
    int? classId,
    String? studentName,
    String? admissionNumber,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? photoUrl,
    int? parentId,
    bool? isActive,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final body = <String, dynamic>{};
      if (sectionIds != null) body['section_ids'] = sectionIds; // Changed to array
      if (classId != null) body['class_id'] = classId;
      if (studentName != null) body['student_name'] = studentName;
      if (admissionNumber != null) body['admission_number'] = admissionNumber;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (gender != null) body['gender'] = gender;
      if (address != null) body['address'] = address;
      if (parentName != null) body['parent_name'] = parentName;
      if (parentPhone != null) body['parent_phone'] = parentPhone;
      if (parentEmail != null) body['parent_email'] = parentEmail;
      if (photoUrl != null) body['photo_url'] = photoUrl;
      if (parentId != null) body['parent_id'] = parentId;
      if (isActive != null) body['is_active'] = isActive;
      
      final response = await _apiService.put(
        ApiConfig.student(schoolId, id),
        body: body,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update student');
      }
    } catch (e) {
      throw Exception('Error updating student: $e');
    }
  }
  
  // Delete student
  Future<void> deleteStudent(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.student(schoolId, id),
      );
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete student');
      }
    } catch (e) {
      throw Exception('Error deleting student: $e');
    }
  }
  
  // Get student transactions
  Future<List<Map<String, dynamic>>> getStudentTransactions(int studentId) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.studentTransactions(schoolId, studentId),
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final transactions = data['data'] as List;
        return transactions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching student transactions: $e');
    }
  }
  
  // Get student payment summary
  Future<Map<String, dynamic>> getStudentPaymentSummary(int studentId) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.studentPaymentSummary(schoolId, studentId),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      throw Exception('Error fetching payment summary: $e');
    }
  }
  
  // Bulk import students
  Future<Map<String, dynamic>> importStudents(
    List<Map<String, dynamic>> students,
  ) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.studentsImport(schoolId),
        body: {'students': students},
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to import students');
      }
    } catch (e) {
      throw Exception('Error importing students: $e');
    }
  }

  // Assign parent to student
  Future<String> assignParentToStudent({
    required String schoolId,
    required String sectionId,
    required String classId,
    required String studentId,
    required String? parentId,
  }) async {
    try {
      final response = await updateStudent(
        int.parse(studentId),
        parentId: parentId != null ? int.parse(parentId) : null,
      );
      return response['message'] ?? 'Parent assigned successfully';
    } catch (e) {
      throw Exception('Error assigning parent: $e');
    }
  }

  // Link student to sections
  Future<String> linkStudentToSections({
    required int studentId,
    required List<int> sectionIds,
  }) async {
    try {
      final response = await updateStudent(
        studentId,
        sectionIds: sectionIds,
      );
      return response['message'] ?? 'Sections linked successfully';
    } catch (e) {
      throw Exception('Error linking sections: $e');
    }
  }

  // Unlink student from specific section
  Future<String> unlinkStudentFromSection({
    required int studentId,
    required int sectionId,
  }) async {
    try {
      // First get current student data
      final studentData = await getStudent(studentId);
      if (studentData == null) {
        throw Exception('Student not found');
      }

      final student = StudentModel.fromMap(studentData);
      final updatedSectionIds = student.sectionIds
          .where((id) => id != sectionId.toString())
          .map((id) => int.tryParse(id) ?? 0)
          .toList();

      final response = await updateStudent(
        studentId,
        sectionIds: updatedSectionIds,
      );
      return response['message'] ?? 'Section unlinked successfully';
    } catch (e) {
      throw Exception('Error unlinking section: $e');
    }
  }
}
