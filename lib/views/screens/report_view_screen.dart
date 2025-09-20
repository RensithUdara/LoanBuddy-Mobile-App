import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/report_provider.dart';
import '../../controllers/settings_provider.dart';
import '../../models/loan_model.dart';
import '../../models/report_model.dart';
import 'report_chart_view.dart';

class ReportViewScreen extends StatefulWidget {
  const ReportViewScreen({super.key});

  @override
  State<ReportViewScreen> createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends State<ReportViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // Format currency values
  String formatCurrency(double value) {
    final currencySymbol =
        Provider.of<SettingsProvider>(context, listen: false).currency;
    return '$currencySymbol ${NumberFormat('#,##0.00').format(value)}';
  }

  // Export report as PDF
  Future<void> exportAsPdf(Report report) async {
    setState(() {
      isExporting = true;
    });

    try {
      final pdf = pw.Document();
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final currencySymbol = settingsProvider.currency;

      // Add title page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    report.title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Date Range: ${report.dateFilter.displayName}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated on ${report.formattedGeneratedDate}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 32),
                  pw.Text(
                    'LoanBuddy',
                    style: const pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Add summary page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pdfTableCell('Metric', isHeader: true),
                        pdfTableCell('Value', isHeader: true),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Total Loans'),
                        pdfTableCell('${report.summary.totalLoans}'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Active Loans'),
                        pdfTableCell('${report.summary.activeLoans}'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Completed Loans'),
                        pdfTableCell('${report.summary.completedLoans}'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Overdue Loans'),
                        pdfTableCell('${report.summary.overdueLoans}'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Total Loan Amount'),
                        pdfTableCell(
                            '$currencySymbol ${NumberFormat('#,##0.00').format(report.summary.totalLoanAmount)}'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Total Paid Amount'),
                        pdfTableCell(
                            '$currencySymbol ${NumberFormat('#,##0.00').format(report.summary.totalPaidAmount)}'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Total Outstanding'),
                        pdfTableCell(
                            '$currencySymbol ${NumberFormat('#,##0.00').format(report.summary.totalOutstandingAmount)}'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Overdue Amount'),
                        pdfTableCell(
                            '$currencySymbol ${NumberFormat('#,##0.00').format(report.summary.overdueAmount)}',
                            color: report.summary.overdueAmount > 0
                                ? PdfColors.red
                                : null),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pdfTableCell('Payment Completion Rate'),
                        pdfTableCell(
                            '${report.summary.paymentCompletionRate.toStringAsFixed(2)}%'),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Add section pages
      for (var section in report.sections) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    section.title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  buildPdfSectionContent(section, currencySymbol),
                ],
              );
            },
          ),
        );
      }

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/LoanBuddy_${report.type.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'LoanBuddy ${report.title}',
          subject: report.title,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isExporting = false;
      });
    }
  }

  // Helper method to build PDF table cells
  pw.Widget pdfTableCell(String text,
      {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8.0),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: color,
        ),
      ),
    );
  }

  // Helper method to build the content for a PDF section
  pw.Widget buildPdfSectionContent(
      ReportSection section, String currencySymbol) {
    // For different report types, customize the section content
    if (section.items.isEmpty) {
      return pw.Text('No data available for this section');
    }

    // If first item is DateGroupReportItem, show date group table
    if (section.items.first is DateGroupReportItem) {
      final columns = [
        'Period',
        'New Loans',
        'Total Lent',
        'Total Received',
        'Completed'
      ];

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: columns
                .map((col) => pdfTableCell(col, isHeader: true))
                .toList(),
          ),
          // Data rows
          ...section.items.map((item) {
            final dateItem = item as DateGroupReportItem;
            return pw.TableRow(
              children: [
                pdfTableCell(DateFormat('MMM yyyy').format(dateItem.startDate)),
                pdfTableCell(dateItem.newLoans.toString()),
                pdfTableCell(
                    '$currencySymbol ${NumberFormat('#,##0.00').format(dateItem.totalLent)}'),
                pdfTableCell(
                    '$currencySymbol ${NumberFormat('#,##0.00').format(dateItem.totalReceived)}'),
                pdfTableCell(dateItem.completedLoans.toString()),
              ],
            );
          }),
          // Totals row if available
          if (section.sectionTotals.isNotEmpty)
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pdfTableCell('Total', isHeader: true),
                pdfTableCell(
                    section.sectionTotals['newLoans']?.toInt().toString() ??
                        ''),
                pdfTableCell(
                    '$currencySymbol ${NumberFormat('#,##0.00').format(section.sectionTotals['totalLent'] ?? 0)}'),
                pdfTableCell(
                    '$currencySymbol ${NumberFormat('#,##0.00').format(section.sectionTotals['totalReceived'] ?? 0)}'),
                pdfTableCell(section.sectionTotals['completedLoans']
                        ?.toInt()
                        .toString() ??
                    ''),
              ],
            ),
        ],
      );
    }

    // If first item is BorrowerReportItem, show borrower summary
    if (section.items.first is BorrowerReportItem) {
      final borrower = section.items.first as BorrowerReportItem;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Borrower: ${borrower.borrowerName}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (borrower.whatsappNumber != null &&
              borrower.whatsappNumber!.isNotEmpty)
            pw.Text('WhatsApp: ${borrower.whatsappNumber}'),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pdfInfoBox('Total Loans', borrower.totalLoans.toString()),
              pdfInfoBox('Active', borrower.activeLoans.toString()),
              pdfInfoBox('Completed', borrower.completedLoans.toString()),
              pdfInfoBox('Overdue', borrower.overdueLoans.toString(),
                  color: borrower.overdueLoans > 0 ? PdfColors.red : null),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pdfInfoBox('Total Amount',
                  '$currencySymbol ${NumberFormat('#,##0.00').format(borrower.totalAmount)}'),
              pdfInfoBox('Paid Amount',
                  '$currencySymbol ${NumberFormat('#,##0.00').format(borrower.paidAmount)}'),
              pdfInfoBox('Outstanding',
                  '$currencySymbol ${NumberFormat('#,##0.00').format(borrower.outstandingAmount)}',
                  color:
                      borrower.outstandingAmount > 0 ? PdfColors.orange : null),
            ],
          ),
        ],
      );
    }

    // Default to loan list table
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pdfTableCell('Borrower', isHeader: true),
            pdfTableCell('Amount', isHeader: true),
            pdfTableCell('Date', isHeader: true),
            pdfTableCell('Due Date', isHeader: true),
            pdfTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows for loans
        ...section.items.map((item) {
          if (item is LoanReportItem) {
            final loan = item.loan;
            final isOverdue = loan.isOverdue;

            return pw.TableRow(
              children: [
                pdfTableCell(loan.borrowerName),
                pdfTableCell(
                    '$currencySymbol ${NumberFormat('#,##0.00').format(loan.loanAmount)}'),
                pdfTableCell(DateFormat('dd/MM/yyyy').format(loan.loanDate)),
                pdfTableCell(DateFormat('dd/MM/yyyy').format(loan.dueDate),
                    color: isOverdue ? PdfColors.red : null),
                pdfTableCell(
                  loan.status == LoanStatus.completed
                      ? 'Completed'
                      : (isOverdue ? 'Overdue' : 'Active'),
                  color: isOverdue
                      ? PdfColors.red
                      : (loan.status == LoanStatus.completed
                          ? PdfColors.green
                          : null),
                ),
              ],
            );
          } else {
            return pw.TableRow(
              children: [
                pdfTableCell('Unknown item type'),
                pdfTableCell(''),
                pdfTableCell(''),
                pdfTableCell(''),
                pdfTableCell(''),
              ],
            );
          }
        }),
        // Totals row if available
        if (section.sectionTotals.isNotEmpty)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              pdfTableCell('Total', isHeader: true),
              pdfTableCell(
                  '$currencySymbol ${NumberFormat('#,##0.00').format(section.sectionTotals['total'] ?? 0)}'),
              pdfTableCell(''),
              pdfTableCell(''),
              pdfTableCell(''),
            ],
          ),
      ],
    );
  }

  // Helper method for PDF info boxes
  pw.Widget pdfInfoBox(String label, String value, {PdfColor? color}) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 2),
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final report = reportProvider.currentReport;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: const Center(child: Text('No report available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(report.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: isExporting ? null : () => exportAsPdf(report),
            tooltip: 'Export as PDF',
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Charts'),
          ],
        ),
      ),
      body: isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting report...'),
                ],
              ),
            )
          : TabBarView(
              controller: tabController,
              children: [
                buildReportDetails(report),
                ReportChartView(report: report),
              ],
            ),
    );
  }

  Widget buildReportDetails(Report report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header
          buildReportHeader(report),
          const SizedBox(height: 24),

          // Report summary
          buildReportSummary(report),
          const SizedBox(height: 24),

          // Report sections
          ...report.sections.map((section) => buildReportSection(section)),
        ],
      ),
    );
  }

  Widget buildReportHeader(Report report) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.title,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text('Date Range: ${report.dateFilter.displayName}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text('Generated: ${report.formattedGeneratedDate}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReportSummary(Report report) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: theme.textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Key figures in a grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                buildSummaryCard(
                  'Total Loans',
                  '${report.summary.totalLoans}',
                  Icons.account_balance,
                ),
                buildSummaryCard(
                  'Active Loans',
                  '${report.summary.activeLoans}',
                  Icons.pending_actions,
                ),
                buildSummaryCard(
                  'Completed Loans',
                  '${report.summary.completedLoans}',
                  Icons.check_circle_outline,
                ),
                buildSummaryCard(
                  'Overdue Loans',
                  '${report.summary.overdueLoans}',
                  Icons.warning_amber,
                  highlight: report.summary.overdueLoans > 0,
                ),
                buildSummaryCard(
                  'Total Amount',
                  formatCurrency(report.summary.totalLoanAmount),
                  Icons.account_balance_wallet,
                ),
                buildSummaryCard(
                  'Paid Amount',
                  formatCurrency(report.summary.totalPaidAmount),
                  Icons.payments,
                ),
                buildSummaryCard(
                  'Outstanding',
                  formatCurrency(report.summary.totalOutstandingAmount),
                  Icons.money_off,
                  highlight: report.summary.totalOutstandingAmount > 0,
                ),
                buildSummaryCard(
                  'Overdue Amount',
                  formatCurrency(report.summary.overdueAmount),
                  Icons.warning,
                  highlight: report.summary.overdueAmount > 0,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Payment completion rate indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Completion Rate'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: report.summary.paymentCompletionRate / 100,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.summary.paymentCompletionRate.toStringAsFixed(2)}%',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryCard(String title, String value, IconData icon,
      {bool highlight = false}) {
    final theme = Theme.of(context);
    final valueColor = highlight ? Colors.red : theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: valueColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReportSection(ReportSection section) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Display content based on the first item type
            if (section.items.isEmpty)
              const Text('No data available for this section')
            else if (section.items.first is DateGroupReportItem)
              buildDateGroupSection(section)
            else if (section.items.first is BorrowerReportItem)
              buildBorrowerSection(section)
            else
              buildLoanListSection(section),
          ],
        ),
      ),
    );
  }

  Widget buildDateGroupSection(ReportSection section) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Period')),
          DataColumn(label: Text('New Loans')),
          DataColumn(label: Text('Total Lent')),
          DataColumn(label: Text('Total Received')),
          DataColumn(label: Text('Completed')),
        ],
        rows: section.items.map((item) {
          final dateItem = item as DateGroupReportItem;
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('MMM yyyy').format(dateItem.startDate))),
              DataCell(Text(dateItem.newLoans.toString())),
              DataCell(Text(formatCurrency(dateItem.totalLent))),
              DataCell(Text(formatCurrency(dateItem.totalReceived))),
              DataCell(Text(dateItem.completedLoans.toString())),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget buildBorrowerSection(ReportSection section) {
    final borrower = section.items.first as BorrowerReportItem;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Borrower: ${borrower.borrowerName}',
          style: theme.textTheme.titleMedium,
        ),
        if (borrower.whatsappNumber != null &&
            borrower.whatsappNumber!.isNotEmpty)
          Text('WhatsApp: ${borrower.whatsappNumber}'),
        const SizedBox(height: 16),

        // Borrower stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 2.3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            buildInfoBox('Total Loans', '${borrower.totalLoans}'),
            buildInfoBox('Active', '${borrower.activeLoans}'),
            buildInfoBox('Completed', '${borrower.completedLoans}'),
            buildInfoBox('Overdue', '${borrower.overdueLoans}',
                highlight: borrower.overdueLoans > 0),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 2.3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            buildInfoBox('Total Amount', formatCurrency(borrower.totalAmount)),
            buildInfoBox('Paid Amount', formatCurrency(borrower.paidAmount)),
            buildInfoBox(
                'Outstanding', formatCurrency(borrower.outstandingAmount),
                highlight: borrower.outstandingAmount > 0),
          ],
        ),

        // List loans from this borrower if available
        const SizedBox(height: 16),
        const Text('Loan Details:'),
        const SizedBox(height: 8),
        const Divider(),
        ...section.items.skip(1).map((item) {
          if (item is LoanReportItem) {
            return buildLoanItem(item.loan);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget buildLoanListSection(ReportSection section) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: section.items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = section.items[index];
        if (item is LoanReportItem) {
          return buildLoanItem(item.loan, showPayments: item.payments != null);
        }
        return const ListTile(title: Text('Unknown item type'));
      },
    );
  }

  Widget buildLoanItem(Loan loan, {bool showPayments = false}) {
    final theme = Theme.of(context);
    final isOverdue = loan.isOverdue;
    final isCompleted = loan.status == LoanStatus.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : (isOverdue ? Icons.warning : Icons.pending),
                color: isCompleted
                    ? Colors.green
                    : (isOverdue ? Colors.red : Colors.orange),
              ),
              const SizedBox(width: 8),
              Text(
                loan.borrowerName,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Chip(
                label: Text(
                  isCompleted
                      ? 'Completed'
                      : (isOverdue ? 'Overdue' : 'Active'),
                ),
                backgroundColor: isCompleted
                    ? Colors.green.withOpacity(0.2)
                    : (isOverdue
                        ? Colors.red.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              buildInfoBox('Loan Amount', formatCurrency(loan.loanAmount)),
              buildInfoBox('Paid', formatCurrency(loan.paidAmount)),
              buildInfoBox('Remaining', formatCurrency(loan.remainingAmount),
                  highlight: loan.remainingAmount > 0),
              buildInfoBox(
                  'Loan Date', DateFormat('dd MMM yyyy').format(loan.loanDate)),
              buildInfoBox(
                  'Due Date', DateFormat('dd MMM yyyy').format(loan.dueDate),
                  highlight: isOverdue),
              buildInfoBox('Phone', loan.whatsappNumber),
            ],
          ),

          // Show payments if available
          if (showPayments) ...[
            const SizedBox(height: 16),
            const Text('Payment History:'),
            const SizedBox(height: 8),
            // Payment history will be implemented here
          ],
        ],
      ),
    );
  }

  Widget buildInfoBox(String label, String value, {bool highlight = false}) {
    final theme = Theme.of(context);
    final valueColor =
        highlight ? Colors.red : theme.textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontSize: 12.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
