import 'package:flutter/foundation.dart';

class SectionModel {
  final String id;
  final String schoolId;
  final String sectionName;
  final String? aboutSection;
  final List<String> academicSessionIds;
  final List<String> classIds;
  final List<String> assignedPrincipalIds;
  final List<String> assignedBursarIds;
  final List<String> assignedTeacherIds;
  final List<String> parentIds;
  final DateTime createdAt;
  final DateTime lastModified;

  SectionModel({
    required this.id,
    required this.schoolId,
    required this.sectionName,
    this.aboutSection,
    this.academicSessionIds = const [],
    this.classIds = const [],
    this.assignedPrincipalIds = const [],
    this.assignedBursarIds = const [],
    this.assignedTeacherIds = const [],
    this.parentIds = const [],
    required this.createdAt,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SectionModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'section_name': sectionName,
      'about_section': aboutSection,
      'created_at': createdAt.toIso8601String(),
      'updated_at': lastModified.toIso8601String(),
    };
  }

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    try {
      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      return SectionModel(
        id: (map['id'] ?? '').toString(),
        schoolId: (map['school_id'] ?? map['schoolId'] ?? '').toString(),
        sectionName: map['section_name'] ?? map['sectionName'] ?? 'No Name',
        aboutSection: map['about_section'] ?? map['aboutSection'],
        academicSessionIds: [],
        classIds: [],
        assignedPrincipalIds: [],
        assignedBursarIds: [],
        assignedTeacherIds: [],
        parentIds: [],
        createdAt: parseDate(map['created_at'] ?? map['createdAt']),
        lastModified: parseDate(map['updated_at'] ?? map['lastModified']),
      );
    } catch (e, stack) {
      debugPrint('Error parsing SectionModel: $e');
      debugPrint('Map: $map');
      return SectionModel(
        id: (map['id'] ?? 'error').toString(),
        schoolId: '',
        sectionName: 'Error Loading Section',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
    }
  }

  SectionModel copyWith({
    String? id,
    String? schoolId,
    String? sectionName,
    String? aboutSection,
    List<String>? academicSessionIds,
    List<String>? classIds,
    List<String>? assignedPrincipalIds,
    List<String>? assignedBursarIds,
    List<String>? assignedTeacherIds,
    List<String>? parentIds,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return SectionModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      sectionName: sectionName ?? this.sectionName,
      aboutSection: aboutSection ?? this.aboutSection,
      academicSessionIds: academicSessionIds ?? this.academicSessionIds,
      classIds: classIds ?? this.classIds,
      assignedPrincipalIds: assignedPrincipalIds ?? this.assignedPrincipalIds,
      assignedBursarIds: assignedBursarIds ?? this.assignedBursarIds,
      assignedTeacherIds: assignedTeacherIds ?? this.assignedTeacherIds,
      parentIds: parentIds ?? this.parentIds,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
