import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:expense_eye/screens/edit_expense_screen.dart';

class FavoritesScreen extends StatelessWidget {
  // Constructor for the FavoritesScreen widget.
  const FavoritesScreen({super.key});

  // Function to get the appropriate emoji icon for a given expense category.
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

  // Function to display the detailed information of an expense in a bottom sheet.
  void _showExpenseDetails(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title of the bottom sheet.
            Text(
              'Expense Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Row displaying the category icon and title.
            Row(
              children: [
                // Container for the category icon background.
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    // Display the category icon.
                    child: Text(
                      _getCategoryIcon(expense.category),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Column for the expense title and category name.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expense title.
                      Text(
                        expense.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      // Expense category name (uppercase).
                      Text(
                        expense.category.name.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row displaying the expense amount.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row displaying the payment method.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                // Container for the payment method label background.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // Display the payment method name (uppercase).
                  child: Text(
                    expense.paymentMethod.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row displaying the expense date.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                // Format and display the expense date.
                Text(
                  DateFormat('MMMM dd, yyyy')
                      .format(expense.date), // Corrected date format
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            // Conditional rendering for displaying the note.
            if (expense.note != null && expense.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              // Display the expense note.
              Text(
                expense.note!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen for changes in the ExpenseProvider.
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Show a loading indicator while expenses are being fetched.
        if (expenseProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Get the list of favorite expenses from the provider.
        final favoriteExpenses = expenseProvider.favoriteExpenses;
        // Display a message if there are no favorite expenses.
        if (favoriteExpenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorite expenses yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add expenses to favorites from the expenses list',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        // Build a ListView to display the list of favorite expenses.
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: favoriteExpenses.length,
          itemBuilder: (context, index) {
            final expense = favoriteExpenses[index];
            // Display each favorite expense in a Card.
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              // Make the Card tappable to show expense details.
              child: InkWell(
                onTap: () => _showExpenseDetails(context, expense),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row containing the category icon, title, and amount.
                      Row(
                        children: [
                          // Container for the category icon.
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _getCategoryIcon(expense.category),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Expanded column for the expense title and category.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expense.category.name.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Column to align amount and payment method to the end.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Display the expense amount.
                              Text(
                                '₹${expense.amount.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              // Container for the payment method label.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // Display the payment method.
                                child: Text(
                                  expense.paymentMethod.name.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          // Popup menu for editing, unfavoriting, and duplicating.
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  // Navigate to the EditExpenseScreen.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditExpenseScreen(expense: expense),
                                    ),
                                  );
                                  break;
                                case 'unfavorite':
                                  // Toggle the favorite status of the expense.
                                  expenseProvider.toggleFavorite(expense.id);
                                  break;
                                case 'duplicate':
                                  // Duplicate the expense.
                                  expenseProvider.duplicateExpense(expense.id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              // Edit option.
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              // Unfavorite option.
                              const PopupMenuItem(
                                value: 'unfavorite',
                                child: Row(
                                  children: [
                                    Icon(Icons.favorite_outline),
                                    SizedBox(width: 8),
                                    Text('Remove from Favorites'),
                                  ],
                                ),
                              ),
                              // Duplicate option.
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy),
                                    SizedBox(width: 8),
                                    Text('Duplicate'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Conditional rendering for displaying the note in the list item.
                      if (expense.note != null && expense.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  expense.note!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Display the date of the expense in the list item.
                      Text(
                        DateFormat('MMMM dd, yyyy')
                            .format(expense.date), // Corrected date format
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
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
