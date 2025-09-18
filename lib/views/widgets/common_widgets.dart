import 'package:flutter/material.dart';
import '../../models/loan_model.dart';
import '../../utils/app_utils.dart';
import '../../services/whatsapp_service.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LoanCard({
    Key? key,
    required this.loan,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = loan.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Constants.defaultMargin, 
        vertical: 8
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Constants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      loan.borrowerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: loan.status == LoanStatus.completed
                          ? Colors.green.withOpacity(0.1)
                          : isOverdue
                              ? Colors.red.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      loan.status == LoanStatus.completed
                          ? 'Completed'
                          : isOverdue
                              ? 'Overdue'
                              : 'Active',
                      style: TextStyle(
                        color: loan.status == LoanStatus.completed
                            ? Colors.green
                            : isOverdue
                                ? Colors.red
                                : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.smartphone, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatPhoneNumber(loan.whatsappNumber),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                        Formatters.currencyFormat.format(loan.loanAmount),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        Formatters.currencyFormat.format(loan.remainingAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: loan.remainingAmount > 0
                              ? isOverdue
                                  ? Colors.red
                                  : theme.colorScheme.primary
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        Formatters.dateFormat.format(loan.dueDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isOverdue ? Colors.red : null,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  loan.status == LoanStatus.active
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.message),
                              tooltip: 'Send WhatsApp Message',
                              onPressed: () async {
                                // Show message options dialog
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => MessageOptionsSheet(loan: loan),
                                );
                              },
                            ),
                            if (onDelete != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete Loan',
                                onPressed: onDelete,
                              ),
                          ],
                        )
                      : const SizedBox(),
                ],
              ),
              if (loan.status == LoanStatus.active) 
                LinearProgressIndicator(
                  value: loan.loanAmount > 0
                      ? loan.paidAmount / loan.loanAmount
                      : 0,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loan.paidAmount / loan.loanAmount >= 1
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                  minHeight: 5,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageOptionsSheet extends StatelessWidget {
  final Loan loan;

  const MessageOptionsSheet({Key? key, required this.loan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Send WhatsApp Message',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: const Text('Friendly Reminder'),
          onTap: () {
            Navigator.pop(context);
            WhatsAppService.sendWhatsAppMessage(loan, 'friendly');
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Payment Reminder'),
          onTap: () {
            Navigator.pop(context);
            WhatsAppService.sendWhatsAppMessage(loan, 'reminder');
          },
        ),
        ListTile(
          leading: const Icon(Icons.warning_amber_outlined),
          title: const Text('Urgent Reminder'),
          onTap: () {
            Navigator.pop(context);
            WhatsAppService.sendWhatsAppMessage(loan, 'urgent');
          },
        ),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Payment Confirmation'),
          onTap: () {
            Navigator.pop(context);
            WhatsAppService.sendWhatsAppMessage(loan, 'confirmation');
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final String buttonText;
  final VoidCallback? onPressed;

  const EmptyStateWidget({
    Key? key,
    required this.message,
    this.icon = Icons.info_outline,
    this.buttonText = 'Add New Loan',
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            if (onPressed != null)
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonText),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomLoadingIndicator extends StatelessWidget {
  final String message;

  const CustomLoadingIndicator({
    Key? key,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final Color? confirmColor;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.confirmColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: confirmColor != null
              ? TextButton.styleFrom(foregroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}