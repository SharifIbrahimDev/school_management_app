class PaymentModel {
  final int id;
  final int studentId;
  final int feeId;
  final double amount;
  final String paymentMethod;
  final String reference;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;
  
  // Relations
  final String? studentName;
  final String? feeType;

  PaymentModel({
    required this.id,
    required this.studentId,
    required this.feeId,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    required this.status,
    this.paidAt,
    required this.createdAt,
    this.studentName,
    this.feeType,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'],
      studentId: map['student_id'],
      feeId: map['fee_id'],
      amount: double.parse(map['amount'].toString()),
      paymentMethod: map['payment_method'],
      reference: map['reference'],
      status: map['status'],
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      studentName: map['student']?['full_name'], // Adjust based on student model
      feeType: map['fee']?['type'], // Adjust based on fee model
    );
  }
}
