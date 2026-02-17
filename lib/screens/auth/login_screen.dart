import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import 'auth_wrapper.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/error_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkBiometrics();
  }

  Future<void> _loadSavedCredentials() async {
    final rememberMe = await StorageHelper.isRememberMeEnabled();
    if (rememberMe) {
      final creds = await StorageHelper.getCredentials();
      if (creds != null) {
        setState(() {
          _rememberMe = true;
          _emailController.text = creds['email'] ?? '';
          _passwordController.text = creds['password'] ?? '';
        });
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final canCheck = await authService.canCheckBiometrics;
    final enabled = await authService.isBiometricEnabled;
    setState(() {
      _canCheckBiometrics = canCheck && enabled;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await authService.login(email, password);

      // Save credentials if remember me is checked
      await StorageHelper.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await StorageHelper.saveCredentials(email, password);
      } else {
        await StorageHelper.clearCredentials();
      }

      if (!mounted) return;

      setState(() => _isLoading = false);
      AppSnackbar.showSuccess(context, message: 'Login successful!');
      
      // Navigate to /auth which will handle showing the Dashboard based on the now-authenticated state.
      // This ensures we always have AuthWrapper at the root, even if we were on a standalone login route.
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.handleError(e, context, stackTrace);
    }
  }
  Future<void> _loginWithBiometrics() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthServiceApi>(context, listen: false);

    try {
      final success = await authService.loginWithBiometrics();
      if (success) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppSnackbar.showSuccess(context, message: 'Biometric Login successful!');
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.handleError(e, context, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
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
          child: Row(
            children: [
              // Side graphic for desktop
              if (!context.isMobile && !context.isTablet)
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(40),
                    decoration: AppTheme.glassDecoration(
                      context: context,
                      opacity: 0.1,
                      borderRadius: 40,
                      hasGlow: true,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_rounded, size: 120, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 24),
                          Text(
                            "Safe & Secure",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "The modern standard for school management",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Login Form
              Expanded(
                flex: 1,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassDecoration(
                                context: context,
                                opacity: 0.2,
                                hasGlow: true,
                                borderColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                              ),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'School Financial App',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: -0.5,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage your school finances efficiently',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomTextField(
                                    controller: _emailController,
                                    labelText: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
                                        return 'Invalid email format';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    obscureText: _obscurePassword,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                          activeColor: theme.colorScheme.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Remember Me', style: TextStyle(fontSize: 14)),
                                      const Spacer(),
                                      if (_canCheckBiometrics)
                                        IconButton(
                                          icon: Icon(Icons.fingerprint_rounded, color: theme.colorScheme.primary, size: 28),
                                          onPressed: _loginWithBiometrics,
                                          tooltip: 'Biometric Login',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    child: CustomButton(
                                      text: 'Login',
                                      onPressed: _isLoading ? null : () => _login(context),
                                      isLoading: _isLoading,
                                      icon: Icons.login_rounded,
                                      backgroundColor: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isLoading) ...[
                            const SizedBox(height: 20),
                            const LoadingIndicator(message: 'Logging in...'),
                          ],
                          const SizedBox(height: 32),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignupScreen()),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
