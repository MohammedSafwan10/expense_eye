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
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  // Called when a bottom navigation item is tapped, updates the selected index.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Reset and restart page transition animation
    _pageTransitionController.reset();
    _pageTransitionController.forward();

    // Ensure expense data is refreshed when changing tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
    });
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
          extendBodyBehindAppBar: true,
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
              child: expenseProvider.isSelectionMode
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
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Will be implemented in future
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Search feature coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: IndexedStack(
                  key: ValueKey<int>(_selectedIndex),
                  index: _selectedIndex,
                  children: [
                    AnimatedBuilder(
                      animation: _pageTransitionController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _pageTransitionController,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _pageTransitionController,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: const ExpenseList(),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pageTransitionController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _pageTransitionController,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _pageTransitionController,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: const ExpenseChart(),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pageTransitionController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _pageTransitionController,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _pageTransitionController,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: const ExpenseSummary(),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pageTransitionController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _pageTransitionController,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _pageTransitionController,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: const FavoritesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: !expenseProvider.isSelectionMode
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
          bottomNavigationBar: NavigationBar(
            elevation: 8,
            backgroundColor:
                isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: const Icon(Icons.pie_chart_outline),
                selectedIcon: const Icon(Icons.pie_chart),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: const Icon(Icons.analytics_outlined),
                selectedIcon: const Icon(Icons.analytics),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_outline),
                selectedIcon: const Icon(Icons.favorite),
                label: 'Favorites',
              ),
            ],
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
                          selectedColor:
                              Theme.of(context).colorScheme.primary.withValues(
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
                          checkmarkColor: Theme.of(context).colorScheme.primary,
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
                          initialDate: provider.selectedDate ?? DateTime.now(),
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
            );
          },
        );
      },
    );
  }
}
