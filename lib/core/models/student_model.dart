class StudentModel {
  final String id;
  final String? prettyId;
  final String fullName;
  final String schoolId;
  final List<String> sectionIds; // Changed from single sectionId to list
  final String classId;
  final String? parentId;
  final String? admissionNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastModified;

  StudentModel({
    required this.id,
    this.prettyId,
    required this.fullName,
    required this.schoolId,
    this.sectionIds = const [], // Default to empty list
    required this.classId,
    this.parentId,
    this.admissionNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pretty_id': prettyId,
      'student_name': fullName,
      'school_id': schoolId,
      'section_ids': sectionIds, // Changed to list
      'class_id': classId,
      'parent_id': parentId,
      'admission_number': admissionNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_email': parentEmail,
      'photo_url': photoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': lastModified.toIso8601String(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseSectionIds(dynamic value) {
      // Handle both old single sectionId and new sectionIds array
      if (value == null) {
        // Check for legacy single section_id
        final legacySectionId = map['section_id'] ?? map['sectionId'];
        if (legacySectionId != null) {
          return [legacySectionId.toString()];
        }
        return [];
      }
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        return [value];
      }
      return [];
    }

    return StudentModel(
      id: (map['id'] ?? '').toString(),
      prettyId: map['pretty_id'] ?? map['prettyId'],
      fullName: map['student_name'] ?? map['full_name'] ?? map['fullName'] ?? '',
      schoolId: (map['school_id'] ?? map['schoolId'] ?? '').toString(),
      sectionIds: parseSectionIds(map['section_ids'] ?? map['sectionIds']),
      classId: (map['class_id'] ?? map['classId'] ?? '').toString(),
      parentId: (map['parent_id'] ?? map['parentId'])?.toString(),
      admissionNumber: map['admission_number'] ?? map['admissionNumber'],
      dateOfBirth: map['date_of_birth'] != null ? DateTime.tryParse(map['date_of_birth']) : null,
      gender: map['gender'],
      address: map['address'],
      parentName: map['parent_name'] ?? map['parentName'],
      parentPhone: map['parent_phone'] ?? map['parentPhone'],
      parentEmail: map['parent_email'] ?? map['parentEmail'],
      photoUrl: map['photo_url'] ?? map['photoUrl'],
      isActive: map['is_active'] ?? map['isActive'] ?? true,
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      lastModified: parseDate(map['updated_at'] ?? map['lastModified']),
    );
  }

  StudentModel copyWith({
    String? id,
    String? prettyId,
    String? fullName,
    String? schoolId,
    List<String>? sectionIds, // Changed from sectionId to sectionIds
    String? classId,
    String? parentId,
    String? admissionNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return StudentModel(
      id: id ?? this.id,
      prettyId: prettyId ?? this.prettyId,
      fullName: fullName ?? this.fullName,
      schoolId: schoolId ?? this.schoolId,
      sectionIds: sectionIds ?? this.sectionIds,
      classId: classId ?? this.classId,
      parentId: parentId ?? this.parentId,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
