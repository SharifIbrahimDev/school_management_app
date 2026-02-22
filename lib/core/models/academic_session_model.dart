import 'package:flutter/foundation.dart';

class AcademicSessionModel {
  final String id;
  final String schoolId;
  final String sectionId;
  final String sessionName;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> termIds;
  final DateTime createdAt;
  final bool isActive;
  final DateTime lastModified;

  AcademicSessionModel({
    required this.id,
    required this.schoolId,
    required this.sectionId,
    required this.sessionName,
    required this.startDate,
    required this.endDate,
    this.termIds = const [],
    required this.createdAt,
    this.isActive = true,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'section_id': sectionId,
      'session_name': sessionName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': lastModified.toIso8601String(),
    };
  }

  factory AcademicSessionModel.fromMap(Map<String, dynamic> map) {
    try {
      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      return AcademicSessionModel(
        id: (map['id'] ?? '').toString(),
        schoolId: (map['school_id'] ?? map['schoolId'] ?? '').toString(),
        sectionId: (map['section_id'] ?? map['sectionId'] ?? '').toString(),
        sessionName: map['session_name'] ?? map['sessionName'] ?? 'Unnamed Session',
        startDate: parseDate(map['start_date'] ?? map['startDate']),
        endDate: parseDate(map['end_date'] ?? map['endDate']),
        termIds: [],
        createdAt: parseDate(map['created_at'] ?? map['createdAt']),
        lastModified: parseDate(map['updated_at'] ?? map['lastModified']),
        isActive: parseBool(map['is_active'] ?? map['isActive']),
      );
    } catch (e) {
      debugPrint('Error parsing AcademicSessionModel: $e');
      return AcademicSessionModel(
        id: (map['id'] ?? 'error').toString(),
        schoolId: '',
        sectionId: '',
        sessionName: 'Error',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
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

  AcademicSessionModel copyWith({
    String? id,
    String? schoolId,
    String? sectionId,
    String? sessionName,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? termIds,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastModified,
  }) {
    return AcademicSessionModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      sectionId: sectionId ?? this.sectionId,
      sessionName: sessionName ?? this.sessionName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      termIds: termIds ?? this.termIds,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
    );
  }
}
