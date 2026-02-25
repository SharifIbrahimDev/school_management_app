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
    return FeeModel(
      id: map['id'] ?? '',
      schoolId: map['schoolId'] ?? '',
      sectionId: map['sectionId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      termId: map['termId'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      feeType: map['feeType'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] ?? map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      status: FeeStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => FeeStatus.pending,
      ),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      lastModified: map['lastModified'] != null ? DateTime.parse(map['lastModified']) : DateTime.now(),
      description: map['description'],
      parentId: map['parentId'],
      feeScope: FeeScope.values.firstWhere(
            (e) => e.name == map['feeScope'],
        orElse: () => FeeScope.section,
      ),
      originScope: map['originScope'] != null
          ? FeeScope.values.firstWhere(
            (e) => e.name == map['originScope'],
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
