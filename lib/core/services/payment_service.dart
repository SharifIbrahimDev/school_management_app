import 'package:flutter/material.dart';
// import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:uuid/uuid.dart';

class PaymentService {
  static const String _publicKey = "pk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"; // TODO: Replace with valid key

  static Future<void> initialize() async {
    // Paystack plugin initialization usually handled instance-wise
  }

  static Future<void> chargeCard({
    required BuildContext context,
    required double amount,
    required String email,
    required String reference,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    // Paystack is not web compatible. For now, we stub it.
    // In a real app, you'd use Paystack's web SDK or a JS interop.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Online payments are only supported on Mobile devices.')),
    );
    onError('Web payments not supported');
    /* 
    try {
      final charge = Charge()
        ..amount = (amount * 100).toInt() // In kobo
        ..email = email
        ..reference = reference
        ..currency = 'NGN';

      // Checkout
      CheckoutResponse response = await PaystackPlugin.checkout(
        context,
        method: CheckoutMethod.card, // Defaults to card and bank
        charge: charge,
        fullscreen: true,
        logo: const Icon(Icons.school, size: 24),
      );

      if (response.status == true) {
        onSuccess(response.reference ?? reference);
      } else {
        onError(response.message);
      }
    } catch (e) {
      onError(e.toString());
    }
    */
  }

  static String generateReference() {
    return 'REF-${const Uuid().v4().substring(0, 8).toUpperCase()}';
  }
}
