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

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('LoanBuddy'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notification functionality could be added here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // This could be expanded to handle navigation between different screens
          if (index == 1) {
            // Reports screen (placeholder)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reports feature coming soon')),
            );
            setState(() => _selectedIndex = 0);
          } else if (index == 2) {
            // Profile screen (placeholder for settings)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            setState(() => _selectedIndex = 0);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        label: const Text('Add Loan'),
        icon: const Icon(Icons.add),
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
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: Constants.animationDuration,
      padding: const EdgeInsets.fromLTRB(
        Constants.defaultPadding,
        Constants.defaultPadding / 2,
        Constants.defaultPadding,
        Constants.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by borrower name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchLoans('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            onChanged: _searchLoans,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Filter by status:',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', theme),
                _buildFilterChip('Active', 'active', theme),
                _buildFilterChip('Completed', 'completed', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _filter == value;
    final chipColor = () {
      if (value == 'active') return const Color(0xFFFFA726);
      if (value == 'completed') return const Color(0xFF43A047);
      return theme.colorScheme.primary;
    }();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: AnimatedContainer(
        duration: Constants.animationDuration,
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.brightness == Brightness.light
                      ? Colors.white
                      : Colors.white
                  : theme.colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _onFilterChanged(value);
            }
          },
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          selectedColor: chipColor,
          checkmarkColor: Colors.white,
          showCheckmark: true,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoansList() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, _) {
        if (loanProvider.isLoading) {
          return const CustomLoadingIndicator(useShimmer: true);
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
