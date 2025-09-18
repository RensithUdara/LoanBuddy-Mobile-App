import 'package:intl/intl.dart';

enum LoanStatus {
  active,
  completed,
}

class Loan {
  final int? id;
  final String borrowerName;
  final String whatsappNumber;
  final double loanAmount;
  double paidAmount;
  final DateTime loanDate;
  final DateTime dueDate;
  LoanStatus status;
  final DateTime createdAt;
  DateTime updatedAt;

  Loan({
    this.id,
    required this.borrowerName,
    required this.whatsappNumber,
    required this.loanAmount,
    this.paidAmount = 0.0,
    required this.loanDate,
    required this.dueDate,
    this.status = LoanStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Get remaining amount
  double get remainingAmount => loanAmount - paidAmount;

  // Check if loan is overdue
  bool get isOverdue =>
      status == LoanStatus.active && dueDate.isBefore(DateTime.now());

  // Add a payment to the loan
  void addPayment(double amount) {
    paidAmount += amount;
    updatedAt = DateTime.now();

    // If fully paid, mark as completed
    if (paidAmount >= loanAmount) {
      status = LoanStatus.completed;
    }
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrower_name': borrowerName,
      'whatsapp_number': whatsappNumber,
      'loan_amount': loanAmount,
      'paid_amount': paidAmount,
      'loan_date': DateFormat('yyyy-MM-dd').format(loanDate),
      'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
      'status': status.name,
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
      'updated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(updatedAt),
    };
  }

  // Create object from database map
  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'],
      borrowerName: map['borrower_name'],
      whatsappNumber: map['whatsapp_number'],
      loanAmount: map['loan_amount'],
      paidAmount: map['paid_amount'],
      loanDate: DateFormat('yyyy-MM-dd').parse(map['loan_date']),
      dueDate: DateFormat('yyyy-MM-dd').parse(map['due_date']),
      status: map['status'] == LoanStatus.completed.name
          ? LoanStatus.completed
          : LoanStatus.active,
      createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['created_at']),
      updatedAt: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['updated_at']),
    );
  }

  // Create a copy of the loan with updated fields
  Loan copyWith({
    int? id,
    String? borrowerName,
    String? whatsappNumber,
    double? loanAmount,
    double? paidAmount,
    DateTime? loanDate,
    DateTime? dueDate,
    LoanStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      borrowerName: borrowerName ?? this.borrowerName,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      loanAmount: loanAmount ?? this.loanAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
