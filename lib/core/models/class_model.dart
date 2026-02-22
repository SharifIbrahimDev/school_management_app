import 'package:flutter/foundation.dart';

class ClassModel {
  final String id;
  final String name;
  final String schoolId;
  final String sectionId;
  final String? formTeacherId;
  String? get assignedTeacherId => formTeacherId;
  String? get assignedTeacherUserId => formTeacherId;
  final int? capacity;
  final bool isActive;
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime lastModified;

  ClassModel({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.sectionId,
    this.formTeacherId,
    this.capacity,
    this.isActive = true,
    this.studentIds = const [],
    required this.createdAt,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_name': name,
      'school_id': schoolId,
      'section_id': sectionId,
      'form_teacher_id': formTeacherId,
      'capacity': capacity,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': lastModified.toIso8601String(),
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    try {
      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      return ClassModel(
        id: (map['id'] ?? '').toString(),
        name: map['class_name'] ?? map['name'] ?? 'No Name',
        schoolId: (map['school_id'] ?? map['schoolId'] ?? '').toString(),
        sectionId: (map['section_id'] ?? map['sectionId'] ?? '').toString(),
        formTeacherId: (map['form_teacher_id'] ?? map['teacher_id'] ?? map['formTeacherId'] ?? map['assignedTeacherId'])?.toString(),
        capacity: map['capacity'] == null ? null : int.tryParse(map['capacity'].toString()),
        isActive: parseBool(map['is_active'] ?? map['isActive']),
        studentIds: [],
        createdAt: parseDate(map['created_at'] ?? map['createdAt']),
        lastModified: parseDate(map['updated_at'] ?? map['lastModified']),
      );
    } catch (e) {
      debugPrint('Error parsing ClassModel: $e');
      return ClassModel(
        id: (map['id'] ?? 'error').toString(),
        name: 'Error',
        schoolId: '',
        sectionId: '',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
    }
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

  ClassModel copyWith({
    String? id,
    String? name,
    String? schoolId,
    String? sectionId,
    String? formTeacherId,
    int? capacity,
    bool? isActive,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      sectionId: sectionId ?? this.sectionId,
      formTeacherId: formTeacherId ?? this.formTeacherId,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
