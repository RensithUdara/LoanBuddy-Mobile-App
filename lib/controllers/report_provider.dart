import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/report_generation_service.dart';
import '../services/database_helper.dart';

/// Provider to manage report state and communicate with the report service
class ReportProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReportGenerationService _reportService = ReportGenerationService();
  
  Report? _currentReport;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  Report? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasReport => _currentReport != null;
  
  // Generate a new report
  Future<bool> generateReport({
    required ReportType type,
    required ReportDateFilter dateFilter,
    String? borrowerFilter,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentReport = await _reportService.generateReport(
        type: type,
        dateFilter: dateFilter,
        borrowerFilter: borrowerFilter,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to generate report: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Clear the current report
  void clearReport() {
    _currentReport = null;
    _error = null;
    notifyListeners();
  }
  
  // Get a list of all borrowers for filtering reports
  Future<List<String>> getAllBorrowers() async {
    try {
      final loans = await _dbHelper.getLoans();
      final borrowerNames = loans.map((loan) => loan.borrowerName).toSet().toList();
      borrowerNames.sort();
      return borrowerNames;
    } catch (e) {
      _error = 'Failed to get borrower list: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }
  
  // Get the count of overdue loans - useful for dashboard indicators
  Future<int> getOverdueLoansCount() async {
    try {
      final loans = await _dbHelper.getLoans(status: 'active');
      return loans.where((loan) => loan.isOverdue).length;
    } catch (e) {
      return 0;
    }
  }
  
  // Get the total overdue amount - useful for dashboard indicators
  Future<double> getOverdueAmount() async {
    try {
      final loans = await _dbHelper.getLoans(status: 'active');
      final overdueLoans = loans.where((loan) => loan.isOverdue);
      return overdueLoans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);
    } catch (e) {
      return 0.0;
    }
  }
}