import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:intl/intl.dart';

class EditExpenseScreen extends StatefulWidget {
  // The expense object to be edited.
  final Expense expense;

  // Constructor for the EditExpenseScreen widget, requires an Expense object.
  const EditExpenseScreen({super.key, required this.expense});

  // Creates the mutable state for this widget.
  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

// The state class for the EditExpenseScreen widget.
class _EditExpenseScreenState extends State<EditExpenseScreen> {
  // Global key used to uniquely identify the Form widget and allows validation.
  final _formKey = GlobalKey<FormState>();
  // Controllers for the text input fields, initialized in initState.
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  // Stores the currently selected date, initialized in initState.
  late DateTime _selectedDate;
  // Stores the currently selected expense category, initialized in initState.
  late ExpenseCategory _selectedCategory;
  // Stores the currently selected payment method, initialized in initState.
  late PaymentMethod _selectedPaymentMethod;
  // Whether this expense is marked as favorite.
  late bool _isFavorite;

  // Called only once when the widget is created, before the build method is called.
  // Used here to initialize the controllers and selected values with the existing expense data.
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController =
        TextEditingController(text: widget.expense.amount.toString());
    _noteController = TextEditingController(text: widget.expense.note ?? '');
    _selectedDate = widget.expense.date;
    _selectedCategory = widget.expense.category;
    _selectedPaymentMethod = widget.expense.paymentMethod;
    _isFavorite = widget.expense.isFavorite;
  }

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

  // Validates the form and submits the updated expense data.
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

      // Create a new Expense object with the updated data, using copyWith.
      final updatedExpense = widget.expense.copyWith(
        title: _titleController.text.trim(), // Trim whitespace from the title.
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        isFavorite: _isFavorite,
        note: _noteController.text
                .trim()
                .isEmpty // If note is empty, set it to null.
            ? null
            : _noteController.text.trim(), // Trim whitespace from the note.
      );

      // Show a loading dialog to indicate that the expense is being updated.
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent dismissing the dialog by tapping outside.
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Access the ExpenseProvider using Provider and call the updateExpense method.
      Provider.of<ExpenseProvider>(context, listen: false)
          .updateExpense(updatedExpense)
          .then((_) {
        // This callback is executed after the expense is successfully updated.
        if (!mounted) return; // Check if the widget is still in the tree.
        Navigator.pop(context); // Dismiss the loading dialog.
        Navigator.pop(context); // Go back to the previous screen.
        // Show a success snackbar.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  // Builds the UI for the EditExpenseScreen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey, // Assign the global key to the Form widget.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Text field for editing the expense title.
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
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
                // Text field for editing the expense amount.
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
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
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // InkWell with InputDecorator to display and select the date.
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('MMMM dd,<ctrl3348>')
                          .format(_selectedDate), // Format the selected date.
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // InputDecorator with DropdownButton for selecting the expense category.
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  child: DropdownButton<ExpenseCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ExpenseCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // InputDecorator with DropdownButton for selecting the payment method.
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  child: DropdownButton<PaymentMethod>(
                    value: _selectedPaymentMethod,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: PaymentMethod.values.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Text field for editing the optional note.
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                // Switch for marking the expense as a favorite.
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: const Text('Mark as Favorite'),
                    secondary: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : null,
                    ),
                    value: _isFavorite,
                    onChanged: (value) {
                      setState(() {
                        _isFavorite = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Filled button to submit the updated form.
                FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
