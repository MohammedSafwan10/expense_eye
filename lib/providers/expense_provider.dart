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

  // Pagination State
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  // Cached results for performance optimization
  List<Expense>? _cachedFilteredExpenses;
  List<MapEntry<DateTime, List<Expense>>>? _cachedGroupedExpenses;
  double? _cachedTotalExpenses;
  Map<ExpenseCategory, double>? _cachedExpensesByCategory;

  List<Expense> get expenses {
    _cachedFilteredExpenses ??= _filterExpenses(_expenses);
    return _cachedFilteredExpenses!;
  }

  List<Expense> get favoriteExpenses => _favoriteExpenses;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  ExpenseCategory? get selectedCategory => _selectedCategory;
  DateTime? get selectedDate => _selectedDate;
  Set<String> get selectedExpenseIds => _selectedExpenseIds;
  bool get isSelectionMode => _isSelectionMode;

  Future<void> loadExpenses() async {
    debugPrint('📱 [ExpenseProvider] loadExpenses() called');
    _isLoading = true;
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();

    try {
      // Clear existing lists
      _expenses = [];
      _favoriteExpenses = [];

      // Load first page of expenses from database
      debugPrint('📱 [ExpenseProvider] Fetching from database...');
      _expenses = await _dbHelper.getExpenses(limit: _pageSize, offset: 0);
      _favoriteExpenses = await _dbHelper.getFavoriteExpenses();

      debugPrint(
          '📱 [ExpenseProvider] Loaded ${_expenses.length} expenses, ${_favoriteExpenses.length} favorites');

      if (_expenses.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('❌ [ExpenseProvider] Error loading expenses: $e');
      _expenses = [];
      _favoriteExpenses = [];
    } finally {
      _isLoading = false;
      // IMPORTANT: Invalidate cache AFTER loading to ensure fresh data
      _invalidateCache();
      debugPrint(
          '📱 [ExpenseProvider] Loading complete. isLoading=$_isLoading, count=${_expenses.length}');
      notifyListeners();
    }
  }

  Future<void> fetchMoreExpenses() async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    _invalidateCache();
    notifyListeners();

    try {
      _currentPage++;
      final moreExpenses = await _dbHelper.getExpenses(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (moreExpenses.isEmpty || moreExpenses.length < _pageSize) {
        _hasMore = false;
      }

      _expenses.addAll(moreExpenses);
    } catch (e) {
      debugPrint('Error fetching more expenses: $e');
      _hasMore = false;
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _dbHelper.insertExpense(expense);
      // Insert at the beginning of the list (since it's sorted by date DESC)
      _expenses.insert(0, expense);
      if (expense.isFavorite) {
        _favoriteExpenses.insert(0, expense);
      }
      _invalidateCache();
      notifyListeners();
      // No need to reload everything from DB after a single add, local state is updated
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
    await _dbHelper.deleteExpenses(_selectedExpenseIds.toList());
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
    _invalidateCache();
    notifyListeners();
  }

  void toggleExpenseSelection(String id) {
    if (_selectedExpenseIds.contains(id)) {
      _selectedExpenseIds.remove(id);
    } else {
      _selectedExpenseIds.add(id);
    }
    _invalidateCache();
    notifyListeners();
  }

  void selectAllExpenses() {
    _selectedExpenseIds = expenses.map((e) => e.id).toSet();
    _invalidateCache();
    notifyListeners();
  }

  void clearSelection() {
    _selectedExpenseIds.clear();
    _isSelectionMode = false;
    _invalidateCache();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    if (_searchQuery != lowerQuery) {
      _searchQuery = lowerQuery;
      _invalidateCache();
      notifyListeners();
    }
  }

  void _invalidateCache() {
    debugPrint('📱 [ExpenseProvider] Cache invalidated');
    _cachedFilteredExpenses = null;
    _cachedGroupedExpenses = null;
    _cachedTotalExpenses = null;
    _cachedExpensesByCategory = null;
  }

  void setSelectedCategory(ExpenseCategory? category) {
    _selectedCategory = category;
    _invalidateCache();
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    _invalidateCache();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedDate = null;
    _invalidateCache();
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
    _cachedTotalExpenses ??=
        expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    return _cachedTotalExpenses!;
  }

  Map<ExpenseCategory, double> getExpensesByCategory() {
    if (_cachedExpensesByCategory == null) {
      final categoryMap = <ExpenseCategory, double>{};
      for (final expense in expenses) {
        categoryMap[expense.category] =
            (categoryMap[expense.category] ?? 0) + expense.amount;
      }
      _cachedExpensesByCategory = categoryMap;
    }
    return _cachedExpensesByCategory!;
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
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  List<MapEntry<DateTime, List<Expense>>> getGroupedExpenses() {
    if (_cachedGroupedExpenses == null) {
      final groupedMap = <DateTime, List<Expense>>{};

      for (final expense in expenses) {
        final date =
            DateTime(expense.date.year, expense.date.month, expense.date.day);
        groupedMap.putIfAbsent(date, () => []).add(expense);
      }

      _cachedGroupedExpenses = groupedMap.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
    }
    return _cachedGroupedExpenses!;
  }
}
