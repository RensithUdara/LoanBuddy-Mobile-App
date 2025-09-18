import 'package:intl/intl.dart';

class Payment {
  final int? id;
  final int loanId;
  final double paymentAmount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.loanId,
    required this.paymentAmount,
    required this.paymentDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_id': loanId,
      'payment_amount': paymentAmount,
      'payment_date': DateFormat('yyyy-MM-dd').format(paymentDate),
      'notes': notes,
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
    };
  }

  // Create object from database map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      loanId: map['loan_id'],
      paymentAmount: map['payment_amount'],
      paymentDate: DateFormat('yyyy-MM-dd').parse(map['payment_date']),
      notes: map['notes'],
      createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['created_at']),
    );
  }
}