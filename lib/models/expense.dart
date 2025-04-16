import 'package:uuid/uuid.dart';

enum ExpenseCategory {
  food,
  transportation,
  utilities,
  entertainment,
  shopping,
  health,
  education,
  other
}

enum PaymentMethod { cash, creditCard, debitCard, upi, other }

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final String? note;
  final bool isFavorite;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
    this.note,
    this.isFavorite = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.index,
      'paymentMethod': paymentMethod.index,
      'note': note,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: ExpenseCategory.values[map['category']],
      paymentMethod: PaymentMethod.values[map['paymentMethod']],
      note: map['note'],
      isFavorite: map['isFavorite'] == 1,
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
    String? note,
    bool? isFavorite,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
