import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/loan_model.dart';

class WhatsAppService {
  static final currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  // Send WhatsApp message
  static Future<bool> sendWhatsAppMessage(Loan loan, String messageType) async {
    try {
      // Format the message based on messageType
      String message = getMessageByType(loan, messageType);

      // Format the phone number (remove spaces, +, etc)
      String phoneNumber = loan.whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');

      // If phone number doesn't start with country code, add Indian country code
      if (!phoneNumber.startsWith('94') && phoneNumber.length == 10) {
        phoneNumber = '94$phoneNumber';
      }

      // Create WhatsApp URL
      final Uri whatsappUrl = Uri.parse(
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

      // Launch URL
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        debugPrint('Could not launch WhatsApp');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
      return false;
    }
  }

  // Get message by type
  static String getMessageByType(Loan loan, String messageType) {
    final formattedLoanAmount = currencyFormatter.format(loan.loanAmount);
    final formattedRemainingAmount =
        currencyFormatter.format(loan.remainingAmount);
    final formattedDueDate = DateFormat('dd MMM yyyy').format(loan.dueDate);

    switch (messageType) {
      case 'friendly':
        return 'Hi ${loan.borrowerName}, this is a friendly reminder about your loan of $formattedLoanAmount. '
            'Remaining balance: $formattedRemainingAmount. '
            'Please let me know when you can make the next payment. Thanks!';

      case 'reminder':
        return 'Hello ${loan.borrowerName}, just a reminder that you have a pending loan balance of $formattedRemainingAmount. '
            'The loan is due on $formattedDueDate. '
            'Please arrange for payment at your earliest convenience. Thank you.';

      case 'urgent':
        return 'Hello ${loan.borrowerName}, your loan payment of $formattedLoanAmount was due on $formattedDueDate. '
            'Current balance: $formattedRemainingAmount. '
            'Please contact me to discuss payment. Thank you.';

      case 'confirmation':
        return 'Hi ${loan.borrowerName}, this is to confirm that I have received your recent payment. '
            'Your remaining balance is $formattedRemainingAmount. '
            'Thank you for your payment!';

      default:
        return 'Hi ${loan.borrowerName}, regarding your loan of $formattedLoanAmount. '
            'Current balance: $formattedRemainingAmount. '
            'Due date: $formattedDueDate. '
            'Thank you.';
    }
  }

  // Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    final Uri whatsappUri = Uri.parse('https://wa.me');
    return await canLaunchUrl(whatsappUri);
  }
}
