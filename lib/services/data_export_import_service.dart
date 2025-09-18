import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/loan_model.dart';
import '../models/payment_model.dart';
import 'database_helper.dart';

class DataExportImportService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Export all loans and their payments to CSV
  Future<String?> exportAllDataToCSV() async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
        status = await Permission.storage.status;
        if (!status.isGranted) {
          return 'Storage permission denied';
        }
      }

      // Get all loans and payments
      final loans = await _databaseHelper.getLoans();
      
      // Create CSV data for loans
      List<List<dynamic>> loanRows = [];
      loanRows.add([
        'ID', 'Borrower Name', 'WhatsApp Number', 'Loan Amount', 
        'Paid Amount', 'Loan Date', 'Due Date', 'Status', 
        'Created At', 'Updated At'
      ]);
      
      for (var loan in loans) {
        loanRows.add([
          loan.id,
          loan.borrowerName,
          loan.whatsappNumber,
          loan.loanAmount,
          loan.paidAmount,
          DateFormat('yyyy-MM-dd').format(loan.loanDate),
          DateFormat('yyyy-MM-dd').format(loan.dueDate),
          loan.status.name,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(loan.createdAt),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(loan.updatedAt),
        ]);
      }
      
      // Create CSV data for payments
      List<List<dynamic>> paymentRows = [];
      paymentRows.add([
        'ID', 'Loan ID', 'Payment Amount', 'Payment Date', 'Notes', 'Created At'
      ]);
      
      for (var loan in loans) {
        final payments = await _databaseHelper.getPaymentsForLoan(loan.id!);
        for (var payment in payments) {
          paymentRows.add([
            payment.id,
            payment.loanId,
            payment.paymentAmount,
            DateFormat('yyyy-MM-dd').format(payment.paymentDate),
            payment.notes ?? '',
            DateFormat('yyyy-MM-dd HH:mm:ss').format(payment.createdAt),
          ]);
        }
      }
      
      // Convert to CSV
      String loanCsv = const ListToCsvConverter().convert(loanRows);
      String paymentCsv = const ListToCsvConverter().convert(paymentRows);
      
      // Get timestamp for filenames
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      
      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        return 'Could not access storage directory';
      }
      
      // Create export directory if it doesn't exist
      final exportDir = Directory('${directory.path}/LoanBuddy_Exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      // Create loan CSV file
      File loanFile = File('${exportDir.path}/loanbuddy_loans_$timestamp.csv');
      await loanFile.writeAsString(loanCsv);
      
      // Create payment CSV file
      File paymentFile = File('${exportDir.path}/loanbuddy_payments_$timestamp.csv');
      await paymentFile.writeAsString(paymentCsv);
      
      return exportDir.path;
    } catch (e) {
      return 'Error exporting data: $e';
    }
  }
  
  // Import loans from CSV
  Future<String> importLoansFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (result == null) {
        return 'No file selected';
      }
      
      String? filePath = result.files.single.path;
      if (filePath == null) {
        return 'Invalid file path';
      }
      
      File file = File(filePath);
      String csvData = await file.readAsString();
      
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvData);
      
      // Check if this is a loans or payments file
      if (rowsAsListOfValues.isEmpty) {
        return 'Empty file';
      }
      
      List<String> headers = rowsAsListOfValues[0].map((e) => e.toString()).toList();
      
      // Check if it's a loans file
      if (headers.contains('Borrower Name') && headers.contains('Loan Amount')) {
        return await _importLoans(rowsAsListOfValues);
      } 
      // Check if it's a payments file
      else if (headers.contains('Loan ID') && headers.contains('Payment Amount')) {
        return await _importPayments(rowsAsListOfValues);
      } else {
        return 'Invalid file format';
      }
      
    } catch (e) {
      return 'Error importing data: $e';
    }
  }
  
  // Helper method to import loans
  Future<String> _importLoans(List<List<dynamic>> rows) async {
    try {
      int successCount = 0;
      int errorCount = 0;
      
      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        try {
          var row = rows[i];
          
          // Create loan from CSV data
          final loan = Loan(
            borrowerName: row[1].toString(),
            whatsappNumber: row[2].toString(),
            loanAmount: double.parse(row[3].toString()),
            paidAmount: double.parse(row[4].toString()),
            loanDate: DateFormat('yyyy-MM-dd').parse(row[5].toString()),
            dueDate: DateFormat('yyyy-MM-dd').parse(row[6].toString()),
            status: row[7].toString() == LoanStatus.completed.name 
                ? LoanStatus.completed 
                : LoanStatus.active,
            createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').parse(row[8].toString()),
            updatedAt: DateFormat('yyyy-MM-dd HH:mm:ss').parse(row[9].toString()),
          );
          
          await _databaseHelper.insertLoan(loan);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }
      
      return 'Imported $successCount loans successfully. $errorCount had errors.';
    } catch (e) {
      return 'Error importing loans: $e';
    }
  }
  
  // Helper method to import payments
  Future<String> _importPayments(List<List<dynamic>> rows) async {
    try {
      int successCount = 0;
      int errorCount = 0;
      
      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        try {
          var row = rows[i];
          
          // Create payment from CSV data
          final payment = Payment(
            loanId: int.parse(row[1].toString()),
            paymentAmount: double.parse(row[2].toString()),
            paymentDate: DateFormat('yyyy-MM-dd').parse(row[3].toString()),
            notes: row[4].toString(),
            createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').parse(row[5].toString()),
          );
          
          await _databaseHelper.insertPayment(payment);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }
      
      return 'Imported $successCount payments successfully. $errorCount had errors.';
    } catch (e) {
      return 'Error importing payments: $e';
    }
  }
}