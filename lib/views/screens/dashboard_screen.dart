import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/loan_provider.dart';
import '../../controllers/settings_provider.dart';
import '../../utils/app_utils.dart';
import '../widgets/common_widgets.dart';
import '../../models/loan_model.dart';
import 'add_loan_screen.dart';
import 'loan_details_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
        content: 'Are you sure you want to delete this loan? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () {
          if (loan.id != null) {
            final loanProvider = Provider.of<LoanProvider>(context, listen: false);
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
        return Container(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Outstanding',
                        Formatters.currencyFormat.format(loanProvider.totalOutstandingAmount),
                        Colors.blue,
                        Icons.account_balance,
                      ),
                      _buildStatItem(
                        'Total Loans',
                        '${loanProvider.loans.length}',
                        Colors.green,
                        Icons.people,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Active',
                        '${loanProvider.loans.where((loan) => loan.status == LoanStatus.active).length}',
                        Colors.orange,
                        Icons.hourglass_bottom,
                      ),
                      _buildStatItem(
                        'Overdue',
                        '${loanProvider.loans.where((loan) => loan.status == LoanStatus.active && loan.isOverdue).length}',
                        Colors.red,
                        Icons.warning_amber_outlined,
                      ),
                      _buildStatItem(
                        'Completed',
                        '${loanProvider.loans.where((loan) => loan.status == LoanStatus.completed).length}',
                        Colors.green,
                        Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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