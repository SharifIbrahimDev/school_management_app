abstract class IStorageService {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<void> saveUser(Map<String, dynamic> user);
  Future<Map<String, dynamic>?> getUser();
  Future<void> clearUser();
  Future<void> saveSchoolId(int schoolId);
  Future<int?> getSchoolId();
  Future<void> clearSchoolId();
  Future<void> clearAll();
  
  // Biometric methods
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  
  // Check if logged in
  Future<bool> isLoggedIn();
}
