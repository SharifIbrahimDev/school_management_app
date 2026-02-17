import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class AuthServiceApi extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Current user data
  Map<String, dynamic>? _currentUser;
  
  Map<String, dynamic>? get currentUser => _currentUser;
  
  UserModel? get currentUserModel {
    if (_currentUser == null) return null;
    return UserModel.fromMap(_currentUser!);
  }
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>;
        
        if (token != null) {
          await _apiService.setToken(token);
        }
        
        // Extract school name if it's nested
        if (user['school'] != null && user['school'] is Map && user['school_name'] == null) {
          user['school_name'] = user['school']['name'];
        }
        
        await StorageHelper.saveUser(user);
        
        // Save school ID if available
        if (user['school_id'] != null) {
          final schoolId = user['school_id'] is int 
              ? user['school_id'] as int 
              : int.tryParse(user['school_id'].toString()) ?? 0;
          await StorageHelper.saveSchoolId(schoolId);
        }
        
        _currentUser = user;
        notifyListeners();
        
        return user;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }
  
  // Register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    required int schoolId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        body: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
          'school_id': schoolId,
        },
        requiresAuth: false,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        return user;
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.logout);
    } catch (e) {
      // Continue with logout even if API call fails
      print('Logout API error: $e');
    } finally {
      await _apiService.clearToken();
      await StorageHelper.clearAll();
      _currentUser = null;
    }
  }
  
  // Alias for logout (backward compatibility)
  Future<void> signOut() => logout();
  
  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Try to get from storage
    _currentUser = await StorageHelper.getUser();
    
    // If still null, try to fetch from API
    if (_currentUser == null && await StorageHelper.isLoggedIn()) {
      try {
        final response = await _apiService.get(ApiConfig.me);
        if (response['success'] == true) {
          _currentUser = response['data']['user'] as Map<String, dynamic>;
          await StorageHelper.saveUser(_currentUser!);
        }
      } catch (e) {
        print('Error fetching current user: $e');
      }
    }
    
    return _currentUser;
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await StorageHelper.isLoggedIn();
  }
  
  // Get user role
  Future<String?> getUserRole() async {
    final user = await getCurrentUser();
    return user?['role'] as String?;
  }
  
  // Get school ID
  Future<int?> getSchoolId() async {
    final schoolId = await StorageHelper.getSchoolId();
    if (schoolId != null) return schoolId;
    
    final user = await getCurrentUser();
    if (user != null && user['school_id'] != null) {
      final id = user['school_id'] is int 
          ? user['school_id'] as int 
          : int.tryParse(user['school_id'].toString()) ?? 0;
      await StorageHelper.saveSchoolId(id);
      return id;
    }
    
    return null;
  }
  
  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiService.post(
        ApiConfig.forgotPassword,
        body: {'email': email},
        requiresAuth: false,
      );
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      throw Exception('Forgot password error: $e');
    }
  }
  
  // Reset password
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.resetPassword,
        body: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        requiresAuth: false,
      );
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception('Reset password error: $e');
    }
  }
  
  // Update password
  Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.updatePassword,
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
      
      if (response['success'] == true) {
        return null; // Success
      } else {
        return response['message'] ?? 'Failed to update password';
      }
    } catch (e) {
      return 'Update password error: $e';
    }
  }

  // Update profile
  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.updateProfile,
        body: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'address': address,
        },
      );
      
      if (response['success'] == true) {
        final user = response['data'] as Map<String, dynamic>;
        await StorageHelper.saveUser(user);
        _currentUser = user;
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Update profile error: $e');
    }
  }

  // Alias for backward compatibility if needed, though we should update the screen
  Future<String?> reauthenticateAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) => updatePassword(currentPassword: currentPassword, newPassword: newPassword);

  /// Onboard a new school and its proprietor
  Future<Map<String, dynamic>> onboardSchool({
    required String schoolName,
    required String shortCode,
    String? schoolAddress,
    String? schoolPhone,
    String? schoolEmail,
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.onboardSchool,
        body: {
          'school_name': schoolName,
          'short_code': shortCode,
          'school_address': schoolAddress,
          'school_phone': schoolPhone,
          'school_email': schoolEmail,
          'full_name': fullName,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        requiresAuth: false,
      );
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>;
        final school = data['school'] as Map<String, dynamic>;
        
        if (token != null) {
          await _apiService.setToken(token);
        }
        
        await StorageHelper.saveUser(user);
        final schoolId = school['id'] is int 
            ? school['id'] as int 
            : int.tryParse(school['id'].toString()) ?? 0;
        await StorageHelper.saveSchoolId(schoolId);
        
        _currentUser = user;
        notifyListeners();
        
        return data;
      } else {
        throw Exception(response['message'] ?? 'Onboarding failed');
      }
    } catch (e) {
      throw Exception('Onboarding error: $e');
    }
  }

  /// Refresh current user data from API
  Future<Map<String, dynamic>?> refreshUser() async {
    try {
      final response = await _apiService.get(ApiConfig.me);
      if (response['success'] == true) {
        _currentUser = response['data']['user'] as Map<String, dynamic>;
        await StorageHelper.saveUser(_currentUser!);
        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
    return _currentUser;
  }

  // --- Biometric Authentication ---

  Future<bool> get isBiometricEnabled => StorageHelper.isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled) async {
    await StorageHelper.setBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<bool> get canCheckBiometrics async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    if (kIsWeb) return false;
    final isAvailable = await canCheckBiometrics;
    if (!isAvailable) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Attempt to login using cached token and biometrics
  Future<bool> loginWithBiometrics() async {
    final enabled = await isBiometricEnabled;
    if (!enabled) return false;

    final success = await authenticateBiometric();
    if (success) {
      // If biometric success, verify we have a valid token
      final token = await StorageHelper.getToken();
      if (token != null) {
        await _apiService.setToken(token);
        await getCurrentUser(); // Refresh user data
        return true;
      }
    }
    return false;
  }
}
