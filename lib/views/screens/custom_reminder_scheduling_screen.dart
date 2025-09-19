import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/loan_provider.dart';
import '../../models/loan_model.dart';
// import '../../services/patched_notification_service.dart';

class CustomReminderSchedulingScreen extends StatefulWidget {
  const CustomReminderSchedulingScreen({super.key});

  @override
  State<CustomReminderSchedulingScreen> createState() =>
      _CustomReminderSchedulingScreenState();
}

class _CustomReminderSchedulingScreenState
    extends State<CustomReminderSchedulingScreen> {
  bool _isNotificationsEnabled = false;
  bool _isLoading = true;
  List<Loan> _activeLoans = [];
  Map<int, bool> _reminderEnabledMap = {};
  Map<int, int> _reminderDaysMap = {}; // days before due date

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadLoans();
  }

  Future<void> _initializeNotifications() async {
    // Notification functionality commented out for now
    // In a real implementation, we would request permissions here
    
    setState(() {
      // For demo purposes, we'll just set this to true
      _isNotificationsEnabled = true;
    });
  }  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
    });

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    await loanProvider.loadLoans();

    final activeLoans = loanProvider.loans
        .where((loan) => loan.status == LoanStatus.active)
        .toList();

    // Initialize reminder settings from shared preferences
    // In a real implementation, this would load from persistent storage
    Map<int, bool> reminderMap = {};
    Map<int, int> daysMap = {};

    for (var loan in activeLoans) {
      if (loan.id != null) {
        reminderMap[loan.id!] = true; // Default to enabled
        daysMap[loan.id!] = 3; // Default to 3 days before
      }
    }

    setState(() {
      _activeLoans = activeLoans;
      _reminderEnabledMap = reminderMap;
      _reminderDaysMap = daysMap;
      _isLoading = false;
    });
  }

  Future<void> _saveReminderSettings(
      int loanId, bool isEnabled, int days) async {
    setState(() {
      _reminderEnabledMap[loanId] = isEnabled;
      _reminderDaysMap[loanId] = days;
    });

    // In a real implementation, save to persistent storage

    // Schedule notification if enabled
    if (isEnabled) {
      final loan = _activeLoans.firstWhere((loan) => loan.id == loanId);
      await _scheduleNotification(loan, days);
    }
  }

  Future<void> _scheduleNotification(Loan loan, int daysBeforeDue) async {
    // Get the notification date (due date - days before)
    final notificationDate =
        loan.dueDate.subtract(Duration(days: daysBeforeDue));

    // Only schedule if the notification date is in the future
    if (notificationDate.isAfter(DateTime.now())) {
      await PatchedNotificationService.scheduleDueDateReminder(
        loan,
        daysBeforeDue,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(theme, isDarkMode),
                Expanded(
                  child: _activeLoans.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeLoans.length,
                          itemBuilder: (context, index) {
                            final loan = _activeLoans[index];
                            return _buildLoanReminderCard(
                                loan, theme, isDarkMode);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDarkMode ? Colors.grey[850] : theme.primaryColor.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Payment Reminders',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule custom reminders for your active loans',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _isNotificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _isNotificationsEnabled ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _isNotificationsEnabled
                    ? 'Notifications are enabled'
                    : 'Notifications are disabled. Please enable them in settings.',
                style: TextStyle(
                  color: _isNotificationsEnabled ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Loans',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some active loans to schedule reminders for them',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanReminderCard(Loan loan, ThemeData theme, bool isDarkMode) {
    final loanId = loan.id!;
    final isReminderEnabled = _reminderEnabledMap[loanId] ?? false;
    final reminderDays = _reminderDaysMap[loanId] ?? 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.borrowerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(loan.dueDate)}',
                        style: TextStyle(
                          color: loan.isOverdue ? Colors.red : null,
                          fontWeight: loan.isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount: \$${loan.remainingAmount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isReminderEnabled,
                  onChanged: (value) {
                    _saveReminderSettings(loanId, value, reminderDays);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Reminder Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Remind me'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: reminderDays,
                  isDense: true,
                  items: [1, 2, 3, 5, 7, 10, 14, 30].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  onChanged: isReminderEnabled
                      ? (newValue) {
                          if (newValue != null) {
                            _saveReminderSettings(loanId, true, newValue);
                          }
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                const Text('days before due date'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isReminderEnabled
                      ? 'Reminder scheduled for ${DateFormat('MMM dd, yyyy').format(loan.dueDate.subtract(Duration(days: reminderDays)))}'
                      : 'Reminder disabled',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isReminderEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
