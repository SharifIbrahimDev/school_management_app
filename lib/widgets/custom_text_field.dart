import 'package:flutter/material.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/validators.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;
  final bool isRequired;
  final String? helperText;
  final int? maxLength;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.maxLines,
    this.obscureText = false,
    this.isRequired = false,
    this.helperText,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textSecondaryColor) : null,
        suffixIcon: suffixIcon,
        helperText: helperText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.brightness == Brightness.light
            ? AppTheme.backgroundColor
            : const Color(0xFF1E1E1E),
      ),
      onFieldSubmitted: onSubmitted,
      validator: validator ?? (isRequired ? (value) => Validators.validateRequired(value, labelText) : null),
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      obscureText: obscureText,
      maxLength: maxLength,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
