import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/loan_provider.dart';
import '../../controllers/payment_provider.dart';
import '../../models/loan_model.dart';
import '../../models/payment_model.dart';
import '../../utils/app_utils.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedTimeRange = 'Last 6 Months';
  final List<String> _timeRanges = ['Last Month', 'Last 3 Months', 'Last 6 Months', 'Last Year', 'All Time'];
  bool _isLoading = true;
  
  // Chart data
  List<FlSpot> _paymentTrendsData = [];
  List<PieChartSectionData> _loanStatusData = [];
  Map<String, double> _borrowerDistribution = {};
  
  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }
  
  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _generateChartData();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _generateChartData() async {
    // Get data from providers
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    await loanProvider.loadLoans();
    final loans = loanProvider.loans;
    
    // Generate payment trends data
    final now = DateTime.now();
    final startDate = _getStartDateFromRange(_selectedTimeRange);
    
    // Map to store payments by month
    Map<String, double> paymentsByMonth = {};
    
    // Generate all months in range for x-axis
    DateTime current = DateTime(startDate.year, startDate.month);
    while (current.isBefore(now) || current.month == now.month && current.year == now.year) {
      final monthKey = DateFormat('yyyy-MM').format(current);
      paymentsByMonth[monthKey] = 0.0;
      current = DateTime(current.year + (current.month == 12 ? 1 : 0), current.month == 12 ? 1 : current.month + 1);
    }
    
    // Populate payment data
    for (var loan in loans) {
      final payments = await paymentProvider.loadPaymentsForLoan(loan.id!);
      
      // Check if payments is not null before iterating
      if (payments != null) {
        for (var payment in payments) {
          if (payment.paymentDate.isAfter(startDate)) {
            final monthKey = DateFormat('yyyy-MM').format(payment.paymentDate);
            if (paymentsByMonth.containsKey(monthKey)) {
              paymentsByMonth[monthKey] = (paymentsByMonth[monthKey] ?? 0) + payment.paymentAmount;
            }
          }
        }
      }
    }
    
    // Convert to FL Chart spots
    List<FlSpot> spots = [];
    int index = 0;
    paymentsByMonth.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value));
      index++;
    });
    
    // Generate loan status data
    int activeLoans = 0;
    int completedLoans = 0;
    int overdueLoans = 0;
    
    // Borrower distribution data
    Map<String, double> borrowerAmounts = {};
    
    for (var loan in loans) {
      // Count loan statuses
      if (loan.status == LoanStatus.completed) {
        completedLoans++;
      } else if (loan.isOverdue) {
        overdueLoans++;
      } else {
        activeLoans++;
      }
      
      // Sum loan amounts by borrower
      if (borrowerAmounts.containsKey(loan.borrowerName)) {
        borrowerAmounts[loan.borrowerName] = (borrowerAmounts[loan.borrowerName] ?? 0) + loan.remainingAmount;
      } else {
        borrowerAmounts[loan.borrowerName] = loan.remainingAmount;
      }
    }
    
    // Generate pie chart sections for loan status
    List<PieChartSectionData> pieData = [];
    if (activeLoans > 0) {
      pieData.add(_generatePieSection('Active', activeLoans.toDouble(), Colors.blue));
    }
    if (completedLoans > 0) {
      pieData.add(_generatePieSection('Completed', completedLoans.toDouble(), Colors.green));
    }
    if (overdueLoans > 0) {
      pieData.add(_generatePieSection('Overdue', overdueLoans.toDouble(), Colors.red));
    }
    
    // Get top 5 borrowers by amount
    Map<String, double> topBorrowers = {};
    borrowerAmounts.entries
        .toList()
        .sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < borrowerAmounts.length && i < 5; i++) {
      final entry = borrowerAmounts.entries.elementAt(i);
      topBorrowers[entry.key] = entry.value;
    }
    
    // Update state with new data
    setState(() {
      _paymentTrendsData = spots;
      _loanStatusData = pieData;
      _borrowerDistribution = topBorrowers;
    });
  }
  
  DateTime _getStartDateFromRange(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'Last Month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'Last 3 Months':
        return DateTime(now.year, now.month - 3, now.day);
      case 'Last 6 Months':
        return DateTime(now.year, now.month - 6, now.day);
      case 'Last Year':
        return DateTime(now.year - 1, now.month, now.day);
      case 'All Time':
      default:
        return DateTime(2020, 1, 1); // Far back in time
    }
  }
  
  PieChartSectionData _generatePieSection(String title, double value, Color color) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: '$title\n${value.toInt()}',
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildTimeRangeSelector(theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Payment Trends', theme),
                  const SizedBox(height: 8),
                  _buildPaymentTrendsChart(cardColor, theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Loan Status Distribution', theme),
                  const SizedBox(height: 8),
                  _buildLoanStatusChart(cardColor, theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Top Borrowers', theme),
                  const SizedBox(height: 8),
                  _buildTopBorrowersList(cardColor, theme),
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton(
                      onPressed: _loadAnalyticsData,
                      child: const Text('Refresh Data'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
  
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Dashboard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visualize your loan data and track payment trends',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeRangeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeRange,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _timeRanges.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTimeRange = newValue;
              });
              _loadAnalyticsData();
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildPaymentTrendsChart(Color? cardColor, ThemeData theme) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 250,
          child: _paymentTrendsData.isEmpty
              ? Center(
                  child: Text(
                    'No payment data available for this period',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat.compact().format(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    minX: 0,
                    maxX: (_paymentTrendsData.length - 1).toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _paymentTrendsData,
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildLoanStatusChart(Color? cardColor, ThemeData theme) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 250,
          child: _loanStatusData.isEmpty
              ? Center(
                  child: Text(
                    'No loan data available',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : PieChart(
                  PieChartData(
                    sections: _loanStatusData,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildTopBorrowersList(Color? cardColor, ThemeData theme) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _borrowerDistribution.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No borrower data available',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            : Column(
                children: _borrowerDistribution.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: LinearProgressIndicator(
                                value: entry.value /
                                    _borrowerDistribution.values.reduce((a, b) => a > b ? a : b),
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              NumberFormat.currency(symbol: '\$').format(entry.value),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}