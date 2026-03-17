import '../../core/enums/fee_scope.dart';

class FeeModel {
  final String id;
  final String schoolId;
  final String sectionId;
  final String sessionId;
  final String termId;
  final String classId;
  final String studentId;
  final String feeType;
  final double amount;
  final double balance;
  final DateTime dueDate;
  final FeeStatus status;
  final DateTime createdAt;
  final DateTime lastModified;
  final String? description;
  final String? parentId;
  final FeeScope feeScope;
  final FeeScope? originScope;

  FeeModel({
    required this.id,
    required this.schoolId,
    required this.sectionId,
    required this.sessionId,
    required this.termId,
    required this.classId,
    required this.studentId,
    required this.feeType,
    required this.amount,
    this.balance = 0.0,
    required this.dueDate,
    this.status = FeeStatus.pending,
    required this.createdAt,
    required this.lastModified,
    this.description,
    this.parentId,
    required this.feeScope,
    this.originScope,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'sectionId': sectionId,
      'sessionId': sessionId,
      'termId': termId,
      'classId': classId,
      'studentId': studentId,
      'feeType': feeType,
      'amount': amount,
      'balance': balance,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'description': description,
      'parentId': parentId,
      'feeScope': feeScope.name,
      'originScope': originScope?.name,
    };
  }

  factory FeeModel.fromMap(Map<String, dynamic> map) {
    String toStringSafe(dynamic value) => value != null ? value.toString() : '';
    
    double toDoubleSafe(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return FeeModel(
      id: toStringSafe(map['id']),
      schoolId: toStringSafe(map['school_id'] ?? map['schoolId']),
      sectionId: toStringSafe(map['section_id'] ?? map['sectionId']),
      sessionId: toStringSafe(map['session_id'] ?? map['sessionId']),
      termId: toStringSafe(map['term_id'] ?? map['termId']),
      classId: toStringSafe(map['class_id'] ?? map['classId']),
      studentId: toStringSafe(map['student_id'] ?? map['studentId']),
      feeType: toStringSafe(map['fee_name'] ?? map['feeType']),
      amount: toDoubleSafe(map['amount']),
      balance: toDoubleSafe(map['balance'] ?? map['amount']),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : (map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now()),
      status: FeeStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => FeeStatus.pending,
      ),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()),
      lastModified: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : (map['lastModified'] != null ? DateTime.parse(map['lastModified']) : DateTime.now()),
      description: map['description'],
      parentId: toStringSafe(map['parent_id'] ?? map['parentId']),
      feeScope: FeeScope.values.firstWhere(
            (e) {
              final name = map['fee_scope'] ?? map['feeScope'] ?? '';
              return e.name == name || (e == FeeScope.classScope && name == 'class');
            },
        orElse: () => FeeScope.section,
      ),
      originScope: (map['origin_scope'] ?? map['originScope']) != null
          ? FeeScope.values.firstWhere(
            (e) {
              final name = map['origin_scope'] ?? map['originScope'] ?? '';
              return e.name == name || (e == FeeScope.classScope && name == 'class');
            },
        orElse: () => FeeScope.section,
      )
          : null,
    );
  }

  FeeModel copyWith({
    String? id,
    String? schoolId,
    String? sectionId,
    String? sessionId,
    String? termId,
    String? classId,
    String? studentId,
    String? feeType,
    double? amount,
    double? balance,
    DateTime? dueDate,
    FeeStatus? status,
    DateTime? createdAt,
    DateTime? lastModified,
    String? description,
    String? parentId,
    FeeScope? feeScope,
    FeeScope? originScope,
  }) {
    return FeeModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      sectionId: sectionId ?? this.sectionId,
      sessionId: sessionId ?? this.sessionId,
      termId: termId ?? this.termId,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      feeType: feeType ?? this.feeType,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      feeScope: feeScope ?? this.feeScope,
      originScope: originScope ?? this.originScope,
    );
  }

  bool get isFullyPaid => balance <= 0 || status == FeeStatus.paid;
  double get amountPaid => amount - balance;
  
  // Backward compatibility alias
  String get name => feeType;
}
