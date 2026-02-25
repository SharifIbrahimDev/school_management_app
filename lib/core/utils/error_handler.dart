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
        return 'Your session has expired. Please log in again to continue.';
      }
      if (error.statusCode == 403) {
        return 'You don\'t have permission for this action. Please contact your administrator.';
      }
      if (error.statusCode == 404) {
        return 'The requested information could not be found. It may have been moved or deleted.';
      }
      if (error.statusCode == 422) {
        return error.message;
      }
      if (error.statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      }
      if (error.statusCode >= 500) {
        return 'Our servers are temporarily unavailable. Please try again in a few moments.';
      }
      return error.message;
    }

    if (error is SocketException || error is HttpException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is TimeoutException) {
      return 'The connection timed out. Please check your internet and try again.';
    }

    if (error is FormatException) {
      return 'We received unexpected data. Please try again or contact support.';
    }

    // Default case for unknown errors
    final errorMessage = error.toString();
    return _mapMessage(errorMessage);
  }

  /// Get a short title for the error category
  static String getErrorTitle(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) return 'Session Expired';
      if (error.statusCode == 403) return 'Access Denied';
      if (error.statusCode == 404) return 'Not Found';
      if (error.statusCode == 429) return 'Too Many Requests';
      if (error.statusCode >= 500) return 'Server Error';
      return 'Request Failed';
    }

    if (error is SocketException || error is HttpException) {
      return 'No Connection';
    }

    if (error is TimeoutException) {
      return 'Connection Timeout';
    }

    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('socket')) {
      return 'Connection Issue';
    }
    if (errorStr.contains('invalid credentials') || errorStr.contains('wrong password') || errorStr.contains('unauthorized')) {
      return 'Login Failed';
    }
    if (errorStr.contains('permission') || errorStr.contains('forbidden')) {
      return 'Access Denied';
    }
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Not Found';
    }

    return 'Something Went Wrong';
  }

  /// Get an icon for the error category
  static IconData getErrorIcon(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('socket') || errorStr.contains('offline')) {
      return Icons.wifi_off_rounded;
    }
    if (errorStr.contains('timeout')) {
      return Icons.hourglass_empty_rounded;
    }
    if (errorStr.contains('permission') || errorStr.contains('forbidden') || errorStr.contains('403')) {
      return Icons.lock_outline_rounded;
    }
    if (errorStr.contains('401') || errorStr.contains('session') || errorStr.contains('unauthorized')) {
      return Icons.login_rounded;
    }
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return Icons.search_off_rounded;
    }
    if (errorStr.contains('500') || errorStr.contains('server')) {
      return Icons.cloud_off_rounded;
    }

    return Icons.warning_amber_rounded;
  }

  /// Centralized error handling for the entire app
  static void handleError(dynamic error, BuildContext context, [StackTrace? stackTrace]) {
    debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('Stacktrace: $stackTrace');
    
    final message = getFriendlyMessage(error);
    AppSnackbar.showError(context, message: message);
  }

  /// Show a premium error dialog for critical errors
  static void handleCriticalError(dynamic error, BuildContext context, {VoidCallback? onRetry}) {
    debugPrint('Critical Error: $error');
    
    final title = getErrorTitle(error);
    final message = getFriendlyMessage(error);
    
    AppSnackbar.showPremiumError(
      context,
      title: title,
      message: message,
      onRetry: onRetry,
    );
  }

  static String _mapMessage(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('socket')) {
      return 'No internet connection. Please check your Wi-Fi or mobile data and try again.';
    }

    if (lowerError.contains('timeout')) {
      return 'The connection timed out. Please check your internet and try again.';
    }
    
    if (lowerError.contains('invalid credentials') || lowerError.contains('wrong password')) {
      return 'Incorrect email or password. Please check your details and try again.';
    }

    if (lowerError.contains('email already exists') || lowerError.contains('already taken')) {
      return 'This email is already registered. Try logging in instead, or use a different email.';
    }

    if (lowerError.contains('unauthorized') || lowerError.contains('401') || lowerError.contains('unauthenticated')) {
      return 'Your session has expired. Please log in again.';
    }

    if (lowerError.contains('forbidden') || lowerError.contains('403') || lowerError.contains('permission')) {
      return 'You don\'t have permission for this action. Please contact your administrator.';
    }

    if (lowerError.contains('not found') || lowerError.contains('404')) {
      return 'The item you\'re looking for wasn\'t found. It may have been deleted or moved.';
    }

    if (lowerError.contains('validation') || lowerError.contains('422') || lowerError.contains('required field')) {
      return 'Please check your input and make sure all required fields are filled correctly.';
    }

    if (lowerError.contains('server') || lowerError.contains('500') || lowerError.contains('503')) {
      return 'Our servers are temporarily unavailable. Please try again in a few moments.';
    }

    if (lowerError.contains('unexpected character') || lowerError.contains('format') || lowerError.contains('type')) {
      return 'We received unexpected data from the server. Please try again.';
    }

    if (lowerError.contains('duplicate') || lowerError.contains('already exists')) {
      return 'This item already exists. Please use a different name or update the existing one.';
    }

    if (lowerError.contains('no data') || lowerError.contains('empty')) {
      return 'No data available at the moment. Please try again later.';
    }

    if (lowerError.contains('storage') || lowerError.contains('space')) {
      return 'Not enough storage space. Please free up some space and try again.';
    }

    return 'Something unexpected happened. Please try again, or contact support if the issue persists.';
  }
}
