import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _showOTPField = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendResetOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulated API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _showOTPField = true;
    });

    if (mounted) {
      AppSnackbar.showSuccess(context, message: 'OTP sent to your email.');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length < 4) {
      AppSnackbar.showError(context, message: 'Please enter a valid OTP');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    if (mounted) {
      AppSnackbar.showSuccess(context, message: 'OTP Verified. Proceed to reset password.');
      // Future: Navigate to ResetPasswordScreen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.accentColor.withValues(alpha: 0.2),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _showOTPField ? 'Verify Identity' : 'Reset Password',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.2,
                            hasGlow: true,
                            borderRadius: 100,
                            borderColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                          child: Icon(
                            _showOTPField ? Icons.shield_outlined : Icons.lock_reset_rounded,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _showOTPField ? 'Enter OTP' : 'Forgot Password?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _showOTPField 
                            ? 'We\'ve sent a 6-digit verification code to your email address.'
                            : 'Enter your email address and we\'ll send you a recovery code to reset your password.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.7,
                            hasGlow: true,
                            borderRadius: 24,
                          ),
                          child: Form(
                            key: _formKey,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _showOTPField 
                                ? Column(
                                    key: const ValueKey('otp_step'),
                                    children: [
                                      CustomTextField(
                                        controller: _otpController,
                                        labelText: 'OTP Code',
                                        keyboardType: TextInputType.number,
                                        prefixIcon: Icons.password_rounded,
                                        maxLength: 6,
                                      ),
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        width: double.infinity,
                                        child: CustomButton(
                                          text: 'Verify OTP',
                                          onPressed: _isLoading ? null : _verifyOTP,
                                          isLoading: _isLoading,
                                          icon: Icons.check_circle_outline,
                                          backgroundColor: AppTheme.primaryColor,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(() => _showOTPField = false),
                                        child: const Text('Resend Code?', style: TextStyle(color: AppTheme.primaryColor)),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('email_step'),
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      CustomTextField(
                                        controller: _emailController,
                                        labelText: 'Email Address',
                                        keyboardType: TextInputType.emailAddress,
                                        prefixIcon: Icons.email_outlined,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        width: double.infinity,
                                        child: CustomButton(
                                          text: 'Send Recovery Code',
                                          onPressed: _isLoading ? null : _sendResetOTP,
                                          isLoading: _isLoading,
                                          icon: Icons.send_rounded,
                                          backgroundColor: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
