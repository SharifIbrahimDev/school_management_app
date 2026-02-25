import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'payment_service_api.dart';
import '../../widgets/app_snackbar.dart';

class PaymentService {
  static String get _publicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';
  static String get _secretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';

  static Future<void> processPayment({
    required BuildContext context,
    required double amount,
    required String email,
    required int studentId,
    required int feeId,
    required Function(String reference) onSuccess,
  }) async {
    try {
      final paymentService = Provider.of<PaymentServiceApi>(context, listen: false);

      // 1. Initialize payment on backend to get reference
      final initData = await paymentService.initializePayment(
        studentId: studentId,
        feeId: feeId,
        amount: amount,
        email: email,
      );

      final String reference = initData['reference'];

      if (!context.mounted) return;

      // 2. Open Paystack popup
      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: _publicKey,
        secretKey: _secretKey,
        context: context,
        customerEmail: email,
        amount: (amount * 100).toInt().toString(),
        reference: reference,
        callBackUrl: 'https://standard.paystack.co/close',
        onClosed: () {
          if (context.mounted) {
            AppSnackbar.showInfo(context, message: 'Payment cancelled or window closed.');
          }
        },
        onSuccess: () async {
          // 3. Verify payment on backend
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            await paymentService.verifyPayment(reference: reference);

            if (!context.mounted) return;
            Navigator.pop(context); // Close loading dialog

            AppSnackbar.showSuccess(context, message: 'Payment Successful! 🎉');
            onSuccess(reference);
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // Close loading dialog
              AppSnackbar.showError(context, message: 'Verification failed: $e');
            }
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(context, message: 'Payment error: $e');
      }
    }
  }

  static String generateReference() {
    return 'REF-${const Uuid().v4().substring(0, 8).toUpperCase()}';
  }
}

