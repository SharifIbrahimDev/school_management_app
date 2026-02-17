

class School {
  final String schoolId;
  final String schoolName;
  final String proprietorId;
  final String proprietorName;
  final String? shortCode;
  final String? description;
  final List<String> sectionIds;
  final DateTime createdAt;
  final DateTime lastModified;

  School({
    required this.schoolId,
    required this.schoolName,
    required this.proprietorId,
    required this.proprietorName,
    this.shortCode,
    this.description,
    this.sectionIds = const [],
    required this.createdAt,
    required this.lastModified,
  }) {
    if (schoolId.isEmpty) throw ArgumentError('schoolId cannot be empty');
    if (schoolName.trim().isEmpty) throw ArgumentError('schoolName cannot be empty');
    if (proprietorId.isEmpty) throw ArgumentError('proprietorId cannot be empty');
    if (proprietorName.trim().isEmpty) throw ArgumentError('proprietorName cannot be empty');
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'schoolName': schoolName.trim(),
      'proprietorId': proprietorId,
      'proprietorName': proprietorName.trim(),
      'shortCode': shortCode?.trim(),
      'description': description?.trim(),
      'sectionIds': sectionIds,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory School.fromMap(Map<String, dynamic> map) {
    final schoolId = map['schoolId'] as String? ?? '';
    final schoolName = map['schoolName'] as String? ?? '';
    final proprietorId = map['proprietorId'] as String? ?? '';
    final proprietorName = map['proprietorName'] as String? ?? '';
    if (schoolId.isEmpty) throw ArgumentError('schoolId cannot be empty');
    if (schoolName.isEmpty) throw ArgumentError('schoolName cannot be empty');
    if (proprietorId.isEmpty) throw ArgumentError('proprietorId cannot be empty');
    if (proprietorName.isEmpty) throw ArgumentError('proprietorName cannot be empty');

    return School(
      schoolId: schoolId,
      schoolName: schoolName,
      proprietorId: proprietorId,
      proprietorName: proprietorName,
      shortCode: map['shortCode'] as String?,
      description: map['description'] as String?,
      sectionIds: List<String>.from(map['sectionIds'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastModified: DateTime.tryParse(map['lastModified']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  School copyWith({
    String? schoolId,
    String? schoolName,
    String? proprietorId,
    String? proprietorName,
    String? shortCode,
    String? description,
    List<String>? sectionIds,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return School(
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      proprietorId: proprietorId ?? this.proprietorId,
      proprietorName: proprietorName ?? this.proprietorName,
      shortCode: shortCode ?? this.shortCode,
      description: description ?? this.description,
      sectionIds: sectionIds ?? this.sectionIds,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
