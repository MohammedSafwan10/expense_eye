import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:expense_eye/screens/add_expense_screen.dart';
import 'package:expense_eye/widgets/expense_list.dart';
import 'package:expense_eye/widgets/expense_summary.dart';
import 'package:expense_eye/widgets/expense_chart.dart';
import 'package:expense_eye/screens/settings_screen.dart';
import 'package:expense_eye/screens/favorites_screen.dart';
import 'package:expense_eye/models/expense.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  // Constructor for the HomeScreen widget. Takes no arguments.
  const HomeScreen({super.key});

  // Creates the mutable state for this widget.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// The state class for the HomeScreen widget.
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Index of the currently selected tab in the bottom navigation bar.
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _fabAnimationController;
  late final AnimationController _pageTransitionController;
  late final Animation<double> _fabScaleAnimation;
  late final Animation<double> _fabRotateAnimation;

  final List<String> _screenTitles = [
    'Dashboard',
    'Analytics',
    'Overview',
    'Favorites'
  ];

  // Called only once when the widget is created, before the build method is called.
  @override
  void initState() {
    super.initState();

    // Animation controllers for various animations
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Animations for the FAB
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fabRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animations after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('📱 [HomeScreen] Initial load triggered');
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pageTransitionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Called when a bottom navigation item is tapped, updates the selected index.
  void _onItemTapped(int index) {
    debugPrint('📱 [HomeScreen] Tab switched to index: $index');
    setState(() {
      _selectedIndex = index;
    });

    // Reload expenses when returning to Dashboard for real-time updates
    if (index == 0) {
      debugPrint('📱 [HomeScreen] Dashboard selected - reloading expenses');
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
    }

    // Reset and restart page transition animation
    _pageTransitionController.reset();
    _pageTransitionController.forward();
  }

  // Builds the UI for the HomeScreen.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use Consumer to listen for changes in the ExpenseProvider.
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        return Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.colorScheme.primary,
            surfaceTintColor: Colors.transparent,
            leading: expenseProvider.isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    // Clear the selection when the close icon is pressed.
                    onPressed: expenseProvider.clearSelection,
                  )
                : IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    // Navigate to the SettingsScreen when the settings icon is pressed.
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SettingsScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;

                            var tween = Tween(begin: begin, end: end).chain(
                              CurveTween(curve: curve),
                            );

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6)),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        expenseProvider.setSearchQuery(value);
                      },
                    )
                  : expenseProvider.isSelectionMode
                      ? Text(
                          '${expenseProvider.selectedExpenseIds.length} Selected',
                          key: const ValueKey('selection-title'),
                        )
                      : Column(
                          key: const ValueKey('screen-title'),
                          children: [
                            Text(
                              _screenTitles[_selectedIndex],
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedIndex == 0)
                              Text(
                                '${expenseProvider.expenses.length} expenses',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
            ),
            actions: [
              // Show these actions only when in selection mode.
              if (expenseProvider.isSelectionMode) ...[
                // Select all expenses.
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: expenseProvider.selectAllExpenses,
                ),
                // Delete selected expenses.
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    // Show a confirmation dialog before deleting.
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Selected'),
                        content: Text(
                          'Are you sure you want to delete ${expenseProvider.selectedExpenseIds.length} expenses?',
                        ),
                        actions: [
                          // Cancel button.
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          // Delete button.
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog.
                              expenseProvider.deleteSelectedExpenses();
                              // Show a snackbar indicating successful deletion.
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Expenses deleted'),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'DISMISS',
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                // Search icon that will be added later
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        expenseProvider.setSearchQuery('');
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterBottomSheet(context, expenseProvider);
                  },
                ),
              ],
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(20),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: true,
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                ExpenseList(),
                ExpenseChart(),
                ExpenseSummary(),
                FavoritesScreen(),
              ],
            ),
          ),
          floatingActionButton:
              !expenseProvider.isSelectionMode && _selectedIndex == 0
                  ? ScaleTransition(
                      scale: _fabScaleAnimation,
                      child: RotationTransition(
                        turns: _fabRotateAnimation,
                        child: FloatingActionButton(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const AddExpenseScreen(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                      ),
                    )
                  : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SafeArea(
            bottom: true,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: NavigationBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                height: 80,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                indicatorColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon:
                        Icon(Icons.dashboard, color: theme.colorScheme.primary),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.pie_chart_outline),
                    selectedIcon:
                        Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                    label: 'Analytics',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.analytics_outlined),
                    selectedIcon:
                        Icon(Icons.analytics, color: theme.colorScheme.primary),
                    label: 'Overview',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.favorite_outline),
                    selectedIcon:
                        Icon(Icons.favorite, color: theme.colorScheme.primary),
                    label: 'Favorites',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Expenses',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              provider.clearFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ExpenseCategory.values.map((category) {
                          final isSelected =
                              provider.selectedCategory == category;
                          return FilterChip(
                            selected: isSelected,
                            label: Text(category.name),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  provider.setSelectedCategory(category);
                                } else {
                                  provider.setSelectedCategory(null);
                                }
                              });
                            },
                            backgroundColor:
                                Theme.of(context).chipTheme.backgroundColor,
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(
                                  red: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .r
                                      .toDouble(),
                                  green: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .g
                                      .toDouble(),
                                  blue: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .b
                                      .toDouble(),
                                  alpha: 0.15,
                                ),
                            checkmarkColor:
                                Theme.of(context).colorScheme.primary,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          provider.selectedDate != null
                              ? '${provider.selectedDate!.day}/${provider.selectedDate!.month}/${provider.selectedDate!.year}'
                              : 'Select Date',
                        ),
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate:
                                provider.selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              provider.setSelectedDate(selectedDate);
                            });
                          }
                        },
                      ),
                      if (provider.selectedDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              provider.setSelectedDate(null);
                            });
                          },
                          child: const Text('Clear Date'),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Apply Filters'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
