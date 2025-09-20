import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/report_provider.dart';
import '../../controllers/settings_provider.dart';
import '../../models/report_model.dart';
import 'report_view_screen.dart';

class ReportSelectionScreen extends StatefulWidget {
  const ReportSelectionScreen({super.key});

  @override
  State<ReportSelectionScreen> createState() => _ReportSelectionScreenState();
}

class _ReportSelectionScreenState extends State<ReportSelectionScreen> {
  ReportType _selectedReportType = ReportType.summary;
  DateFilterType _selectedDateFilterType = DateFilterType.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedBorrower;
  List<String> _borrowersList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _selectedReportType = settings.defaultReportType;
        _selectedDateFilterType = settings.defaultDateFilter;
      });
      _loadBorrowers();
    });
  }

  // Load the list of borrowers for filtering
  Future<void> _loadBorrowers() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final borrowers = await reportProvider.getAllBorrowers();
    setState(() {
      _borrowersList = borrowers;
    });
  }

  // Convert the selected date filter type to a ReportDateFilter
  ReportDateFilter _getDateFilter() {
    switch (_selectedDateFilterType) {
      case DateFilterType.all:
        return ReportDateFilter.all();
      case DateFilterType.thisMonth:
        return ReportDateFilter.thisMonth();
      case DateFilterType.lastMonth:
        return ReportDateFilter.lastMonth();
      case DateFilterType.thisYear:
        return ReportDateFilter.thisYear();
      case DateFilterType.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return ReportDateFilter.custom(_customStartDate!, _customEndDate!);
        }
        // Fall back to this month if custom dates aren't set
        return ReportDateFilter.thisMonth();
    }
  }

  // Generate the report and navigate to the view screen
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final success = await reportProvider.generateReport(
      type: _selectedReportType,
      dateFilter: _getDateFilter(),
      borrowerFilter: _selectedReportType == ReportType.detailed ? _selectedBorrower : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ReportViewScreen(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportProvider.error ?? 'Failed to generate report'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Type Selection
                  Text(
                    'Report Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  _buildReportTypeSelector(),
                  const SizedBox(height: 24.0),

                  // Date Filter Selection
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  _buildDateFilterSelector(),
                  const SizedBox(height: 16.0),

                  // Custom Date Range (if selected)
                  if (_selectedDateFilterType == DateFilterType.custom)
                    _buildCustomDateRangePicker(),

                  // Borrower Filter (only for detailed report)
                  if (_selectedReportType == ReportType.detailed) ...[
                    const SizedBox(height: 24.0),
                    Text(
                      'Borrower Filter (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8.0),
                    _buildBorrowerSelector(),
                  ],

                  const SizedBox(height: 32.0),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: const Text('Generate Report'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Card(
      child: Column(
        children: [
          for (final type in ReportType.values)
            RadioListTile<ReportType>(
              title: Text(_getReportTypeTitle(type)),
              subtitle: Text(_getReportTypeDescription(type)),
              value: type,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilterSelector() {
    return Card(
      child: Column(
        children: [
          for (final filterType in DateFilterType.values)
            RadioListTile<DateFilterType>(
              title: Text(_getDateFilterTitle(filterType)),
              value: filterType,
              groupValue: _selectedDateFilterType,
              onChanged: (value) {
                setState(() {
                  _selectedDateFilterType = value!;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomDateRangePicker() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Date',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4.0),
                  InkWell(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _customStartDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _customStartDate = selectedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _customStartDate == null
                                ? 'Select Date'
                                : '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year}',
                          ),
                          const Icon(Icons.calendar_today, size: 18.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End Date',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4.0),
                  InkWell(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _customEndDate ?? DateTime.now(),
                        firstDate: _customStartDate ?? DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _customEndDate = selectedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _customEndDate == null
                                ? 'Select Date'
                                : '${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}',
                          ),
                          const Icon(Icons.calendar_today, size: 18.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: _selectedBorrower,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'All Borrowers',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Borrowers'),
            ),
            ..._borrowersList.map(
              (borrower) => DropdownMenuItem<String>(
                value: borrower,
                child: Text(borrower),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedBorrower = value;
            });
          },
        ),
      ),
    );
  }

  // Helper methods to get human-readable titles and descriptions
  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.summary:
        return 'Summary Report';
      case ReportType.detailed:
        return 'Detailed Report';
      case ReportType.overdue:
        return 'Overdue Loans';
      case ReportType.byBorrower:
        return 'Borrower Analysis';
      case ReportType.byDate:
        return 'Date Analysis';
      case ReportType.paymentFlow:
        return 'Payment Flow';
    }
  }

  String _getReportTypeDescription(ReportType type) {
    switch (type) {
      case ReportType.summary:
        return 'Overall summary of your loans and payments';
      case ReportType.detailed:
        return 'Detailed information about loans with payment history';
      case ReportType.overdue:
        return 'Focus on overdue loans grouped by overdue period';
      case ReportType.byBorrower:
        return 'Analysis of loans grouped by borrowers';
      case ReportType.byDate:
        return 'Loan and payment activity grouped by date';
      case ReportType.paymentFlow:
        return 'Cash flow analysis of loan disbursements and payments';
    }
  }

  String _getDateFilterTitle(DateFilterType type) {
    switch (type) {
      case DateFilterType.all:
        return 'All Time';
      case DateFilterType.thisMonth:
        return 'This Month';
      case DateFilterType.lastMonth:
        return 'Last Month';
      case DateFilterType.thisYear:
        return 'This Year';
      case DateFilterType.custom:
        return 'Custom Range';
    }
  }
}