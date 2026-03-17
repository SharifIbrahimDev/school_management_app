import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service_api.dart';

/// Thin wrapper around the live AuthServiceApi, kept in features/auth
/// for architectural consistency. All actual logic lives in AuthServiceApi.
class AuthProvider extends ChangeNotifier {
  final AuthServiceApi _authService;

  AuthProvider(this._authService) {
    _authService.addListener(notifyListeners);
  }

  bool get isLoading => false; // AuthServiceApi handles loading state internally

  Future<void> login(String email, String password) =>
      _authService.login(email, password);

  Future<void> logout() => _authService.logout();

  @override
  void dispose() {
    _authService.removeListener(notifyListeners);
    super.dispose();
  }
}
