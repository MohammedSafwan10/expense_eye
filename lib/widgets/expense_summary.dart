import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:expense_eye/models/expense.dart';
import 'dart:math' as math;

class ExpenseSummary extends StatefulWidget {
  const ExpenseSummary({super.key});

  @override
  State<ExpenseSummary> createState() => _ExpenseSummaryState();
}

class _ExpenseSummaryState extends State<ExpenseSummary>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final expenses = expenseProvider.expenses;
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  'No expenses to analyze',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add expenses to see your spending patterns',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        final totalExpense = expenseProvider.getTotalExpenses();
        final today = DateTime.now();
        final dailyExpense = expenseProvider.getDailyTotal(today);

        // Calculate weekly expenses
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final weeklyExpenses = expenses
            .where((expense) =>
                expense.date
                    .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                expense.date.isBefore(endOfWeek.add(const Duration(days: 1))))
            .fold(0.0, (sum, expense) => sum + expense.amount);

        // Calculate monthly expenses
        final startOfMonth = DateTime(today.year, today.month, 1);
        final endOfMonth = (today.month < 12)
            ? DateTime(today.year, today.month + 1, 0)
            : DateTime(today.year + 1, 1, 0);
        final monthlyExpenses = expenses
            .where((expense) =>
                expense.date
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                expense.date.isBefore(endOfMonth.add(const Duration(days: 1))))
            .fold(0.0, (sum, expense) => sum + expense.amount);

        // Calculate category distribution
        final categoryExpenses = expenseProvider.getExpensesByCategory();
        final sortedCategories = categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Get recent transactions
        final recentTransactions = expenses.take(5).toList();

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 16, left: 16, right: 16, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overview',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  DateFormat('MMMM yyyy').format(today),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      red: 0,
                                      green: 0,
                                      blue: 0,
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('MMM dd').format(startOfMonth)} - ${DateFormat('MMM dd').format(endOfMonth)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSummaryGrid(
                          context,
                          [
                            SummaryItem(
                              title: 'Today',
                              amount: dailyExpense,
                              icon: Icons.today,
                              color: Colors.blue,
                              animationDelay: 0.0,
                            ),
                            SummaryItem(
                              title: 'This Week',
                              amount: weeklyExpenses,
                              icon: Icons.calendar_view_week,
                              color: Colors.green,
                              animationDelay: 0.1,
                              subtitle:
                                  '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}',
                            ),
                            SummaryItem(
                              title: 'This Month',
                              amount: monthlyExpenses,
                              icon: Icons.calendar_month,
                              color: Colors.orange,
                              animationDelay: 0.2,
                              subtitle: DateFormat('MMMM').format(today),
                            ),
                            SummaryItem(
                              title: 'Total',
                              amount: totalExpense,
                              icon: Icons.account_balance_wallet,
                              color: Colors.purple,
                              animationDelay: 0.3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Categories',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedCategories.length,
                      itemBuilder: (context, index) {
                        final entry = sortedCategories[index];
                        final category = entry.key;
                        final amount = entry.value;
                        final percentage = (amount / totalExpense) * 100;

                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildCategoryCard(
                            context,
                            category,
                            amount,
                            percentage,
                            index * 0.05,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Transactions',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = recentTransactions[index];
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final delay = 0.3 + (index * 0.05);
                          final delayedAnimation =
                              Curves.easeOutQuart.transform(
                            math.max(
                                0,
                                math.min(
                                    1.0,
                                    (_animationController.value - delay) /
                                        0.5)),
                          );

                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - delayedAnimation)),
                            child: Opacity(
                              opacity: delayedAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(expense.category)
                                      .withValues(
                                    red: _getCategoryColor(expense.category)
                                        .r
                                        .toDouble(),
                                    green: _getCategoryColor(expense.category)
                                        .g
                                        .toDouble(),
                                    blue: _getCategoryColor(expense.category)
                                        .b
                                        .toDouble(),
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _getCategoryIcon(expense.category),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('MMM dd, yyyy').format(expense.date),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                        red: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .r
                                            .toDouble(),
                                        green: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .g
                                            .toDouble(),
                                        blue: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .b
                                            .toDouble(),
                                        alpha: 0.6,
                                      ),
                                ),
                              ),
                              trailing: Text(
                                currencyFormat.format(expense.amount),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: expense.amount > 1000
                                      ? Colors.red[700]
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: recentTransactions.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryGrid(BuildContext context, List<SummaryItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delayedAnimation = Curves.easeOutQuart.transform(
              math.max(
                  0,
                  math.min(
                      1.0,
                      (_animationController.value - item.animationDelay) /
                          0.5)),
            );

            return Transform.translate(
              offset: Offset(0, 20 * (1 - delayedAnimation)),
              child: Opacity(
                opacity: delayedAnimation,
                child: child,
              ),
            );
          },
          child: _buildSummaryCard(
            context,
            item.title,
            item.amount,
            item.icon,
            item.color,
            subtitle: item.subtitle,
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(
                      red: color.r.toDouble(),
                      green: color.g.toDouble(),
                      blue: color.b.toDouble(),
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                currencyFormat.format(amount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
            if (subtitle != null)
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withValues(
                                  red: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .r
                                      .toDouble(),
                                  green: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .g
                                      .toDouble(),
                                  blue: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .b
                                      .toDouble(),
                                  alpha: 0.6,
                                ),
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    ExpenseCategory category,
    double amount,
    double percentage,
    double animationDelay,
  ) {
    final color = _getCategoryColor(category);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delayedAnimation = Curves.easeOutQuart.transform(
          math.max(
              0,
              math.min(
                  1.0, (_animationController.value - animationDelay) / 0.5)),
        );

        return Transform.translate(
          offset: Offset(20 * (1 - delayedAnimation), 0),
          child: Opacity(
            opacity: delayedAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(
                      red: color.r.toDouble(),
                      green: color.g.toDouble(),
                      blue: color.b.toDouble(),
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryIcon(category),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getCategoryName(category),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                currencyFormat.format(amount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                      red: Theme.of(context).colorScheme.onSurface.r.toDouble(),
                      green:
                          Theme.of(context).colorScheme.onSurface.g.toDouble(),
                      blue:
                          Theme.of(context).colorScheme.onSurface.b.toDouble(),
                      alpha: 0.6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transportation:
        return 'Transport';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.transportation:
        return '🚗';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.entertainment:
        return '🎮';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.health:
        return '🏥';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.other:
        return '📝';
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B); // Red-ish
      case ExpenseCategory.transportation:
        return const Color(0xFF4ECDC4); // Teal
      case ExpenseCategory.utilities:
        return const Color(0xFFFFBE0B); // Yellow
      case ExpenseCategory.entertainment:
        return const Color(0xFF845EC2); // Purple
      case ExpenseCategory.shopping:
        return const Color(0xFF00C9A7); // Green-ish
      case ExpenseCategory.health:
        return const Color(0xFFFF9671); // Orange-ish
      case ExpenseCategory.education:
        return const Color(0xFF4D8076); // Dark Green
      case ExpenseCategory.other:
        return const Color(0xFFB39CD0); // Light Purple
    }
  }
}

class SummaryItem {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final double animationDelay;
  final String? subtitle;

  SummaryItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.animationDelay,
    this.subtitle,
  });
}
