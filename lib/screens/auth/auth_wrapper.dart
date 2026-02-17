import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service_api.dart';
import '../dashboard/dashboard_wrapper.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      await authService.getCurrentUser();
    } catch (e, stackTrace) {
      debugPrint('AuthWrapper initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authService = context.watch<AuthServiceApi>();
    final user = authService.currentUser;

    if (user != null) {
      return const DashboardWrapper();
    }

    return const LoginScreen();
  }
}
