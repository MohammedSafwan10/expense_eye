import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:expense_eye/screens/edit_expense_screen.dart';
import 'package:expense_eye/services/export_service.dart';
import 'package:expense_eye/services/split_service.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final bool _isSearching = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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

    _animationController.reset();
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _showExpenseDetails(BuildContext context, Expense expense) {
    final categoryColor = _getCategoryColor(expense.category);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0.1,
              ),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(
                    red: Colors.grey.r.toDouble(),
                    green: Colors.grey.g.toDouble(),
                    blue: Colors.grey.b.toDouble(),
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Expense Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(
                      red: categoryColor.r.toDouble(),
                      green: categoryColor.g.toDouble(),
                      blue: categoryColor.b.toDouble(),
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _getCategoryIcon(expense.category),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(
                            red: categoryColor.r.toDouble(),
                            green: categoryColor.g.toDouble(),
                            blue: categoryColor.b.toDouble(),
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.category.name.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: categoryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(expense.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(expense.amount),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      expense.paymentMethod.name.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  ],
                ),
              ],
            ),
            if (expense.note != null && expense.note!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(
                          red: Theme.of(context)
                              .colorScheme
                              .outline
                              .r
                              .toDouble(),
                          green: Theme.of(context)
                              .colorScheme
                              .outline
                              .g
                              .toDouble(),
                          blue: Theme.of(context)
                              .colorScheme
                              .outline
                              .b
                              .toDouble(),
                          alpha: 0.1,
                        ),
                  ),
                ),
                child: Text(
                  expense.note!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8.0,
              runSpacing: 16.0,
              children: [
                _buildActionButton(
                  context: context,
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditExpenseScreen(expense: expense),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.copy_outlined,
                  label: 'Duplicate',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<ExpenseProvider>(context, listen: false)
                        .duplicateExpense(expense.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense duplicated'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.share_outlined,
                  label: 'Export',
                  onTap: () {
                    // Store the context before popping dialog
                    final currentContext = context;
                    Navigator.pop(context);

                    // Move async operation to a separate method
                    _exportExpense(expense, currentContext);
                  },
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.people_outlined,
                  label: 'Split',
                  onTap: () {
                    Navigator.pop(context);
                    SplitService.showSplitExpenseDialog(context, expense);
                  },
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, expense);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<ExpenseProvider>(context, listen: false)
                  .deleteExpense(expense.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExpense(Expense expense, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await ExportService.exportAsPDF(expense);
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Expense exported'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final expenses = expenseProvider.expenses;
        final filteredExpenses = expenseProvider.selectedCategory != null ||
                expenseProvider.selectedDate != null
            ? expenses.where((expense) {
                bool matchesCategory =
                    expenseProvider.selectedCategory == null ||
                        expense.category == expenseProvider.selectedCategory;
                bool matchesDate = expenseProvider.selectedDate == null ||
                    (expense.date.year == expenseProvider.selectedDate!.year &&
                        expense.date.month ==
                            expenseProvider.selectedDate!.month &&
                        expense.date.day == expenseProvider.selectedDate!.day);
                return matchesCategory && matchesDate;
              }).toList()
            : expenses;

        final searchResults = _isSearching && _searchQuery.isNotEmpty
            ? filteredExpenses
                .where((expense) =>
                    expense.title
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    expense.category.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList()
            : filteredExpenses;

        final groupedExpenses = <DateTime, List<Expense>>{};
        for (var expense in searchResults) {
          final dateOnly = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          if (!groupedExpenses.containsKey(dateOnly)) {
            groupedExpenses[dateOnly] = [];
          }
          groupedExpenses[dateOnly]!.add(expense);
        }

        final sortedDates = groupedExpenses.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        if (filteredExpenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  'No expenses found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  expenseProvider.selectedCategory != null ||
                          expenseProvider.selectedDate != null
                      ? 'Try changing your filters'
                      : 'Add expenses to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                if (expenseProvider.selectedCategory != null ||
                    expenseProvider.selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filters'),
                      onPressed: () {
                        expenseProvider.clearFilters();
                      },
                    ),
                  ),
              ],
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isSearching ? 60 : 0,
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search expenses...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          )
                        : null,
                  ),
                ),
                if (expenseProvider.selectedCategory != null ||
                    expenseProvider.selectedDate != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(
                              red: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .r
                                  .toDouble(),
                              green: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .g
                                  .toDouble(),
                              blue: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .b
                                  .toDouble(),
                              alpha: 0.5,
                            ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filters: ${expenseProvider.selectedCategory != null ? expenseProvider.selectedCategory!.name : ''}${expenseProvider.selectedCategory != null && expenseProvider.selectedDate != null ? ' - ' : ''}${expenseProvider.selectedDate != null ? DateFormat('MMM dd, yyyy').format(expenseProvider.selectedDate!) : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: expenseProvider.clearFilters,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 0,
                        right: 0,
                        top: 24,
                        bottom: MediaQuery.of(context).padding.bottom + 80,
                      ),
                      itemCount: sortedDates.length * 2,
                      itemBuilder: (context, index) {
                        if (index % 2 == 0) {
                          final dateIndex = index ~/ 2;
                          if (dateIndex >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }
                          return _buildGroupHeader(sortedDates[dateIndex]);
                        } else {
                          final dateIndex = index ~/ 2;
                          if (dateIndex >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }

                          final date = sortedDates[dateIndex];
                          final expensesForDate = groupedExpenses[date]!;

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: expensesForDate.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, expenseIndex) {
                              final expense = expensesForDate[expenseIndex];
                              final isSelected = expenseProvider
                                  .selectedExpenseIds
                                  .contains(expense.id);

                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 80,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Dismissible(
                                    key: Key(expense.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.red[700],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Expense'),
                                          content: const Text(
                                              'Are you sure you want to delete this expense?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (direction) {
                                      expenseProvider.deleteExpense(expense.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              const Text('Expense deleted'),
                                          action: SnackBarAction(
                                            label: 'UNDO',
                                            onPressed: () {
                                              expenseProvider
                                                  .addExpense(expense);
                                            },
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: isSelected
                                            ? BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 2,
                                              )
                                            : BorderSide.none,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          if (expenseProvider.isSelectionMode) {
                                            expenseProvider
                                                .toggleExpenseSelection(
                                                    expense.id);
                                          } else {
                                            _showExpenseDetails(
                                                context, expense);
                                          }
                                        },
                                        onLongPress: () {
                                          if (!expenseProvider
                                              .isSelectionMode) {
                                            expenseProvider
                                                .toggleSelectionMode();
                                          }
                                          expenseProvider
                                              .toggleExpenseSelection(
                                                  expense.id);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              if (expenseProvider
                                                  .isSelectionMode)
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  margin: const EdgeInsets.only(
                                                      right: 16),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .outline,
                                                      width: 2,
                                                    ),
                                                    color: isSelected
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                        : Colors.transparent,
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                )
                                              else
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: _getCategoryColor(
                                                            expense.category)
                                                        .withValues(
                                                      red: _getCategoryColor(
                                                              expense.category)
                                                          .r
                                                          .toDouble(),
                                                      green: _getCategoryColor(
                                                              expense.category)
                                                          .g
                                                          .toDouble(),
                                                      blue: _getCategoryColor(
                                                              expense.category)
                                                          .b
                                                          .toDouble(),
                                                      alpha: 0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      _getCategoryIcon(
                                                          expense.category),
                                                      style: const TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      expense.title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _getCategoryColor(
                                                                    expense
                                                                        .category)
                                                                .withValues(
                                                              red: _getCategoryColor(
                                                                      expense
                                                                          .category)
                                                                  .r
                                                                  .toDouble(),
                                                              green: _getCategoryColor(
                                                                      expense
                                                                          .category)
                                                                  .g
                                                                  .toDouble(),
                                                              blue: _getCategoryColor(
                                                                      expense
                                                                          .category)
                                                                  .b
                                                                  .toDouble(),
                                                              alpha: 0.1,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: Text(
                                                            expense
                                                                .category.name,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: _getCategoryColor(
                                                                  expense
                                                                      .category),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          DateFormat('h:mm a')
                                                              .format(
                                                                  expense.date),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  red: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .r
                                                                      .toDouble(),
                                                                  green: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .g
                                                                      .toDouble(),
                                                                  blue: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .b
                                                                      .toDouble(),
                                                                  alpha: 0.6,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8),
                                                child: Text(
                                                  currencyFormat
                                                      .format(expense.amount),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: expense.amount > 1000
                                                        ? Colors.red[700]
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    String headerText;
    if (dateOnly == today) {
      headerText = 'Today';
    } else if (dateOnly == yesterday) {
      headerText = 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      headerText = DateFormat('EEEE').format(date);
    } else if (dateOnly.year == now.year) {
      headerText = DateFormat('MMM d').format(date);
    } else {
      headerText = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(
                    red: Theme.of(context).colorScheme.primary.r.toDouble(),
                    green: Theme.of(context).colorScheme.primary.g.toDouble(),
                    blue: Theme.of(context).colorScheme.primary.b.toDouble(),
                    alpha: 0.1,
                  ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              headerText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    red: Theme.of(context).colorScheme.onSurface.r.toDouble(),
                    green: Theme.of(context).colorScheme.onSurface.g.toDouble(),
                    blue: Theme.of(context).colorScheme.onSurface.b.toDouble(),
                    alpha: 0.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
