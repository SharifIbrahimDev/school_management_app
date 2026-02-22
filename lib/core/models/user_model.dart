
enum UserRole { proprietor, principal, bursar, teacher, parent }

class UserModel {
  final String id;
  final String prettyId;
  final String? registrationId;

  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final UserRole role;

  final List<String> assignedSchools;
  final List<String> assignedSections;
  final List<String> assignedClasses;
  final List<String> assignedStudents;

  final DateTime createdAt;
  final DateTime lastModified;
  final String? schoolId;
  final String? sectionId;
  final DateTime? lastSignIn;
  final bool isActive;

  UserModel({
    required this.id,
    required this.prettyId,
    this.registrationId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.role,
    this.assignedSchools = const [],
    this.assignedSections = const [],
    this.assignedClasses = const [],
    this.assignedStudents = const [],
    required this.createdAt,
    required this.lastModified,
    this.schoolId,
    this.sectionId,
    this.lastSignIn,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pretty_id': prettyId,
      'registration_id': registrationId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'role': role.toString().split('.').last.toLowerCase(),
      'assigned_schools': assignedSchools,
      'assigned_sections': assignedSections,
      'assigned_classes': assignedClasses,
      'assigned_students': assignedStudents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': lastModified.toIso8601String(),
      'school_id': schoolId,
      'section_id': sectionId,
      'last_sign_in': lastSignIn?.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    // Handle both API (snake_case) and legacy (camelCase) keys
    return UserModel(
      id: (map['id'] ?? '').toString(),
      prettyId: (map['pretty_id'] ?? map['prettyId'] ?? map['id'] ?? '').toString(),
      registrationId: map['registration_id']?.toString() ?? map['registrationId']?.toString(),
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      role: _roleFromString(map['role']),
      assignedSchools: _parseList(map['assigned_schools'] ?? map['assignedSchools']),
      assignedSections: _parseList(map['assigned_sections'] ?? map['assignedSections']),
      assignedClasses: _parseList(map['assigned_classes'] ?? map['assignedClasses']),
      assignedStudents: _parseList(map['assigned_students'] ?? map['assignedStudents']),
      schoolId: map['school_id']?.toString() ?? map['schoolId']?.toString(),
      sectionId: map['section_id']?.toString() ?? map['sectionId']?.toString(),
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      lastModified: parseDate(map['updated_at'] ?? map['lastModified']),
      lastSignIn: parseDate(map['last_sign_in'] ?? map['lastSignIn']),
      isActive: parseBool(map['is_active'] ?? map['isActive']),
    );
  }

  static bool parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == '1' || s == 'true' || s == 'yes' || s == 'active';
    }
    return true;
  }

  static List<String> _parseList(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list.map((e) {
        if (e is Map) return (e['id'] ?? '').toString();
        return e.toString();
      }).toList();
    }
    return [];
  }

  static UserRole _roleFromString(dynamic role) {
    if (role == null) return UserRole.parent;
    final roleStr = role.toString().toLowerCase();
    return UserRole.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == roleStr,
      orElse: () => UserRole.parent,
    );
  }

  UserModel copyWith({
    String? id,
    String? prettyId,
    String? registrationId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    UserRole? role,
    List<String>? assignedSchools,
    List<String>? assignedSections,
    List<String>? assignedClasses,
    List<String>? assignedStudents,
    DateTime? createdAt,
    DateTime? lastModified,
    String? schoolId,
    String? sectionId,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      prettyId: prettyId ?? this.prettyId,
      registrationId: registrationId ?? this.registrationId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      role: role ?? this.role,
      assignedSchools: assignedSchools ?? this.assignedSchools,
      assignedSections: assignedSections ?? this.assignedSections,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      assignedStudents: assignedStudents ?? this.assignedStudents,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      schoolId: schoolId ?? this.schoolId,
      sectionId: sectionId ?? this.sectionId,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      isActive: isActive ?? isActive,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.proprietor:
        return 'Proprietor';
      case UserRole.principal:
        return 'Principal';
      case UserRole.bursar:
        return 'Bursar';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.parent:
        return 'Parent';
    }
  }

  String get initials {
    if (fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
