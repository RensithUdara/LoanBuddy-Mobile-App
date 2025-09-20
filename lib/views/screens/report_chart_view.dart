import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/report_model.dart';
import '../../models/loan_model.dart';

class ReportChartView extends StatefulWidget {
  final Report report;

  const ReportChartView({super.key, required this.report});

  @override
  State<ReportChartView> createState() => _ReportChartViewState();
}

class _ReportChartViewState extends State<ReportChartView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Charts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSummaryPieChart(),
                  const SizedBox(height: 24),
                  _buildLoanStatusChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Report type specific charts
          _buildReportSpecificCharts(),
        ],
      ),
    );
  }

  Widget _buildSummaryPieChart() {
    final summary = widget.report.summary;

    // For the pie chart, we'll display paid vs outstanding
    final paidAmount = summary.totalPaidAmount;
    final outstandingAmount = summary.totalOutstandingAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Distribution',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: paidAmount,
                        title: '${(summary.paymentCompletionRate).toStringAsFixed(0)}%',
                        color: Colors.green,
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      PieChartSectionData(
                        value: outstandingAmount,
                        title: '${(100 - summary.paymentCompletionRate).toStringAsFixed(0)}%',
                        color: Colors.orange,
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('Paid', Colors.green),
                  const SizedBox(height: 8),
                  _buildLegendItem('Outstanding', Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanStatusChart() {
    final summary = widget.report.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loan Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: summary.totalLoans.toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            List<String> titles = ['Active', 'Completed', 'Overdue'];
                            if (value >= 0 && value < titles.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  titles[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barGroups: [
                      // Active loans (excluding overdue)
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: (summary.activeLoans - summary.overdueLoans).toDouble(),
                            color: Colors.blue,
                            width: 22,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      // Completed loans
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: summary.completedLoans.toDouble(),
                            color: Colors.green,
                            width: 22,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      // Overdue loans
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: summary.overdueLoans.toDouble(),
                            color: Colors.red,
                            width: 22,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('Active', Colors.blue),
                  const SizedBox(height: 8),
                  _buildLegendItem('Completed', Colors.green),
                  const SizedBox(height: 8),
                  _buildLegendItem('Overdue', Colors.red),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportSpecificCharts() {
    // Build different charts based on the report type
    switch (widget.report.type) {
      case ReportType.paymentFlow:
        return _buildPaymentFlowChart();
      case ReportType.byDate:
        return _buildDateAnalysisChart();
      case ReportType.byBorrower:
        return _buildBorrowerChart();
      case ReportType.overdue:
        return _buildOverdueChart();
      default:
        return const SizedBox.shrink(); // No specific charts for other types
    }
  }

  Widget _buildPaymentFlowChart() {
    // Extract data from report
    final sections = widget.report.sections;
    if (sections.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Prepare data for the line chart
    List<FlSpot> lentSpots = [];
    List<FlSpot> receivedSpots = [];
    List<String> bottomTitles = [];

    int index = 0;
    for (final section in sections) {
      if (section.items.isEmpty || section.items.first is! DateGroupReportItem) {
        continue;
      }

      final dateItem = section.items.first as DateGroupReportItem;
      lentSpots.add(FlSpot(index.toDouble(), dateItem.totalLent));
      receivedSpots.add(FlSpot(index.toDouble(), dateItem.totalReceived));
      bottomTitles.add(DateFormat('MMM yy').format(dateItem.startDate));
      index++;
    }

    if (lentSpots.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Flow Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1000,
                    verticalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < bottomTitles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                bottomTitles[index],
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black12),
                  ),
                  minX: 0,
                  maxX: (bottomTitles.length - 1).toDouble(),
                  lineBarsData: [
                    // Money lent line
                    LineChartBarData(
                      spots: lentSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                    // Money received line
                    LineChartBarData(
                      spots: receivedSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Money Lent', Colors.red),
                const SizedBox(width: 24),
                _buildLegendItem('Money Received', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAnalysisChart() {
    // Similar to payment flow but focused on new loans and completions
    final sections = widget.report.sections;
    if (sections.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Prepare data for the line chart
    List<FlSpot> newLoanSpots = [];
    List<FlSpot> completedSpots = [];
    List<String> bottomTitles = [];

    int index = 0;
    for (final section in sections) {
      if (section.sectionTotals.isEmpty) {
        continue;
      }

      final newLoans = section.sectionTotals['newLoans'] ?? 0.0;
      final completedLoans = section.sectionTotals['completedLoans'] ?? 0.0;
      
      newLoanSpots.add(FlSpot(index.toDouble(), newLoans));
      completedSpots.add(FlSpot(index.toDouble(), completedLoans));
      bottomTitles.add(section.title);
      index++;
    }

    if (newLoanSpots.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Activity Over Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < bottomTitles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                bottomTitles[index],
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black12),
                  ),
                  minX: 0,
                  maxX: (bottomTitles.length - 1).toDouble(),
                  lineBarsData: [
                    // New loans line
                    LineChartBarData(
                      spots: newLoanSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                    // Completed loans line
                    LineChartBarData(
                      spots: completedSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('New Loans', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Completed Loans', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowerChart() {
    final sections = widget.report.sections;
    if (sections.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Get top 5 borrowers by outstanding amount
    final sortedSections = List<ReportSection>.from(sections)
      ..sort((a, b) => 
          (b.sectionTotals['outstandingAmount'] ?? 0)
              .compareTo(a.sectionTotals['outstandingAmount'] ?? 0));
    
    final topBorrowers = sortedSections.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Borrowers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: topBorrowers.isEmpty 
                      ? 0 
                      : (topBorrowers.map((s) => s.sectionTotals['totalAmount'] ?? 0.0).reduce((a, b) => a > b ? a : b) * 1.2),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex < topBorrowers.length) {
                          final section = topBorrowers[groupIndex];
                          final totalAmount = section.sectionTotals['totalAmount'] ?? 0.0;
                          final paidAmount = section.sectionTotals['paidAmount'] ?? 0.0;
                          final outstandingAmount = section.sectionTotals['outstandingAmount'] ?? 0.0;
                          
                          return BarTooltipItem(
                            '${section.title}\n'
                            'Total: ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(totalAmount)}\n'
                            'Paid: ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(paidAmount)}\n'
                            'Outstanding: ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(outstandingAmount)}',
                            const TextStyle(color: Colors.white),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < topBorrowers.length) {
                            // Truncate borrower name if too long
                            String name = topBorrowers[index].title;
                            if (name.length > 10) {
                              name = '${name.substring(0, 8)}...';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(topBorrowers.length, (index) {
                    final section = topBorrowers[index];
                    final totalAmount = section.sectionTotals['totalAmount'] ?? 0.0;
                    final paidAmount = section.sectionTotals['paidAmount'] ?? 0.0;
                    final outstandingAmount = section.sectionTotals['outstandingAmount'] ?? 0.0;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: totalAmount,
                          rodStackItems: [
                            BarChartRodStackItem(0, paidAmount, Colors.green),
                            BarChartRodStackItem(paidAmount, totalAmount, Colors.orange),
                          ],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          width: 22,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Paid Amount', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('Outstanding Amount', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueChart() {
    final sections = widget.report.sections;
    if (sections.isEmpty) {
      return const Center(child: Text('No overdue loans'));
    }

    // Calculate values for overdue periods
    Map<String, double> overdueValues = {};
    for (var section in sections) {
      overdueValues[section.title] = section.sectionTotals['outstandingAmount'] ?? 0.0;
    }

    // Standard overdue periods
    final List<String> periods = [
      'Under 30 Days',
      '30-60 Days',
      '60-90 Days',
      'Over 90 Days',
    ];

    // Ensure all periods are present in the map
    for (var period in periods) {
      overdueValues.putIfAbsent(period, () => 0.0);
    }

    // Create data for the chart
    List<PieChartSectionData> sections = [];
    int i = 0;
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];

    periods.forEach((period) {
      final value = overdueValues[period] ?? 0.0;
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            value: value,
            title: period,
            color: colors[i % colors.length],
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      i++;
    });

    if (sections.isEmpty) {
      return const Center(child: Text('No overdue loans'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overdue Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int j = 0; j < periods.length; j++)
                        if (overdueValues[periods[j]]! > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: _buildLegendItem(periods[j], colors[j]),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}