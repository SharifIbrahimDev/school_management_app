import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'app_snackbar.dart';

class ErrorHandler {
  static void handleError(dynamic error, BuildContext context, [StackTrace? stackTrace]) {
    debugPrint('--- ERROR TRACKED ---');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack Trace: $stackTrace');
    }
    debugPrint('---------------------');

    String message = 'An unexpected error occurred';
    
    if (error is ApiException) {
      if (error.isUnauthorized) {
        message = 'Session expired. Please login again.';
        // Redirect to auth wrapper which handles login/dashboard states
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      } else if (error.isForbidden) {
        message = 'You do not have permission to perform this action.';
      } else if (error.isNotFound) {
        message = 'The requested resource was not found.';
      } else if (error.isValidationError) {
        message = error.message;
        if (error.errors != null) {
          message = error.toString(); 
        }
      } else if (error.isServerError) {
        message = 'Server error. Please try again later.';
      } else {
        message = error.message;
      }
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('Network is unreachable')) {
       message = 'No internet connection. Please check your network.';
    } else if (error.toString().contains('TimeoutException')) {
       message = 'Request timed out. Please check your connection.';
    }

    AppSnackbar.showError(context, message: message);
  }
}
