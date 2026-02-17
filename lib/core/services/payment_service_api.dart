import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/payment_model.dart';
import 'api_service.dart';

class PaymentServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Get payment history
  Future<List<PaymentModel>> getPayments({int? studentId}) async {
    try {
      final queryParams = <String, String>{};
      if (studentId != null) {
        queryParams['student_id'] = studentId.toString();
      }

      final response = await _apiService.get(
        ApiConfig.payments,
        queryParameters: queryParams,
      );

      final List<dynamic> items = response['data'] ?? [];
      return items.map((item) => PaymentModel.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Error loading payments: $e');
    }
  }

  /// Initialize payment (Backend generates reference & calls Paystack)
  Future<Map<String, dynamic>> initializePayment({
    required int studentId,
    required int feeId,
    required double amount,
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.paymentsInitialize,
        body: {
          'student_id': studentId,
          'fee_id': feeId,
          'amount': amount,
          'email': email,
        },
      );

      return response;
    } catch (e) {
      throw Exception('Error initializing payment: $e');
    }
  }

  /// Verify payment
  Future<PaymentModel> verifyPayment({
    required String reference,
    int? studentId,
    int? feeId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.paymentsVerify,
        body: {
          'reference': reference,
          if (studentId != null) 'student_id': studentId,
          if (feeId != null) 'fee_id': feeId,
        },
      );

      return PaymentModel.fromMap(response['data']);
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }
}
