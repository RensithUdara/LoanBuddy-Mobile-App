import 'package:flutter/material.dart';

import '../../services/data_export_import_service.dart';

class DataExportImportScreen extends StatefulWidget {
  const DataExportImportScreen({super.key});

  @override
  State<DataExportImportScreen> createState() => _DataExportImportScreenState();
}

class _DataExportImportScreenState extends State<DataExportImportScreen> {
  final DataExportImportService _dataService = DataExportImportService();
  bool _isExporting = false;
  bool _isImporting = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export/Import Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Export your loan and payment data to backup or transfer to another device.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            _buildFeatureCard(
              icon: Icons.file_download_outlined,
              title: 'Export Data',
              description: 'Export all loans and payments to CSV files',
              buttonText: 'Export',
              isLoading: _isExporting,
              onPressed: _exportData,
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              icon: Icons.file_upload_outlined,
              title: 'Import Data',
              description: 'Import loans and payments from CSV files',
              buttonText: 'Import',
              isLoading: _isImporting,
              onPressed: _importData,
            ),
            const SizedBox(height: 30),
            if (_resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultMessage.contains('Error') || _resultMessage.contains('denied')
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _resultMessage.contains('Error') || _resultMessage.contains('denied')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _resultMessage.contains('Error') || _resultMessage.contains('denied')
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _resultMessage,
                        style: TextStyle(
                          color: _resultMessage.contains('Error') || _resultMessage.contains('denied')
                              ? Colors.red
                              : Colors.green,
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _resultMessage = '';
    });

    try {
      final result = await _dataService.exportAllDataToCSV();
      if (result != null) {
        if (result.contains('Error') || result.contains('permission denied')) {
          setState(() {
            _resultMessage = result;
          });
        } else {
          setState(() {
            _resultMessage = 'Data exported successfully to: $result';
          });
        }
      } else {
        setState(() {
          _resultMessage = 'Failed to export data';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
      _resultMessage = '';
    });

    try {
      final result = await _dataService.importLoansFromCSV();
      setState(() {
        _resultMessage = result;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }
}