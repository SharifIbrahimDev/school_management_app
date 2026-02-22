import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class TransactionServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Get transactions
  Future<List<Map<String, dynamic>>> getTransactions({
    int? sectionId,
    int? sessionId,
    int? termId,
    int? studentId,
    String? transactionType,
    String? paymentMethod,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int? limit,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (sessionId != null) queryParams['session_id'] = sessionId.toString();
      if (termId != null) queryParams['term_id'] = termId.toString();
      if (studentId != null) queryParams['student_id'] = studentId.toString();
      if (transactionType != null) queryParams['transaction_type'] = transactionType;
      if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (search != null) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final response = await _apiService.get(
        ApiConfig.transactions(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final transactions = data['data'] as List;
        return transactions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }
  
  // Get transaction by ID
  Future<Map<String, dynamic>?> getTransaction(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.get(
        ApiConfig.transaction(schoolId, id),
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      throw Exception('Error fetching transaction: $e');
    }
  }
  
  // Add transaction
  Future<Map<String, dynamic>> addTransaction({
    required int sectionId,
    int? sessionId,
    int? termId,
    int? studentId,
    required String transactionType,
    required double amount,
    required String paymentMethod,
    String? category,
    String? description,
    String? referenceNumber,
    int? feeId,
    required String transactionDate,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.post(
        ApiConfig.transactions(schoolId),
        body: {
          'section_id': sectionId,
          if (sessionId != null) 'session_id': sessionId,
          if (termId != null) 'term_id': termId,
          if (studentId != null) 'student_id': studentId,
          'transaction_type': transactionType,
          'amount': amount,
          'payment_method': paymentMethod,
          if (category != null) 'category': category,
          if (description != null) 'description': description,
          if (referenceNumber != null) 'reference_number': referenceNumber,
          if (feeId != null) 'fee_id': feeId,
          'transaction_date': transactionDate,
        },
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to add transaction');
      }
    } catch (e) {
      throw Exception('Error adding transaction: $e');
    }
  }
  
  // Update transaction
  Future<Map<String, dynamic>> updateTransaction(
    int id, {
    int? sectionId,
    int? sessionId,
    int? termId,
    int? studentId,
    String? transactionType,
    double? amount,
    String? paymentMethod,
    String? category,
    String? description,
    String? referenceNumber,
    String? transactionDate,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final body = <String, dynamic>{};
      if (sectionId != null) body['section_id'] = sectionId;
      if (sessionId != null) body['session_id'] = sessionId;
      if (termId != null) body['term_id'] = termId;
      if (studentId != null) body['student_id'] = studentId;
      if (transactionType != null) body['transaction_type'] = transactionType;
      if (amount != null) body['amount'] = amount;
      if (paymentMethod != null) body['payment_method'] = paymentMethod;
      if (category != null) body['category'] = category;
      if (description != null) body['description'] = description;
      if (referenceNumber != null) body['reference_number'] = referenceNumber;
      if (transactionDate != null) body['transaction_date'] = transactionDate;
      
      final response = await _apiService.put(
        ApiConfig.transaction(schoolId, id),
        body: body,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to update transaction');
      }
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }
  
  // Delete transaction
  Future<void> deleteTransaction(int id) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final response = await _apiService.delete(
        ApiConfig.transaction(schoolId, id),
      );
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }
  
  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats({
    int? sectionId,
    int? sessionId,
    int? termId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (sessionId != null) queryParams['session_id'] = sessionId.toString();
      if (termId != null) queryParams['term_id'] = termId.toString();
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final response = await _apiService.get(
        ApiConfig.transactionsDashboardStats(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }
  
  // Get transaction report
  Future<Map<String, dynamic>> getReport({
    required String startDate,
    required String endDate,
    int? sectionId,
    String? transactionType,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{
        'start_date': startDate,
        'end_date': endDate,
      };
      
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (transactionType != null) queryParams['transaction_type'] = transactionType;
      
      final response = await _apiService.get(
        ApiConfig.transactionsReport(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      throw Exception('Error fetching report: $e');
    }
  }
  
  // Get monthly summary
  Future<Map<String, dynamic>> getMonthlySummary({
    int? year,
    int? sectionId,
  }) async {
    try {
      final schoolId = await StorageHelper.getSchoolId();
      if (schoolId == null) throw Exception('School ID not found');
      
      final queryParams = <String, String>{};
      if (year != null) queryParams['year'] = year.toString();
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      
      final response = await _apiService.get(
        ApiConfig.transactionsMonthlySummary(schoolId),
        queryParameters: queryParams,
      );
      
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      throw Exception('Error fetching monthly summary: $e');
    }
  }
  
  // Get transactions by student
  Future<List<Map<String, dynamic>>> getTransactionsByStudent(int studentId) async {
    return getTransactions(studentId: studentId);
  }
}
