import 'package:flutter/material.dart';
import '../core/utils/app_theme.dart';

class AppSnackbar {
  static void show(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 3),
        Color? backgroundColor,
        Color? textColor,
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: duration,
        backgroundColor: backgroundColor ?? AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  static void showError(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    show(
      context,
      message: message,
      duration: duration,
      backgroundColor: AppTheme.errorColor,
      textColor: Colors.white,
    );
  }

  static void showSuccess(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    show(
      context,
      message: message,
      duration: duration,
      backgroundColor: AppTheme.successColor,
      textColor: Colors.white,
    );
  }

  static void showWarning(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    show(
      context,
      message: message,
      duration: duration,
      backgroundColor: AppTheme.warningColor,
      textColor: Colors.black87,
    );
  }
}
