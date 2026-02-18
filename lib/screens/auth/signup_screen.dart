import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_snackbar.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import 'auth_wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // School Information
  final _schoolNameController = TextEditingController();
  final _schoolShortCodeController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _schoolAddressController = TextEditingController();

  // Proprietor Information
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Proprietor phone
  final _addressController = TextEditingController(); // Proprietor address
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolShortCodeController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    _schoolAddressController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthServiceApi>(context, listen: false);

    try {
      await authService.onboardSchool(
        schoolName: _schoolNameController.text.trim(),
        shortCode: _schoolShortCodeController.text.trim().toUpperCase(),
        schoolAddress: _schoolAddressController.text.trim(),
        schoolPhone: _schoolPhoneController.text.trim(),
        schoolEmail: _schoolEmailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      
      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
        ),
      );
      AppSnackbar.showSuccess(context, message: 'School and account created successfully!');
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.handleError(e, context, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Create Account',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.2,
                            hasGlow: true,
                            borderRadius: 100, // Circle
                            borderColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                          child: Icon(Icons.school_rounded, size: 60, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 32),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // School Section
                              _buildSectionHeader('School Information', Icons.school_rounded),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _schoolNameController,
                                labelText: 'School Name',
                                prefixIcon: Icons.business_rounded,
                                validator: (v) => v!.isEmpty ? 'Please enter school name' : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _schoolShortCodeController,
                                labelText: 'School Short Code (e.g. BHS)',
                                prefixIcon: Icons.tag_rounded,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter a short code';
                                  if (v.length > 20) return 'Short code too long (max 20)';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _schoolEmailController,
                                labelText: 'School Email (Optional)',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _schoolPhoneController,
                                labelText: 'School Phone (Optional)',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.contact_phone_rounded,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _schoolAddressController,
                                labelText: 'School Address (Optional)',
                                prefixIcon: Icons.map_rounded,
                                maxLines: 2,
                              ),

                              const SizedBox(height: 32),
                              
                              // Proprietor Section
                              _buildSectionHeader('Proprietor Information', Icons.admin_panel_settings_rounded),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _fullNameController,
                                labelText: 'Full Name',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => v!.isEmpty ? 'Please enter your full name' : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _emailController,
                                labelText: 'Login Email',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (v) => v!.isEmpty ? 'Please enter your login email' : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter a password';
                                  if (value.length < 8) return 'Password must be at least 8 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Confirm Password',
                                obscureText: _obscureConfirmPassword,
                                prefixIcon: Icons.lock_reset_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please confirm your password';
                                  if (value != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              CustomButton(
                                text: 'Register School',
                                onPressed: _isLoading ? null : _signup,
                                isLoading: _isLoading,
                                backgroundColor: AppTheme.primaryColor,
                                icon: Icons.rocket_launch_rounded,
                              ),
                              if (_isLoading) ...[
                                const SizedBox(height: 16),
                                LoadingIndicator(
                                  message: 'Creating account...',
                                  color: AppTheme.primaryColor,
                                  size: 24.0,
                                ),
                              ],
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppTheme.primaryColor.withValues(alpha: 0.2))),
      ],
    );
  }
}
