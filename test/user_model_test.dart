import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_app/core/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    final testMap = {
      'id': '1',
      'pretty_id': 'USR-001',
      'full_name': 'Test User',
      'email': 'test@example.com',
      'phone_number': '1234567890',
      'address': '123 Test St',
      'role': 'proprietor',
      'created_at': '2023-01-01T00:00:00Z',
      'updated_at': '2023-01-01T00:00:00Z',
      'is_active': 1,
    };

    test('should create UserModel from map', () {
      final user = UserModel.fromMap(testMap);
      expect(user.id, '1');
      expect(user.fullName, 'Test User');
      expect(user.role, UserRole.proprietor);
      expect(user.isActive, true);
    });

    test('should convert UserModel to map', () {
      final user = UserModel.fromMap(testMap);
      final map = user.toMap();
      expect(map['id'], '1');
      expect(map['full_name'], 'Test User');
      expect(map['role'], 'proprietor');
      expect(map['is_active'], true);
    });

    test('copyWith should work correctly (including isActive fix)', () {
      final user = UserModel.fromMap(testMap);
      
      // Test updating fullName
      final updatedUser = user.copyWith(fullName: 'New Name');
      expect(updatedUser.fullName, 'New Name');
      expect(updatedUser.id, user.id);
      
      // Test updating isActive (the fix we made)
      final deactivatedUser = user.copyWith(isActive: false);
      expect(deactivatedUser.isActive, false);
      
      final reactivatedUser = deactivatedUser.copyWith(isActive: true);
      expect(reactivatedUser.isActive, true);
    });

    test('initials should return correct value', () {
      final user1 = UserModel.fromMap(testMap); // "Test User"
      expect(user1.initials, 'TU');

      final user2 = user1.copyWith(fullName: 'John');
      expect(user2.initials, 'J');

      final user3 = user1.copyWith(fullName: 'John Quincy Adams');
      expect(user3.initials, 'JA');
    });

    test('roleDisplayName should return correct value', () {
      final user = UserModel.fromMap(testMap);
      expect(user.roleDisplayName, 'Proprietor');
    });
  });
}
