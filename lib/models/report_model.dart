import 'package:intl/intl.dart';

import 'loan_model.dart';
import 'payment_model.dart';

/// Enum for different report types
enum ReportType {
  summary, // Overall summary of all loans
  detailed, // Detailed report with all loans and payments
  overdue, // Only overdue loans
  byBorrower, // Grouped by borrower name
  byDate, // Grouped by date ranges
  paymentFlow, // Cash flow of payments
}

/// Report filter for date range selection
class ReportDateFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool useCustomRange;
  final DateFilterType filterType;

  ReportDateFilter({
    this.startDate,
    this.endDate,
    this.useCustomRange = false,
    this.filterType = DateFilterType.all,
  });

  factory ReportDateFilter.all() => ReportDateFilter(
        filterType: DateFilterType.all,
      );

  factory ReportDateFilter.thisMonth() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    return ReportDateFilter(
      startDate: startDate,
      endDate: endDate,
      filterType: DateFilterType.thisMonth,
    );
  }

  factory ReportDateFilter.lastMonth() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, 1);
    final endDate = DateTime(now.year, now.month, 0);
    return ReportDateFilter(
      startDate: startDate,
      endDate: endDate,
      filterType: DateFilterType.lastMonth,
    );
  }

  factory ReportDateFilter.thisYear() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);
    final endDate = DateTime(now.year, 12, 31);
    return ReportDateFilter(
      startDate: startDate,
      endDate: endDate,
      filterType: DateFilterType.thisYear,
    );
  }

  factory ReportDateFilter.custom(DateTime start, DateTime end) {
    return ReportDateFilter(
      startDate: start,
      endDate: end,
      useCustomRange: true,
      filterType: DateFilterType.custom,
    );
  }

  String get displayName {
    switch (filterType) {
      case DateFilterType.all:
        return 'All Time';
      case DateFilterType.thisMonth:
        return 'This Month';
      case DateFilterType.lastMonth:
        return 'Last Month';
      case DateFilterType.thisYear:
        return 'This Year';
      case DateFilterType.custom:
        final formatter = DateFormat('MMM dd, yyyy');
        return '${formatter.format(startDate!)} - ${formatter.format(endDate!)}';
    }
  }
}

/// Date filter types for easier selection
enum DateFilterType {
  all,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

/// Main report class
class Report {
  final String title;
  final ReportType type;
  final DateTime generatedAt;
  final ReportDateFilter dateFilter;
  final List<ReportSection> sections;
  final ReportSummary summary;

  Report({
    required this.title,
    required this.type,
    required this.dateFilter,
    required this.sections,
    required this.summary,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// Get a formatted string of when the report was generated
  String get formattedGeneratedDate =>
      DateFormat('MMMM dd, yyyy - HH:mm').format(generatedAt);

  /// Map for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.name,
      'generatedAt': DateFormat('yyyy-MM-dd HH:mm:ss').format(generatedAt),
      'dateFilter': {
        'startDate': dateFilter.startDate != null
            ? DateFormat('yyyy-MM-dd').format(dateFilter.startDate!)
            : null,
        'endDate': dateFilter.endDate != null
            ? DateFormat('yyyy-MM-dd').format(dateFilter.endDate!)
            : null,
        'filterType': dateFilter.filterType.name,
      },
      'sections': sections.map((section) => section.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }
}

/// Report summary with key financial metrics
class ReportSummary {
  final double totalLoanAmount;
  final double totalPaidAmount;
  final double totalOutstandingAmount;
  final int totalLoans;
  final int activeLoans;
  final int completedLoans;
  final int overdueLoans;
  final double overdueAmount;

  ReportSummary({
    required this.totalLoanAmount,
    required this.totalPaidAmount,
    required this.totalOutstandingAmount,
    required this.totalLoans,
    required this.activeLoans,
    required this.completedLoans,
    required this.overdueLoans,
    required this.overdueAmount,
  });

  /// Percentage of total amount that has been paid
  double get paymentCompletionRate =>
      totalLoanAmount > 0 ? (totalPaidAmount / totalLoanAmount) * 100 : 0;

  /// Percentage of loans that are overdue
  double get overdueRate =>
      activeLoans > 0 ? (overdueLoans / activeLoans) * 100 : 0;

  /// Map for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalLoanAmount': totalLoanAmount,
      'totalPaidAmount': totalPaidAmount,
      'totalOutstandingAmount': totalOutstandingAmount,
      'totalLoans': totalLoans,
      'activeLoans': activeLoans,
      'completedLoans': completedLoans,
      'overdueLoans': overdueLoans,
      'overdueAmount': overdueAmount,
      'paymentCompletionRate': paymentCompletionRate,
      'overdueRate': overdueRate,
    };
  }
}

/// Report section for grouping related items
class ReportSection {
  final String title;
  final List<ReportItem> items;
  final Map<String, double> sectionTotals;

  ReportSection({
    required this.title,
    required this.items,
    Map<String, double>? sectionTotals,
  }) : sectionTotals = sectionTotals ?? {};

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'sectionTotals': sectionTotals,
    };
  }
}

/// Base class for report items
abstract class ReportItem {
  final String title;

  ReportItem({required this.title});

  Map<String, dynamic> toJson();
}

/// Loan item for report
class LoanReportItem extends ReportItem {
  final Loan loan;
  final List<Payment>? payments;

  LoanReportItem({
    required this.loan,
    this.payments,
  }) : super(title: loan.borrowerName);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'loan',
      'title': title,
      'loan': loan.toMap(),
      'payments': payments?.map((payment) => payment.toMap()).toList(),
    };
  }
}

/// Borrower summary item for report
class BorrowerReportItem extends ReportItem {
  final String borrowerName;
  final String? whatsappNumber;
  final int totalLoans;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final int activeLoans;
  final int completedLoans;
  final int overdueLoans;

  BorrowerReportItem({
    required this.borrowerName,
    this.whatsappNumber,
    required this.totalLoans,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.activeLoans,
    required this.completedLoans,
    required this.overdueLoans,
  }) : super(title: borrowerName);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'borrower',
      'title': title,
      'borrowerName': borrowerName,
      'whatsappNumber': whatsappNumber,
      'totalLoans': totalLoans,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'activeLoans': activeLoans,
      'completedLoans': completedLoans,
      'overdueLoans': overdueLoans,
    };
  }
}

/// Date group item for report (e.g., monthly summary)
class DateGroupReportItem extends ReportItem {
  final DateTime startDate;
  final DateTime endDate;
  final double totalLent;
  final double totalReceived;
  final int newLoans;
  final int completedLoans;

  DateGroupReportItem({
    required this.startDate,
    required this.endDate,
    required this.totalLent,
    required this.totalReceived,
    required this.newLoans,
    required this.completedLoans,
  }) : super(title: DateFormat('MMMM yyyy').format(startDate));

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'dateGroup',
      'title': title,
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
      'totalLent': totalLent,
      'totalReceived': totalReceived,
      'newLoans': newLoans,
      'completedLoans': completedLoans,
    };
  }
}
