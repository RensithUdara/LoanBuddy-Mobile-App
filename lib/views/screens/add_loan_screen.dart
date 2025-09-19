import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/loan_provider.dart';
import '../../models/loan_model.dart';
import '../../utils/app_utils.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _loanDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isLoanDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isLoanDate ? _loanDate : _dueDate,
      firstDate: isLoanDate ? DateTime(2020) : _loanDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isLoanDate) {
          _loanDate = picked;
          // Update due date to be at least the loan date
          if (_dueDate.isBefore(_loanDate)) {
            _dueDate = _loanDate.add(const Duration(days: 30));
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _saveLoan() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Parse the amount
        final amount = double.parse(
            _amountController.text.replaceAll(RegExp(r'[^\d.]'), ''));

        // Create the loan object
        final loan = Loan(
          borrowerName: _nameController.text,
          whatsappNumber: _phoneController.text,
          loanAmount: amount,
          loanDate: _loanDate,
          dueDate: _dueDate,
        );

        // Save to database via provider
        final loanProvider = Provider.of<LoanProvider>(context, listen: false);
        final result = await loanProvider.addLoan(loan);

        if (result) {
          if (!mounted) return;
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add loan')),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Loan'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Borrower Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.nameValidator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number',
                        prefixIcon: Icon(Icons.phone_android),
                        hintText: '10-digit number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: Validators.phoneNumberValidator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount',
                        prefixIcon: Icon(Icons.currency_rupee),
                        prefixText: 'Rs. ',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.amountValidator,
                    ),
                    const SizedBox(height: 24),
                    _buildDateField(
                      label: 'Loan Date',
                      date: _loanDate,
                      onTap: () => _selectDate(context, true),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Due Date',
                      date: _dueDate,
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveLoan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Loan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('dd MMMM yyyy').format(date),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
