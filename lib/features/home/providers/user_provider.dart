import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service_api.dart';
import '../../../core/models/user_model.dart';

/// Provides the current logged-in user model, mirroring AuthServiceApi.currentUserModel.
class UserProvider extends ChangeNotifier {
  final AuthServiceApi _authService;

  UserProvider(this._authService) {
    _authService.addListener(notifyListeners);
  }

  UserModel? get currentUser => _authService.currentUserModel;

  Future<void> refresh() => _authService.refreshUser();

  @override
  void dispose() {
    _authService.removeListener(notifyListeners);
    super.dispose();
  }
}
