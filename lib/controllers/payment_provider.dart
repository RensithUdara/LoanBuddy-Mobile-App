import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/database_helper.dart';
import 'loan_provider.dart';

class PaymentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LoanProvider _loanProvider;
  List<Payment> _payments = [];
  bool _isLoading = false;
  int? _currentLoanId;

  // Getters
  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  int? get currentLoanId => _currentLoanId;

  // Constructor
  PaymentProvider(this._loanProvider);

  // Load payments for a loan
  Future<void> loadPaymentsForLoan(int loanId) async {
    _isLoading = true;
    _currentLoanId = loanId;
    notifyListeners();

    try {
      _payments = await _dbHelper.getPaymentsForLoan(loanId);
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new payment
  Future<bool> addPayment(Payment payment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _dbHelper.insertPayment(payment);
      if (id > 0) {
        // Add the payment to our local list
        final newPayment = Payment(
          id: id,
          loanId: payment.loanId,
          paymentAmount: payment.paymentAmount,
          paymentDate: payment.paymentDate,
          notes: payment.notes,
        );
        _payments.insert(0, newPayment);
        
        // Refresh the loan to update its paid amount
        final loan = await _loanProvider.getLoan(payment.loanId);
        if (loan != null) {
          // Update the loan in the loan provider
          await _loanProvider.loadLoans();
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding payment: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Delete a payment
  Future<bool> deletePayment(int paymentId, int loanId, double amount) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _dbHelper.deletePayment(paymentId, loanId, amount);
      if (result > 0) {
        _payments.removeWhere((payment) => payment.id == paymentId);
        
        // Refresh the loan to update its paid amount
        await _loanProvider.loadLoans();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting payment: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Clear current payments
  void clearPayments() {
    _payments = [];
    _currentLoanId = null;
    notifyListeners();
  }
}