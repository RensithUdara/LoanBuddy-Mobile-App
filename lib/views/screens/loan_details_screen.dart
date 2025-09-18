import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/loan_provider.dart';
import '../../controllers/payment_provider.dart';
import '../../models/loan_model.dart';
import '../../models/payment_model.dart';
import '../../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class LoanDetailsScreen extends StatefulWidget {
  final int loanId;

  const LoanDetailsScreen({
    super.key,
    required this.loanId,
  });

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  Loan? _loan;
  bool _isLoading = true;
  final _paymentAmountController = TextEditingController();
  final _paymentNotesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLoanDetails();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadLoanDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final loan = await loanProvider.getLoan(widget.loanId);

      if (loan != null) {
        setState(() {
          _loan = loan;
          _isLoading = false;
        });

        // Load payment history for this loan
        final paymentProvider =
            Provider.of<PaymentProvider>(context, listen: false);
        await paymentProvider.loadPaymentsForLoan(widget.loanId);
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan not found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading loan details: $e')),
      );
      Navigator.pop(context);
    }
  }

  void _showAddPaymentModal() {
    if (_loan == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Payment',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _paymentDate = picked;
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
                    _showAddPaymentModal();
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy').format(_paymentDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentNotesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_paymentAmountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter payment amount')),
                    );
                    return;
                  }

                  try {
                    final amount = double.parse(_paymentAmountController.text
                        .replaceAll(RegExp(r'[^\d.]'), ''));

                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Amount must be greater than zero')),
                      );
                      return;
                    }

                    final payment = Payment(
                      loanId: widget.loanId,
                      paymentAmount: amount,
                      paymentDate: _paymentDate,
                      notes: _paymentNotesController.text.isNotEmpty
                          ? _paymentNotesController.text
                          : null,
                    );

                    final paymentProvider =
                        Provider.of<PaymentProvider>(context, listen: false);
                    final result = await paymentProvider.addPayment(payment);

                    if (result) {
                      if (!mounted) return;
                      Navigator.pop(context);
                      _paymentAmountController.clear();
                      _paymentNotesController.clear();
                      _paymentDate = DateTime.now();
                      _loadLoanDetails();
                    } else {
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add payment')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Save Payment'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    if (_loan == null) return;

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Loan',
        content:
            'Are you sure you want to delete this loan? All payment history will also be deleted. This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () async {
          if (_loan?.id != null) {
            final loanProvider =
                Provider.of<LoanProvider>(context, listen: false);
            final result = await loanProvider.deleteLoan(_loan!.id!);

            if (result) {
              if (!mounted) return;
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan deleted')),
              );
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete loan')),
              );
            }
          }
        },
      ),
    );
  }

  void _showSendMessageOptions() {
    if (_loan == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => MessageOptionsSheet(loan: _loan!),
    );
  }

  void _showDeletePaymentConfirmation(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Payment',
        content:
            'Are you sure you want to delete this payment? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () async {
          if (payment.id != null) {
            final paymentProvider =
                Provider.of<PaymentProvider>(context, listen: false);
            final result = await paymentProvider.deletePayment(
              payment.id!,
              payment.loanId,
              payment.paymentAmount,
            );

            if (result) {
              _loadLoanDetails();
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete payment')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Details')),
        body: const CustomLoadingIndicator(),
      );
    }

    if (_loan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Details')),
        body: const Center(child: Text('Loan not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_loan!.borrowerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Send WhatsApp Message',
            onPressed: _showSendMessageOptions,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Loan',
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLoanDetailsCard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.history),
                SizedBox(width: 8),
                Text('Payment History',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _buildPaymentHistory(),
          ),
        ],
      ),
      floatingActionButton: _loan!.status == LoanStatus.active
          ? FloatingActionButton(
              onPressed: _showAddPaymentModal,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildLoanDetailsCard() {
    final theme = Theme.of(context);
    final isOverdue = _loan!.isOverdue;

    return Card(
      margin: const EdgeInsets.all(Constants.defaultMargin),
      child: Padding(
        padding: const EdgeInsets.all(Constants.defaultPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Amount',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      Formatters.currencyFormat.format(_loan!.loanAmount),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _loan!.status == LoanStatus.completed
                        ? Colors.green.withOpacity(0.1)
                        : isOverdue
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _loan!.status == LoanStatus.completed
                        ? 'Completed'
                        : isOverdue
                            ? 'Overdue'
                            : 'Active',
                    style: TextStyle(
                      color: _loan!.status == LoanStatus.completed
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow(
                'Phone',
                Formatters.formatPhoneNumber(_loan!.whatsappNumber),
                Icons.phone_android),
            _buildDetailRow(
                'Remaining',
                Formatters.currencyFormat.format(_loan!.remainingAmount),
                Icons.account_balance_wallet),
            _buildDetailRow(
                'Paid',
                Formatters.currencyFormat.format(_loan!.paidAmount),
                Icons.payments),
            _buildDetailRow(
                'Loan Date',
                Formatters.dateFormat.format(_loan!.loanDate),
                Icons.calendar_today),
            _buildDetailRow(
              'Due Date',
              Formatters.dateFormat.format(_loan!.dueDate),
              Icons.event,
              isOverdue && _loan!.status == LoanStatus.active
                  ? Colors.red
                  : null,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _loan!.loanAmount > 0
                  ? _loan!.paidAmount / _loan!.loanAmount
                  : 0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _loan!.paidAmount / _loan!.loanAmount >= 1
                    ? Colors.green
                    : theme.colorScheme.primary,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              '${(_loan!.paidAmount / _loan!.loanAmount * 100).toStringAsFixed(0)}% Paid',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      [Color? valueColor]) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Text('$label:', style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        if (paymentProvider.isLoading) {
          return const CustomLoadingIndicator();
        }

        final payments = paymentProvider.payments;

        if (payments.isEmpty) {
          return const EmptyStateWidget(
            message: 'No payment history yet',
            icon: Icons.payments,
            buttonText: '', // No button
          );
        }

        return ListView.builder(
          itemCount: payments.length,
          padding: const EdgeInsets.only(bottom: 80), // For FAB
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: const Icon(Icons.payment),
                ),
                title: Text(
                    Formatters.currencyFormat.format(payment.paymentAmount)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formatters.dateFormat.format(payment.paymentDate)),
                    if (payment.notes != null && payment.notes!.isNotEmpty)
                      Text(
                        payment.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showDeletePaymentConfirmation(payment),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
