class Validators {
  // Validate non-empty string
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // Validate class name (e.g., JSS1A, SS3B)
  static String? validateClassName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Class name is required';
    }
    final classRegex = RegExp(r'^[A-Z0-9]+$');
    if (!classRegex.hasMatch(value.trim())) {
      return 'Class name must be alphanumeric (e.g., JSS1A)';
    }
    return null;
  }

  // Validate amount
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Enter a valid positive amount';
    }
    return null;
  }

  // Validate date
  static String? validateDate(DateTime? date, String fieldName) {
    if (date == null) {
      return '$fieldName is required';
    }
    if (date.isBefore(DateTime.now())) {
      return '$fieldName cannot be in the past';
    }
    return null;
  }
  // Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    // Optional: Add complexity checks
    // if (!value.contains(RegExp(r'[A-Z]'))) return 'Password must contain uppercase';
    // if (!value.contains(RegExp(r'[0-9]'))) return 'Password must contain number';
    return null;
  }
}
