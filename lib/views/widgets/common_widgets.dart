import 'package:flutter/material.dart';

import '../../models/loan_model.dart';
import '../../services/whatsapp_service.dart';
import '../../utils/app_utils.dart';
import 'shimmer_effects.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = loan.isOverdue;

    // Status colors
    final statusColor = loan.status == LoanStatus.completed
        ? const Color(0xFF43A047) // Green
        : isOverdue
            ? const Color(0xFFE53935) // Red
            : const Color(0xFF1A73E8); // Blue

    final progressPercent =
        loan.loanAmount > 0 ? loan.paidAmount / loan.loanAmount : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: Constants.defaultMargin, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        loan.borrowerName.isNotEmpty
                            ? loan.borrowerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.borrowerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.smartphone,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatPhoneNumber(loan.whatsappNumber),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      loan.status == LoanStatus.completed
                          ? 'Completed'
                          : isOverdue
                              ? 'Overdue'
                              : 'Active',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAmountInfo(
                      context,
                      label: 'Loan Amount',
                      amount: loan.loanAmount,
                      color: theme.colorScheme.onSurface,
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    _buildAmountInfo(
                      context,
                      label: 'Remaining',
                      amount: loan.remainingAmount,
                      color: loan.remainingAmount > 0
                          ? isOverdue
                              ? const Color(0xFFE53935)
                              : theme.colorScheme.primary
                          : const Color(0xFF43A047),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due Date:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dateFormat.format(loan.dueDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isOverdue ? const Color(0xFFE53935) : null,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  loan.status == LoanStatus.active
                      ? Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.message_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                tooltip: 'Send WhatsApp Message',
                                onPressed: () async {
                                  // Show message options dialog
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: theme.colorScheme.surface,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) =>
                                        MessageOptionsSheet(loan: loan),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (onDelete != null)
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer
                                      .withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete Loan',
                                  onPressed: onDelete,
                                ),
                              ),
                          ],
                        )
                      : const SizedBox(),
                ],
              ),
              const SizedBox(height: 12),
              if (loan.status == LoanStatus.active)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(progressPercent * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progressPercent >= 1
                                ? const Color(0xFF43A047)
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressPercent >= 1
                              ? const Color(0xFF43A047)
                              : theme.colorScheme.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInfo(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.currencyFormat.format(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class MessageOptionsSheet extends StatelessWidget {
  final Loan loan;

  const MessageOptionsSheet({super.key, required this.loan});

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
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.buttonText = 'Add New Loan',
    this.onPressed,
  });

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
  final bool useShimmer;

  const CustomLoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.useShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useShimmer) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const ShimmerStatCardsLoading(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ShimmerEffect(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ShimmerEffect(
                        child: Container(
                          height: 32,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShimmerEffect(
                        child: Container(
                          height: 32,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShimmerEffect(
                        child: Container(
                          height: 32,
                          width: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) => const ShimmerLoanCardLoading(),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.confirmColor,
  });

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
