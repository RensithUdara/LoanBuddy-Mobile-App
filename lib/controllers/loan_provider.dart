import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../services/database_helper.dart';

class LoanProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Loan> _loans = [];
  bool _isLoading = false;
  double _totalLoanAmount = 0;
  double _totalOutstandingAmount = 0;

  // Getters
  List<Loan> get loans => _loans;
  bool get isLoading => _isLoading;
  double get totalLoanAmount => _totalLoanAmount;
  double get totalOutstandingAmount => _totalOutstandingAmount;

  // Constructor
  LoanProvider() {
    loadLoans();
  }

  // Load all loans
  Future<void> loadLoans() async {
    _isLoading = true;
    notifyListeners();

    try {
      _loans = await _dbHelper.getLoans();
      await _loadTotalAmounts();
    } catch (e) {
      debugPrint('Error loading loans: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load active loans only
  Future<void> loadActiveLoans() async {
    _isLoading = true;
    notifyListeners();

    try {
      _loans = await _dbHelper.getLoans(status: LoanStatus.active.name);
      await _loadTotalAmounts();
    } catch (e) {
      debugPrint('Error loading active loans: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load completed loans only
  Future<void> loadCompletedLoans() async {
    _isLoading = true;
    notifyListeners();

    try {
      _loans = await _dbHelper.getLoans(status: LoanStatus.completed.name);
    } catch (e) {
      debugPrint('Error loading completed loans: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new loan
  Future<bool> addLoan(Loan loan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _dbHelper.insertLoan(loan);
      if (id > 0) {
        final newLoan = loan.copyWith(id: id);
        _loans.add(newLoan);
        await _loadTotalAmounts();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding loan: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Update an existing loan
  Future<bool> updateLoan(Loan loan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _dbHelper.updateLoan(loan);
      if (result > 0) {
        final index = _loans.indexWhere((l) => l.id == loan.id);
        if (index != -1) {
          _loans[index] = loan;
        }
        await _loadTotalAmounts();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating loan: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Delete a loan
  Future<bool> deleteLoan(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _dbHelper.deleteLoan(id);
      if (result > 0) {
        _loans.removeWhere((loan) => loan.id == id);
        await _loadTotalAmounts();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting loan: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Load total amounts
  Future<void> _loadTotalAmounts() async {
    try {
      _totalLoanAmount = await _dbHelper.getTotalLoanAmount();
      _totalOutstandingAmount = await _dbHelper.getTotalOutstandingAmount();
    } catch (e) {
      debugPrint('Error loading total amounts: $e');
    }
  }

  // Get a specific loan
  Future<Loan?> getLoan(int id) async {
    try {
      return await _dbHelper.getLoan(id);
    } catch (e) {
      debugPrint('Error getting loan: $e');
      return null;
    }
  }

  // Filter loans by name
  List<Loan> searchLoans(String query) {
    if (query.isEmpty) return _loans;
    return _loans.where((loan) => 
      loan.borrowerName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}