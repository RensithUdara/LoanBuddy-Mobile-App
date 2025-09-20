import 'package:intl/intl.dart';

import '../models/loan_model.dart';
import '../models/payment_model.dart';
import '../models/report_model.dart';
import '../services/database_helper.dart';

/// Service class responsible for generating various report types
class ReportGenerationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Generate a report based on the selected type and filters
  Future<Report> generateReport({
    required ReportType type,
    required ReportDateFilter dateFilter,
    String? borrowerFilter,
  }) async {
    switch (type) {
      case ReportType.summary:
        return await _generateSummaryReport(dateFilter);
      case ReportType.detailed:
        return await _generateDetailedReport(dateFilter, borrowerFilter);
      case ReportType.overdue:
        return await _generateOverdueReport(dateFilter);
      case ReportType.byBorrower:
        return await _generateBorrowerReport(dateFilter);
      case ReportType.byDate:
        return await _generateDateReport(dateFilter);
      case ReportType.paymentFlow:
        return await _generatePaymentFlowReport(dateFilter);
    }
  }

  /// Generate an overall summary report
  Future<Report> _generateSummaryReport(ReportDateFilter filter) async {
    // Load all loans within the date filter
    List<Loan> loans = await _getFilteredLoans(filter);

    // Calculate summary metrics
    final summary = await _calculateReportSummary(loans, filter);

    // Create sections for the report
    List<ReportSection> sections = [];

    // Add active loans section if there are any
    final activeLoans =
        loans.where((loan) => loan.status == LoanStatus.active).toList();
    if (activeLoans.isNotEmpty) {
      sections.add(ReportSection(
        title: 'Active Loans',
        items: activeLoans.map((loan) => LoanReportItem(loan: loan)).toList(),
        sectionTotals: {
          'total': activeLoans.fold(0, (sum, loan) => sum + loan.loanAmount),
          'paid': activeLoans.fold(0, (sum, loan) => sum + loan.paidAmount),
          'outstanding':
              activeLoans.fold(0, (sum, loan) => sum + loan.remainingAmount),
        },
      ));
    }

    // Add completed loans section if there are any
    final completedLoans =
        loans.where((loan) => loan.status == LoanStatus.completed).toList();
    if (completedLoans.isNotEmpty) {
      sections.add(ReportSection(
        title: 'Completed Loans',
        items:
            completedLoans.map((loan) => LoanReportItem(loan: loan)).toList(),
        sectionTotals: {
          'total': completedLoans.fold(0, (sum, loan) => sum + loan.loanAmount),
          'paid': completedLoans.fold(0, (sum, loan) => sum + loan.paidAmount),
          'outstanding':
              completedLoans.fold(0, (sum, loan) => sum + loan.remainingAmount),
        },
      ));
    }

    // Add overdue loans section if there are any
    final overdueLoans = activeLoans.where((loan) => loan.isOverdue).toList();
    if (overdueLoans.isNotEmpty) {
      sections.add(ReportSection(
        title: 'Overdue Loans',
        items: overdueLoans.map((loan) => LoanReportItem(loan: loan)).toList(),
        sectionTotals: {
          'total': overdueLoans.fold(0, (sum, loan) => sum + loan.loanAmount),
          'paid': overdueLoans.fold(0, (sum, loan) => sum + loan.paidAmount),
          'outstanding':
              overdueLoans.fold(0, (sum, loan) => sum + loan.remainingAmount),
        },
      ));
    }

    // Create the final report
    return Report(
      title: 'Loan Summary Report',
      type: ReportType.summary,
      dateFilter: filter,
      sections: sections,
      summary: summary,
    );
  }

  /// Generate a detailed report with all loans and their payments
  Future<Report> _generateDetailedReport(
      ReportDateFilter filter, String? borrowerFilter) async {
    // Load all loans within the date filter
    List<Loan> loans =
        await _getFilteredLoans(filter, borrowerName: borrowerFilter);

    // Calculate summary metrics
    final summary = await _calculateReportSummary(loans, filter);

    // Create sections for the report - one section per loan
    List<ReportSection> sections = [];

    // Process each loan
    for (var loan in loans) {
      // Get all payments for this loan
      final payments = await _dbHelper.getPaymentsForLoan(loan.id!);

      // Filter payments by date if needed
      final filteredPayments = filter.useCustomRange
          ? payments.where((payment) {
              return (payment.paymentDate.isAfter(filter.startDate!) ||
                      payment.paymentDate
                          .isAtSameMomentAs(filter.startDate!)) &&
                  (payment.paymentDate.isBefore(filter.endDate!) ||
                      payment.paymentDate.isAtSameMomentAs(filter.endDate!));
            }).toList()
          : payments;

      // Create a section for this loan
      sections.add(ReportSection(
        title:
            '${loan.borrowerName} (${loan.status == LoanStatus.active ? "Active" : "Completed"})',
        items: [LoanReportItem(loan: loan, payments: filteredPayments)],
        sectionTotals: {
          'loanAmount': loan.loanAmount,
          'paidAmount': loan.paidAmount,
          'remainingAmount': loan.remainingAmount,
          'paymentCount': filteredPayments.length.toDouble(),
        },
      ));
    }

    // Create the final report
    return Report(
      title: borrowerFilter != null
          ? 'Detailed Loan Report for $borrowerFilter'
          : 'Detailed Loan Report',
      type: ReportType.detailed,
      dateFilter: filter,
      sections: sections,
      summary: summary,
    );
  }

  /// Generate a report focusing on overdue loans
  Future<Report> _generateOverdueReport(ReportDateFilter filter) async {
    // Load all loans within the date filter
    List<Loan> loans = await _getFilteredLoans(filter);

    // Keep only overdue loans
    loans = loans
        .where((loan) => loan.status == LoanStatus.active && loan.isOverdue)
        .toList();

    // Sort by due date (oldest first)
    loans.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Calculate summary metrics
    final summary = await _calculateReportSummary(loans, filter);

    // Group by overdue period
    final Map<String, List<Loan>> groupedLoans = {
      'Under 30 Days': <Loan>[],
      '30-60 Days': <Loan>[],
      '60-90 Days': <Loan>[],
      'Over 90 Days': <Loan>[],
    };

    final now = DateTime.now();
    for (var loan in loans) {
      final difference = now.difference(loan.dueDate).inDays;

      if (difference < 30) {
        groupedLoans['Under 30 Days']!.add(loan);
      } else if (difference < 60) {
        groupedLoans['30-60 Days']!.add(loan);
      } else if (difference < 90) {
        groupedLoans['60-90 Days']!.add(loan);
      } else {
        groupedLoans['Over 90 Days']!.add(loan);
      }
    }

    // Create sections for the report based on overdue periods
    List<ReportSection> sections = [];

    groupedLoans.forEach((key, loanList) {
      if (loanList.isNotEmpty) {
        sections.add(ReportSection(
          title: key,
          items: loanList.map((loan) => LoanReportItem(loan: loan)).toList(),
          sectionTotals: {
            'count': loanList.length.toDouble(),
            'totalAmount':
                loanList.fold(0, (sum, loan) => sum + loan.loanAmount),
            'outstandingAmount':
                loanList.fold(0, (sum, loan) => sum + loan.remainingAmount),
          },
        ));
      }
    });

    // Create the final report
    return Report(
      title: 'Overdue Loans Report',
      type: ReportType.overdue,
      dateFilter: filter,
      sections: sections,
      summary: summary,
    );
  }

  /// Generate a report grouped by borrowers
  Future<Report> _generateBorrowerReport(ReportDateFilter filter) async {
    // Load all loans within the date filter
    List<Loan> loans = await _getFilteredLoans(filter);

    // Calculate summary metrics
    final summary = await _calculateReportSummary(loans, filter);

    // Group loans by borrower name
    Map<String, List<Loan>> borrowerLoans = {};

    for (var loan in loans) {
      if (!borrowerLoans.containsKey(loan.borrowerName)) {
        borrowerLoans[loan.borrowerName] = [];
      }
      borrowerLoans[loan.borrowerName]!.add(loan);
    }

    // Create sections for each borrower
    List<ReportSection> sections = [];

    // Sort borrowers by name
    final sortedBorrowers = borrowerLoans.keys.toList()..sort();

    for (var borrower in sortedBorrowers) {
      final borrowerLoanList = borrowerLoans[borrower]!;

      // Calculate borrower metrics
      final totalAmount =
          borrowerLoanList.fold(0.0, (sum, loan) => sum + loan.loanAmount);
      final paidAmount =
          borrowerLoanList.fold(0.0, (sum, loan) => sum + loan.paidAmount);
      final outstandingAmount = totalAmount - paidAmount;
      final activeLoans = borrowerLoanList
          .where((loan) => loan.status == LoanStatus.active)
          .length;
      final completedLoans = borrowerLoanList
          .where((loan) => loan.status == LoanStatus.completed)
          .length;
      final overdueLoans =
          borrowerLoanList.where((loan) => loan.isOverdue).length;

      // Create a BorrowerReportItem
      final borrowerItem = BorrowerReportItem(
        borrowerName: borrower,
        whatsappNumber: borrowerLoanList
            .first.whatsappNumber, // Assuming same number for all loans
        totalLoans: borrowerLoanList.length,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        outstandingAmount: outstandingAmount,
        activeLoans: activeLoans,
        completedLoans: completedLoans,
        overdueLoans: overdueLoans,
      );

      // Create a list of ReportItem (mixing BorrowerReportItem and LoanReportItem)
      final List<ReportItem> sectionItems = <ReportItem>[borrowerItem];
      sectionItems
          .addAll(borrowerLoanList.map((loan) => LoanReportItem(loan: loan)));

      sections.add(ReportSection(
        title: borrower,
        items: sectionItems,
        sectionTotals: {
          'totalAmount': totalAmount,
          'paidAmount': paidAmount,
          'outstandingAmount': outstandingAmount,
          'loanCount': borrowerLoanList.length.toDouble(),
        },
      ));
    }

    // Sort sections by outstanding amount (highest first)
    sections.sort((a, b) => (b.sectionTotals['outstandingAmount'] ?? 0)
        .compareTo(a.sectionTotals['outstandingAmount'] ?? 0));

    // Create the final report
    return Report(
      title: 'Borrower Analysis Report',
      type: ReportType.byBorrower,
      dateFilter: filter,
      sections: sections,
      summary: summary,
    );
  }

  /// Generate a report grouped by date periods (months/quarters)
  Future<Report> _generateDateReport(ReportDateFilter filter) async {
    // Load all loans and payments within the date filter
    final loans = await _getFilteredLoans(filter);

    // Calculate summary metrics
    final summary = await _calculateReportSummary(loans, filter);

    // Define date range
    DateTime startDate = filter.startDate ??
        DateTime(2000); // Default to past date if not specified
    DateTime endDate =
        filter.endDate ?? DateTime.now(); // Default to today if not specified

    // Group by month
    Map<String, DateGroupData> monthlyData = {};

    // Process loans
    for (var loan in loans) {
      final month = DateTime(loan.loanDate.year, loan.loanDate.month, 1);
      final monthKey = DateFormat('yyyy-MM').format(month);

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = DateGroupData(
          startDate: month,
          endDate:
              DateTime(month.year, month.month + 1, 0), // Last day of month
        );
      }

      // Add loan to month's data
      monthlyData[monthKey]!.newLoans++;
      monthlyData[monthKey]!.totalLent += loan.loanAmount;

      // Check if loan was completed in this period
      if (loan.status == LoanStatus.completed &&
          loan.updatedAt.year == month.year &&
          loan.updatedAt.month == month.month) {
        monthlyData[monthKey]!.completedLoans++;
      }
    }

    // Process payments
    for (var loan in loans) {
      final payments = await _dbHelper.getPaymentsForLoan(loan.id!);

      for (var payment in payments) {
        final month =
            DateTime(payment.paymentDate.year, payment.paymentDate.month, 1);
        final monthKey = DateFormat('yyyy-MM').format(month);

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = DateGroupData(
            startDate: month,
            endDate:
                DateTime(month.year, month.month + 1, 0), // Last day of month
          );
        }

        // Add payment to month's data
        monthlyData[monthKey]!.totalReceived += payment.paymentAmount;
      }
    }

    // Create sections for the report - one per quarter
    Map<String, List<DateGroupReportItem>> quarterlyGroups = {};
    List<ReportSection> sections = [];

    // Convert monthly data to report items and group by quarter
    monthlyData.forEach((key, data) {
      final quarterKey =
          '${data.startDate.year} Q${(data.startDate.month - 1) ~/ 3 + 1}';

      if (!quarterlyGroups.containsKey(quarterKey)) {
        quarterlyGroups[quarterKey] = [];
      }

      quarterlyGroups[quarterKey]!.add(DateGroupReportItem(
        startDate: data.startDate,
        endDate: data.endDate,
        totalLent: data.totalLent,
        totalReceived: data.totalReceived,
        newLoans: data.newLoans,
        completedLoans: data.completedLoans,
      ));
    });

    // Create sections for each quarter
    final sortedQuarters = quarterlyGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    for (var quarter in sortedQuarters) {
      final quarterItems = quarterlyGroups[quarter]!;
      quarterItems.sort((a, b) =>
          b.startDate.compareTo(a.startDate)); // Sort by most recent month

      sections.add(ReportSection(
        title: quarter,
        items: quarterItems,
        sectionTotals: {
          'totalLent':
              quarterItems.fold(0.0, (sum, item) => sum + item.totalLent),
          'totalReceived':
              quarterItems.fold(0.0, (sum, item) => sum + item.totalReceived),
          'newLoans':
              quarterItems.fold(0.0, (sum, item) => sum + item.newLoans),
          'completedLoans':
              quarterItems.fold(0.0, (sum, item) => sum + item.completedLoans),
        },
      ));
    }

    // Create the final report
    return Report(
      title: 'Loan Activity by Date',
      type: ReportType.byDate,
      dateFilter: filter,
      sections: sections,
      summary: summary,
    );
  }

  /// Generate a cash flow report of payments
  Future<Report> _generatePaymentFlowReport(ReportDateFilter filter) async {
    // Load all loans within the date filter
    List<Loan> loans = await _getFilteredLoans(filter);

    // Calculate summary metrics
    final summary = await _calculateReportSummary(loans, filter);

    // Get all payments within the date range
    List<Payment> allPayments = [];
    for (var loan in loans) {
      final payments = await _dbHelper.getPaymentsForLoan(loan.id!);

      // Filter payments by date range if needed
      if (filter.useCustomRange) {
        allPayments.addAll(payments.where((payment) {
          return (payment.paymentDate.isAfter(filter.startDate!) ||
                  payment.paymentDate.isAtSameMomentAs(filter.startDate!)) &&
              (payment.paymentDate.isBefore(filter.endDate!) ||
                  payment.paymentDate.isAtSameMomentAs(filter.endDate!));
        }));
      } else {
        allPayments.addAll(payments);
      }
    }

    // Group payments by month
    Map<String, List<Payment>> paymentsByMonth = {};

    for (var payment in allPayments) {
      final monthKey = DateFormat('yyyy-MM').format(payment.paymentDate);

      if (!paymentsByMonth.containsKey(monthKey)) {
        paymentsByMonth[monthKey] = [];
      }

      paymentsByMonth[monthKey]!.add(payment);
    }

    // Create a payment flow section
    List<ReportSection> sections = [];

    // Sort months chronologically
    final sortedMonths = paymentsByMonth.keys.toList()..sort();

    for (var month in sortedMonths) {
      final monthlyPayments = paymentsByMonth[month]!;
      final date = DateFormat('yyyy-MM').parse(month);

      // Create a monthly report item
      final monthlyItem = DateGroupReportItem(
        startDate: DateTime(date.year, date.month, 1),
        endDate: DateTime(date.year, date.month + 1, 0), // Last day of month
        totalLent: 0, // Will calculate new loans later
        totalReceived: monthlyPayments.fold(
            0.0, (sum, payment) => sum + payment.paymentAmount),
        newLoans: 0, // Will calculate later
        completedLoans: 0, // Will calculate later
      );

      // Calculate loans issued in this month
      final loansThisMonth = loans
          .where((loan) =>
              loan.loanDate.year == date.year &&
              loan.loanDate.month == date.month)
          .toList();

      // Calculate completed loans in this month
      final completedThisMonth = loans
          .where((loan) =>
              loan.status == LoanStatus.completed &&
              loan.updatedAt.year == date.year &&
              loan.updatedAt.month == date.month)
          .toList();

      // Update the monthly item with loan data
      final updatedMonthlyItem = DateGroupReportItem(
        startDate: monthlyItem.startDate,
        endDate: monthlyItem.endDate,
        totalLent:
            loansThisMonth.fold(0.0, (sum, loan) => sum + loan.loanAmount),
        totalReceived: monthlyItem.totalReceived,
        newLoans: loansThisMonth.length,
        completedLoans: completedThisMonth.length,
      );

      sections.add(ReportSection(
        title: DateFormat('MMMM yyyy').format(date),
        items: [updatedMonthlyItem],
        sectionTotals: {
          'inflow': updatedMonthlyItem.totalReceived,
          'outflow': updatedMonthlyItem.totalLent,
          'netFlow':
              updatedMonthlyItem.totalReceived - updatedMonthlyItem.totalLent,
          'paymentCount': monthlyPayments.length.toDouble(),
        },
      ));
    }

    // Create the final report
    return Report(
      title: 'Payment Flow Report',
      type: ReportType.paymentFlow,
      dateFilter: filter,
      sections: sections,
      summary: summary,
    );
  }

  /// Helper method to get loans filtered by date range and other criteria
  Future<List<Loan>> _getFilteredLoans(
    ReportDateFilter filter, {
    String? borrowerName,
    String? status,
  }) async {
    // Get all loans first (or with status filter if provided)
    List<Loan> loans = await _dbHelper.getLoans(status: status);

    // Filter by borrower name if provided
    if (borrowerName != null && borrowerName.isNotEmpty) {
      loans = loans
          .where((loan) => loan.borrowerName
              .toLowerCase()
              .contains(borrowerName.toLowerCase()))
          .toList();
    }

    // Apply date filter if using custom range
    if (filter.useCustomRange &&
        filter.startDate != null &&
        filter.endDate != null) {
      loans = loans.where((loan) {
        // Filter by loan date or due date depending on what makes more sense for the report
        final dateToCheck = loan.loanDate;
        return (dateToCheck.isAfter(filter.startDate!) ||
                dateToCheck.isAtSameMomentAs(filter.startDate!)) &&
            (dateToCheck.isBefore(filter.endDate!) ||
                dateToCheck.isAtSameMomentAs(filter.endDate!));
      }).toList();
    }

    return loans;
  }

  /// Calculate summary metrics for the report
  Future<ReportSummary> _calculateReportSummary(
      List<Loan> loans, ReportDateFilter filter) async {
    final totalLoanAmount =
        loans.fold(0.0, (sum, loan) => sum + loan.loanAmount);
    final totalPaidAmount =
        loans.fold(0.0, (sum, loan) => sum + loan.paidAmount);
    final totalOutstandingAmount = totalLoanAmount - totalPaidAmount;

    final totalLoans = loans.length;
    final activeLoans =
        loans.where((loan) => loan.status == LoanStatus.active).length;
    final completedLoans =
        loans.where((loan) => loan.status == LoanStatus.completed).length;

    final overdueLoans = loans
        .where((loan) => loan.status == LoanStatus.active && loan.isOverdue)
        .length;

    final overdueAmount = loans
        .where((loan) => loan.status == LoanStatus.active && loan.isOverdue)
        .fold(0.0, (sum, loan) => sum + loan.remainingAmount);

    return ReportSummary(
      totalLoanAmount: totalLoanAmount,
      totalPaidAmount: totalPaidAmount,
      totalOutstandingAmount: totalOutstandingAmount,
      totalLoans: totalLoans,
      activeLoans: activeLoans,
      completedLoans: completedLoans,
      overdueLoans: overdueLoans,
      overdueAmount: overdueAmount,
    );
  }
}

/// Helper class for date grouping
class DateGroupData {
  final DateTime startDate;
  final DateTime endDate;
  double totalLent = 0;
  double totalReceived = 0;
  int newLoans = 0;
  int completedLoans = 0;

  DateGroupData({
    required this.startDate,
    required this.endDate,
  });
}
