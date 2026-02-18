class Validators {
  // Validate non-empty string
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide the $fieldName.';
    }
    return null;
  }

  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'We need your email address to continue.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'That doesn\'t look like a valid email address. Could you double-check it?';
    }
    return null;
  }

  // Validate phone number (exactly 11 digits)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'A phone number is required so we can stay in touch.';
    }
    
    // Remove any spaces or dashes
    final cleaned = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it's all digits and exactly 11 digits long
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'The phone number should only contain numbers.';
    }
    
    if (cleaned.length != 11) {
      return 'Please enter a complete 11-digit phone number.';
    }
    
    return null;
  }

  // Validate class name (e.g., JSS1A, SS3B)
  static String? validateClassName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a name for the class.';
    }
    final classRegex = RegExp(r'^[A-Z0-9]+$');
    if (!classRegex.hasMatch(value.trim())) {
      return 'Please use letters and numbers only, like "JSS1A".';
    }
    return null;
  }

  // Validate amount
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the amount.';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Please provide a valid amount greater than zero.';
    }
    return null;
  }

  // Validate date
  static String? validateDate(DateTime? date, String fieldName) {
    if (date == null) {
      return 'Please select a $fieldName.';
    }
    if (date.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      return 'The $fieldName can\'t be in the past. Please choose a future date.';
    }
    return null;
  }

  // Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A password is required to keep your account safe.';
    }
    if (value.length < 8) {
      return 'For your security, please use at least 8 characters.';
    }
    return null;
  }
}
