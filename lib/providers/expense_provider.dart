import 'package:flutter/foundation.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:expense_eye/services/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> _favoriteExpenses = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  DateTime? _selectedDate;
  Set<String> _selectedExpenseIds = {};
  bool _isSelectionMode = false;

  List<Expense> get expenses => _filterExpenses(_expenses);
  List<Expense> get favoriteExpenses => _favoriteExpenses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ExpenseCategory? get selectedCategory => _selectedCategory;
  DateTime? get selectedDate => _selectedDate;
  Set<String> get selectedExpenseIds => _selectedExpenseIds;
  bool get isSelectionMode => _isSelectionMode;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear existing lists to prevent duplication issues
      _expenses = [];
      _favoriteExpenses = [];

      // Load expenses from database
      _expenses = await _dbHelper.getExpenses();
      _favoriteExpenses = await _dbHelper.getFavoriteExpenses();

      // Sort expenses by date (most recent first)
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _favoriteExpenses.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      // Reset to empty lists in case of error
      _expenses = [];
      _favoriteExpenses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _dbHelper.insertExpense(expense);
      // Add to local list immediately for UI responsiveness
      _expenses.add(expense);
      if (expense.isFavorite) {
        _favoriteExpenses.add(expense);
      }
      notifyListeners();
      // Then reload from database to ensure consistency
      await loadExpenses();
    } catch (e) {
      debugPrint('Error adding expense: $e');
      await loadExpenses();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> toggleFavorite(String id) async {
    final expense = _expenses.firstWhere((e) => e.id == id);
    final updatedExpense = expense.copyWith(isFavorite: !expense.isFavorite);
    await _dbHelper.updateExpense(updatedExpense);
    await loadExpenses();
  }

  Future<void> duplicateExpense(String id) async {
    final expense = _expenses.firstWhere((e) => e.id == id);
    final duplicatedExpense = Expense(
      title: '${expense.title} (Copy)',
      amount: expense.amount,
      date: DateTime.now(),
      category: expense.category,
      paymentMethod: expense.paymentMethod,
      note: expense.note,
    );
    await addExpense(duplicatedExpense);
  }

  Future<void> deleteExpense(String id) async {
    await _dbHelper.deleteExpense(id);
    await loadExpenses();
  }

  Future<void> deleteSelectedExpenses() async {
    for (final id in _selectedExpenseIds) {
      await _dbHelper.deleteExpense(id);
    }
    _selectedExpenseIds.clear();
    _isSelectionMode = false;
    await loadExpenses();
  }

  Future<void> clearAllData() async {
    await _dbHelper.clearAllData();
    await loadExpenses();
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedExpenseIds.clear();
    }
    notifyListeners();
  }

  void toggleExpenseSelection(String id) {
    if (_selectedExpenseIds.contains(id)) {
      _selectedExpenseIds.remove(id);
    } else {
      _selectedExpenseIds.add(id);
    }
    notifyListeners();
  }

  void selectAllExpenses() {
    _selectedExpenseIds = expenses.map((e) => e.id).toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedExpenseIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void setSelectedCategory(ExpenseCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedDate = null;
    notifyListeners();
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    return expenses.where((expense) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final title = expense.title.toLowerCase();
        final note = expense.note?.toLowerCase() ?? '';
        if (!title.contains(_searchQuery) && !note.contains(_searchQuery)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null && expense.category != _selectedCategory) {
        return false;
      }

      // Date filter
      if (_selectedDate != null) {
        if (expense.date.year != _selectedDate!.year ||
            expense.date.month != _selectedDate!.month ||
            expense.date.day != _selectedDate!.day) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double getTotalExpenses() {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<ExpenseCategory, double> getExpensesByCategory() {
    final categoryMap = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      categoryMap[expense.category] =
          (categoryMap[expense.category] ?? 0) + expense.amount;
    }
    return categoryMap;
  }

  List<Expense> getExpensesByDate(DateTime date) {
    return expenses
        .where((expense) =>
            expense.date.year == date.year &&
            expense.date.month == date.month &&
            expense.date.day == date.day)
        .toList();
  }

  double getDailyTotal(DateTime date) {
    return getExpensesByDate(date)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  List<MapEntry<DateTime, List<Expense>>> getGroupedExpenses() {
    final groupedMap = <DateTime, List<Expense>>{};

    for (final expense in expenses) {
      final date =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      groupedMap.putIfAbsent(date, () => []).add(expense);
    }

    return groupedMap.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
  }
}
