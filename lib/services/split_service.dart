import 'package:flutter/material.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class SplitService {
  static Future<void> showSplitExpenseDialog(
      BuildContext context, Expense expense) async {
    final TextEditingController peopleController =
        TextEditingController(text: '2');
    final TextEditingController namesController = TextEditingController();
    bool splitEqually = true;
    List<double> customAmounts = [];
    List<String> names = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final numberOfPeople = int.tryParse(peopleController.text) ?? 2;
          final amountPerPerson = expense.amount / numberOfPeople;

          if (customAmounts.length != numberOfPeople) {
            customAmounts = List.filled(numberOfPeople, amountPerPerson);
          }

          return AlertDialog(
            title: const Text('Split Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount: ₹${expense.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: peopleController,
                          decoration: const InputDecoration(
                            labelText: 'Number of People',
                            prefixIcon: Icon(Icons.group),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: namesController,
                    decoration: const InputDecoration(
                      labelText: 'Names (comma separated)',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      names = value
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Split Equally'),
                    value: splitEqually,
                    onChanged: (value) {
                      setState(() {
                        splitEqually = value;
                      });
                    },
                  ),
                  if (!splitEqually) ...[
                    const SizedBox(height: 16),
                    const Text('Custom Split:'),
                    const SizedBox(height: 8),
                    ...List.generate(
                      numberOfPeople,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Person ${index + 1}',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            final amount = double.tryParse(value) ?? 0;
                            setState(() {
                              customAmounts[index] = amount;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final splits = _calculateSplits(
                    expense,
                    numberOfPeople: int.parse(peopleController.text),
                    names: names,
                    splitEqually: splitEqually,
                    customAmounts: customAmounts,
                  );
                  Navigator.pop(context);
                  _shareSplitDetails(expense, splits);
                },
                child: const Text('Share Split'),
              ),
            ],
          );
        },
      ),
    );
  }

  static List<Map<String, dynamic>> _calculateSplits(
    Expense expense, {
    required int numberOfPeople,
    required List<String> names,
    required bool splitEqually,
    required List<double> customAmounts,
  }) {
    final List<Map<String, dynamic>> splits = [];
    final amountPerPerson = expense.amount / numberOfPeople;

    for (var i = 0; i < numberOfPeople; i++) {
      final name = i < names.length ? names[i] : 'Person ${i + 1}';
      splits.add({
        'name': name,
        'amount': splitEqually ? amountPerPerson : customAmounts[i],
      });
    }

    return splits;
  }

  static Future<void> _shareSplitDetails(
    Expense expense,
    List<Map<String, dynamic>> splits,
  ) async {
    final StringBuffer details = StringBuffer();
    details.writeln('Split Expense Details:');
    details.writeln('Title: ${expense.title}');
    details.writeln('Total Amount: ₹${expense.amount.toStringAsFixed(2)}');
    details
        .writeln('Date: ${DateFormat('MMMM dd, yyyy').format(expense.date)}');
    details.writeln('\nSplit Details:');

    for (final split in splits) {
      details
          .writeln('${split['name']}: ₹${split['amount'].toStringAsFixed(2)}');
    }

    await Share.share(details.toString());
  }
}
