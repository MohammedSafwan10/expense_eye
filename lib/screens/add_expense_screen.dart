import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  // Constructor for the AddExpenseScreen widget. Takes no arguments.
  const AddExpenseScreen({super.key});

  // Creates the mutable state for this widget.
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

// The state class for the AddExpenseScreen widget.
class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Global key used to uniquely identify the Form widget and allows validation.
  final _formKey = GlobalKey<FormState>();
  // Controllers for the text input fields.
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  // Stores the currently selected date, initialized to the current date.
  DateTime _selectedDate = DateTime.now();
  // Stores the currently selected expense category, initialized to 'food'.
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  // Stores the currently selected payment method, initialized to 'cash'.
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  // Called when the state object is removed permanently from the widget tree.
  // It's good practice to dispose of controllers to release resources.
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Asynchronously shows a date picker dialog to the user.
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Earliest selectable date.
      lastDate: DateTime.now(), // Latest selectable date.
    );
    // If a date was picked (not null), update the selected date in the state.
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Validates the form and submits the new expense data.
  void _submitForm() {
    // Validate the form using the _formKey.
    if (_formKey.currentState!.validate()) {
      // Try to parse the entered amount as a double.
      final amount = double.tryParse(_amountController.text);
      // Check if the parsed amount is null or not positive.
      if (amount == null || amount <= 0) {
        // Show a snackbar with an error message if the amount is invalid.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid amount'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return; // Stop the submission process.
      }

      // Create a new Expense object with the collected data.
      final expense = Expense(
        title: _titleController.text.trim(), // Trim whitespace from the title.
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        note: _noteController.text
                .trim()
                .isEmpty // If note is empty, set it to null.
            ? null
            : _noteController.text.trim(), // Trim whitespace from the note.
      );

      // Show a loading dialog to indicate that the expense is being added.
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent dismissing the dialog by tapping outside.
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Access the ExpenseProvider using Provider and call the addExpense method.
      Provider.of<ExpenseProvider>(context, listen: false)
          .addExpense(expense)
          .then((_) {
        // This callback is executed after the expense is successfully added.
        if (!mounted) return; // Check if the widget is still in the tree.
        Navigator.pop(context); // Dismiss the loading dialog.
        Navigator.pop(context); // Go back to the previous screen.
        // Show a success snackbar.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }).catchError((error) {
        // This callback is executed if an error occurs during expense addition.
        if (!mounted) return; // Check if the widget is still in the tree.
        Navigator.pop(context); // Dismiss the loading dialog.
        // Show an error snackbar.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding expense: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  // Builds the UI for the AddExpenseScreen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, // Assign the global key to the Form widget.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text field for entering the expense title.
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                // Validator for the title field.
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Text field for entering the expense amount.
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                // Validator for the amount field.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Card and ListTile to display and select the date.
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy')
                        .format(_selectedDate), // Format the selected date.
                  ),
                  onTap: _selectDate, // Call _selectDate when tapped.
                ),
              ),
              const SizedBox(height: 16),
              // Dropdown button for selecting the expense category.
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Dropdown button for selecting the payment method.
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Text field for entering an optional note.
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              // Filled button to submit the form.
              FilledButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
