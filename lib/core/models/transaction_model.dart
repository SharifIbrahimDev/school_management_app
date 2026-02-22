import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum TransactionType { credit, debit }

enum PaymentType { cash, transfer, partial }

enum CreditCategory { schoolFees, registrationFees, books, otherIncome }

enum DebitCategory { salary, stationary, cleaning, maintenance, generalExpenses, utilities, rent, otherExpenses }

extension TransactionTypeExtension on TransactionType {
  String get displayName => this == TransactionType.credit ? 'Credit' : 'Debit';
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.cash:
        return 'Cash';
      case PaymentType.transfer:
        return 'Transfer';
      case PaymentType.partial:
        return 'Partial (Cash & Transfer)';
    }
  }
}

extension CreditCategoryExtension on CreditCategory {
  String get displayName => TransactionModel._formatCategoryName(toString().split('.').last);
}

extension DebitCategoryExtension on DebitCategory {
  String get displayName => TransactionModel._formatCategoryName(toString().split('.').last);
}

class TransactionModel {
  final String id;
  final double amount;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime transactionDate;
  final TransactionType transactionType;
  final PaymentType paymentType;
  final double? cashAmount;
  final double? transferAmount;
  final String category;
  final String schoolId;
  final String sectionId;
  final String classId;
  final String termId;
  final String? sessionId;
  final String? studentId;

  TransactionModel({
    required this.id,
    required this.amount,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.transactionDate,
    required this.transactionType,
    required this.paymentType,
    this.cashAmount,
    this.transferAmount,
    required this.category,
    required this.schoolId,
    required this.sectionId,
    required this.classId,
    required this.termId,
    this.sessionId,
    this.studentId,
  }) {
    if (id.isEmpty) throw ArgumentError('id cannot be empty');
    if (amount <= 0) throw ArgumentError('amount must be positive');
    if (paymentType == PaymentType.partial) {
      if (cashAmount == null || cashAmount! <= 0) throw ArgumentError('cashAmount must be positive for partial payment');
      if (transferAmount == null || transferAmount! <= 0) throw ArgumentError('transferAmount must be positive for partial payment');
      if ((cashAmount! + transferAmount!) != amount) throw ArgumentError('cashAmount + transferAmount must equal amount for partial payment');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description?.trim(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'transaction_date': transactionDate.toIso8601String(),
      'transaction_type': transactionType == TransactionType.credit ? 'income' : 'expense',
      'payment_method': _getBackendPaymentMethod(paymentType),
      'cash_amount': cashAmount,
      'transfer_amount': transferAmount,
      'category': category,
      'school_id': schoolId,
      'section_id': sectionId,
      'class_id': classId,
      'term_id': termId,
      'session_id': sessionId,
      'student_id': studentId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    try {
      final typeStr = map['transaction_type'] as String? ?? map['type'] as String? ?? 'income';
      final transactionType = typeStr == 'expense' ? TransactionType.debit : TransactionType.credit;
      
      final paymentTypeStr = map['payment_method'] as String? ?? 'cash';
      final paymentType = _getFrontendPaymentType(paymentTypeStr);

      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      return TransactionModel(
        id: (map['id'] ?? const Uuid().v4()).toString(),
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        description: map['description'] as String?,
        createdBy: (map['created_by'] ?? map['createdBy'] ?? '').toString(),
        createdAt: parseDate(map['created_at'] ?? map['createdAt']),
        transactionDate: parseDate(map['transaction_date'] ?? map['transactionDate']),
        transactionType: transactionType,
        paymentType: paymentType,
        cashAmount: (map['cash_amount'] ?? map['cashAmount'] as num?)?.toDouble(),
        transferAmount: (map['transfer_amount'] ?? map['transferAmount'] as num?)?.toDouble(),
        category: map['category'] as String? ?? (transactionType == TransactionType.credit ? CreditCategory.schoolFees.displayName : DebitCategory.generalExpenses.displayName),
        schoolId: (map['school_id'] ?? map['schoolId'] ?? '').toString(),
        sectionId: (map['section_id'] ?? map['sectionId'] ?? '').toString(),
        classId: (map['class_id'] ?? map['classId'] ?? '').toString(),
        termId: (map['term_id'] ?? map['termId'] ?? '').toString(),
        sessionId: (map['session_id'] ?? map['sessionId'])?.toString(),
        studentId: (map['student_id'] ?? map['studentId'])?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing TransactionModel: $e');
      return TransactionModel(
        id: 'error',
        amount: 0.1,
        createdBy: '',
        createdAt: DateTime.now(),
        transactionDate: DateTime.now(),
        transactionType: TransactionType.credit,
        paymentType: PaymentType.cash,
        category: 'Error',
        schoolId: '',
        sectionId: '',
        classId: '',
        termId: '',
      );
    }
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? transactionDate,
    TransactionType? transactionType,
    PaymentType? paymentType,
    double? cashAmount,
    double? transferAmount,
    String? category,
    String? schoolId,
    String? sectionId,
    String? classId,
    String? termId,
    String? sessionId,
    String? studentId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionType: transactionType ?? this.transactionType,
      paymentType: paymentType ?? this.paymentType,
      cashAmount: cashAmount ?? this.cashAmount,
      transferAmount: transferAmount ?? this.transferAmount,
      category: category ?? this.category,
      schoolId: schoolId ?? this.schoolId,
      sectionId: sectionId ?? this.sectionId,
      classId: classId ?? this.classId,
      termId: termId ?? this.termId,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
    );
  }

  String get transactionTypeDisplayName => transactionType.displayName;

  String get type => transactionType == TransactionType.credit ? 'income' : 'expense';

  String get paymentTypeDisplayName => paymentType.displayName;
  
  // Backward compatibility alias
  String get paymentMethod => paymentType.displayName;

  static List<String> getCreditCategories() => CreditCategory.values.map((e) => e.displayName).toList();

  static List<String> getDebitCategories() => DebitCategory.values.map((e) => e.displayName).toList();

  static String _getBackendPaymentMethod(PaymentType type) {
    switch (type) {
      case PaymentType.cash: return 'cash';
      case PaymentType.transfer: return 'bank_transfer';
      case PaymentType.partial: return 'bank_transfer'; // Default to bank_transfer for partial for now or handle appropriately
    }
  }

  static PaymentType _getFrontendPaymentType(String method) {
    switch (method) {
      case 'cash': return PaymentType.cash;
      case 'bank_transfer': return PaymentType.transfer;
      case 'cheque': return PaymentType.transfer;
      case 'mobile_money': return PaymentType.transfer;
      default: return PaymentType.cash;
    }
  }

  static String _formatCategoryName(String category) {
    return category
        .replaceAllMapped(RegExp(r'([A-Z])'), (Match m) => ' ${m.group(0)!}')
        .trim()
        .replaceAllMapped(RegExp(r'^[a-z]'), (Match m) => m.group(0)!.toUpperCase())
        .replaceAll('Fees', 'Fees')
        .replaceAll('Expenses', 'Expenses');
  }
}
