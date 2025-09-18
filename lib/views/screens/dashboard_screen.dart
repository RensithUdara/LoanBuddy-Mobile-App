import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/loan_provider.dart';
import '../../models/loan_model.dart';
import '../../utils/app_utils.dart';
import '../widgets/common_widgets.dart';
import 'add_loan_screen.dart';
import 'loan_details_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load loans when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      loanProvider.loadLoans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String? value) {
    if (value == null) return;
    setState(() {
      _filter = value;
    });

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    switch (value) {
      case 'active':
        loanProvider.loadActiveLoans();
        break;
      case 'completed':
        loanProvider.loadCompletedLoans();
        break;
      case 'all':
      default:
        loanProvider.loadLoans();
        break;
    }
  }

  void _searchLoans(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showDeleteConfirmation(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Loan',
        content:
            'Are you sure you want to delete this loan? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () {
          if (loan.id != null) {
            final loanProvider =
                Provider.of<LoanProvider>(context, listen: false);
            loanProvider.deleteLoan(loan.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loan deleted')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoanBuddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatCards(),
          _buildSearchAndFilters(),
          Expanded(
            child: _buildLoansList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddLoanScreen()),
          );

          if (result == true) {
            // Reload loans if a new loan was added
            if (!mounted) return;
            Provider.of<LoanProvider>(context, listen: false).loadLoans();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCards() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, _) {
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  'Your Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildGradientCard(
                      title: 'Total Outstanding',
                      value: Formatters.currencyFormat
                          .format(loanProvider.totalOutstandingAmount),
                      icon: Icons.account_balance,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF6C92F4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildGradientCard(
                      title: 'Total Loans',
                      value: '${loanProvider.loans.length}',
                      icon: Icons.people,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Active',
                      value:
                          '${loanProvider.loans.where((loan) => loan.status == LoanStatus.active).length}',
                      icon: Icons.hourglass_bottom,
                      color: const Color(0xFFFFA726),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Overdue',
                      value:
                          '${loanProvider.loans.where((loan) => loan.status == LoanStatus.active && loan.isOverdue).length}',
                      icon: Icons.warning_amber_outlined,
                      color: const Color(0xFFE53935),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Completed',
                      value:
                          '${loanProvider.loans.where((loan) => loan.status == LoanStatus.completed).length}',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF43A047),
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradientCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    final brightness = theme.brightness;
    final cardColor = brightness == Brightness.light
        ? color.withOpacity(0.12)
        : color.withOpacity(0.24);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by borrower name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _searchLoans,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Active', 'active'),
                _buildFilterChip('Completed', 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (selected) {
          if (selected) {
            _onFilterChanged(value);
          }
        },
      ),
    );
  }

  Widget _buildLoansList() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, _) {
        if (loanProvider.isLoading) {
          return const CustomLoadingIndicator();
        }

        final filteredLoans = _searchQuery.isEmpty
            ? loanProvider.loans
            : loanProvider.searchLoans(_searchQuery);

        if (filteredLoans.isEmpty) {
          return EmptyStateWidget(
            message: _searchQuery.isNotEmpty
                ? 'No loans match your search'
                : 'No loans yet. Add your first loan!',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddLoanScreen()),
              );

              if (result == true && mounted) {
                Provider.of<LoanProvider>(context, listen: false).loadLoans();
              }
            },
          );
        }

        return ListView.builder(
          itemCount: filteredLoans.length,
          padding: const EdgeInsets.only(bottom: 80), // For FAB
          itemBuilder: (context, index) {
            final loan = filteredLoans[index];
            return LoanCard(
              loan: loan,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanDetailsScreen(loanId: loan.id!),
                  ),
                );

                if (result == true && mounted) {
                  Provider.of<LoanProvider>(context, listen: false).loadLoans();
                }
              },
              onDelete: () => _showDeleteConfirmation(context, loan),
            );
          },
        );
      },
    );
  }
}
