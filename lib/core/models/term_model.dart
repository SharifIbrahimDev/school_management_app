class TermModel {
  final String id;
  final String schoolId;
  final String sectionId;
  final String sessionId;
  final String termName;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isActive;

  TermModel({
    required this.id,
    required this.schoolId,
    required this.sectionId,
    required this.sessionId,
    required this.termName,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.lastModified,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'section_id': sectionId,
      'session_id': sessionId,
      'term_name': termName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': lastModified.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory TermModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return TermModel(
      id: (map['id'] ?? '').toString(),
      schoolId: (map['school_id'] ?? map['schoolId'] ?? '').toString(),
      sectionId: (map['section_id'] ?? map['sectionId'] ?? '').toString(),
      sessionId: (map['session_id'] ?? map['sessionId'] ?? '').toString(),
      termName: map['term_name'] ?? map['termName'] ?? '',
      startDate: parseDate(map['start_date'] ?? map['startDate']),
      endDate: parseDate(map['end_date'] ?? map['endDate']),
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      lastModified: parseDate(map['updated_at'] ?? map['lastModified']),
      isActive: map['is_active'] ?? map['isActive'] ?? true,
    );
  }

  TermModel copyWith({
    String? id,
    String? schoolId,
    String? sectionId,
    String? sessionId,
    String? termName,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isActive,
  }) {
    return TermModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      sectionId: sectionId ?? this.sectionId,
      sessionId: sessionId ?? this.sessionId,
      termName: termName ?? this.termName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
    );
  }
}
