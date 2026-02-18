import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../widgets/app_snackbar.dart';

class ErrorHandler {
  /// Maps any error object to a user-friendly message
  static String getFriendlyMessage(dynamic error) {
    if (error is String) {
      return _mapMessage(error);
    }

    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Your session has timed out for security. Just log in again to continue where you left off.';
      }
      if (error.statusCode == 403) {
        return 'You don\'t have permission to do this. If you think this is a mistake, please reach out to your administrator.';
      }
      if (error.statusCode == 404) {
        return 'We couldn\'t find the information you were looking for. Please try again or check your link.';
      }
      if (error.statusCode == 422) {
        // Validation errors usually come with a specific message from the server
        return error.message;
      }
      if (error.statusCode >= 500) {
        return 'Our servers are feeling a bit overwhelmed. We\'re working on it—please try again in a few moments.';
      }
      return error.message;
    }

    if (error is SocketException || error is HttpException) {
      return 'It looks like you\'re offline. Please check your internet connection and try again.';
    }

    if (error is TimeoutException) {
      return 'Connection is taking longer than expected. Please try again when you have a better signal.';
    }

    // Default case for unknown errors
    final errorMessage = error.toString().toLowerCase();
    return _mapMessage(errorMessage);
  }

  /// Centralized error handling for the entire app
  static void handleError(dynamic error, BuildContext context, [StackTrace? stackTrace]) {
    debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('Stacktrace: $stackTrace');
    
    final message = getFriendlyMessage(error);
    AppSnackbar.showError(context, message: message);
  }

  static String _mapMessage(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Internet connection issue. Please check your data or Wi-Fi and try again.';
    }
    
    if (lowerError.contains('invalid credentials') || lowerError.contains('wrong password')) {
      return 'The email or password you entered doesn\'t match our records. Please try again.';
    }

    if (lowerError.contains('email already exists') || lowerError.contains('already taken')) {
      return 'This email address is already registered. Would you like to log in instead?';
    }

    if (lowerError.contains('unexpected character') || lowerError.contains('format')) {
      return 'We received some confusing data from our servers. Please try refreshing the page.';
    }

    return 'Oops! Something went wrong on our end. We\'re looking into it, so please try again in a bit.';
  }
}
