import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/loan_provider.dart';
import '../../models/loan_model.dart';
import '../../utils/app_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common_widgets.dart';
import 'add_loan_screen.dart';
import 'loan_details_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String _filter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Load loans when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      loanProvider.loadLoans();
    });

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                backgroundColor: theme.scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDarkMode
                              ? const Color(0xFF1E3A5F)
                              : const Color(0xFF2196F3).withOpacity(0.8),
                          isDarkMode
                              ? const Color(0xFF0D2137)
                              : const Color(0xFF1565C0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative elements
                        Positioned(
                          right: -20,
                          top: -20,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        // App Bar content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.monetization_on,
                                  color: theme.colorScheme.primary,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'LoanBuddy',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Manage your loans efficiently',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_outlined,
                                      color: Colors.white),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('No new notifications')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: IconButton(
                                  icon: const Icon(Icons.settings,
                                      color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SettingsScreen()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlePadding: EdgeInsets.zero,
                ),
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: () async {
              final loanProvider =
                  Provider.of<LoanProvider>(context, listen: false);
              await loanProvider.loadLoans();
            },
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildStatCards(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSearchAndFilters(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Constants.defaultPadding,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Your Loans',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Consumer<LoanProvider>(
                            builder: (context, provider, _) {
                              return Text(
                                '${provider.loans.length} total',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 80), // For FAB
                    sliver: Consumer<LoanProvider>(
                      builder: (context, loanProvider, _) {
                        if (loanProvider.isLoading) {
                          return SliverToBoxAdapter(
                            child: Container(
                              height: MediaQuery.of(context).size.height -
                                  300, // Adjust this value as needed
                              alignment: Alignment.center,
                              child: const CustomLoadingIndicator(
                                  useShimmer: true),
                            ),
                          );
                        }

                        final filteredLoans = _searchQuery.isEmpty
                            ? loanProvider.loans
                            : loanProvider.searchLoans(_searchQuery);

                        if (filteredLoans.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Container(
                              height: MediaQuery.of(context).size.height -
                                  300, // Adjust this value as needed
                              alignment: Alignment.center,
                              child: EmptyStateWidget(
                                message: _searchQuery.isNotEmpty
                                    ? 'No loans match your search'
                                    : 'No loans yet. Add your first loan!',
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AddLoanScreen()),
                                  );

                                  if (result == true && mounted) {
                                    Provider.of<LoanProvider>(context,
                                            listen: false)
                                        .loadLoans();
                                  }
                                },
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final loan = filteredLoans[index];
                              return LoanCard(
                                loan: loan,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LoanDetailsScreen(loanId: loan.id!),
                                    ),
                                  );

                                  if (result == true && mounted) {
                                    Provider.of<LoanProvider>(context,
                                            listen: false)
                                        .loadLoans();
                                  }
                                },
                                onDelete: () =>
                                    _showDeleteConfirmation(context, loan),
                              );
                            },
                            childCount: filteredLoans.length,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          elevation: 8,
          height: 72,
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          indicatorColor: isDarkMode
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.primaryContainer.withOpacity(0.3),
          shadowColor: theme.shadowColor,
          surfaceTintColor: Colors.transparent,
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
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              selectedIcon:
                  const Icon(Icons.home, color: AppTheme.primaryColor),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.bar_chart_outlined,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              selectedIcon:
                  const Icon(Icons.bar_chart, color: AppTheme.primaryColor),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              selectedIcon:
                  const Icon(Icons.person, color: AppTheme.primaryColor),
              label: 'Profile',
            ),
          ],
        ),
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
        elevation: 4,
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
                child: Row(
                  children: [
                    Text(
                      'Your Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.insights,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Financial Summary',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
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
      margin: const EdgeInsets.symmetric(
        horizontal: Constants.defaultPadding,
        vertical: Constants.defaultPadding / 2,
      ),
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
}
