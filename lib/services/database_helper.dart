import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:expense_eye/models/expense.dart';

class DatabaseHelper {
  // Singleton instance of the DatabaseHelper.
  static DatabaseHelper? _instance;
  // The database instance.
  static Database? _database;

  // Private constructor to enforce singleton pattern.
  DatabaseHelper._internal();

  // Factory constructor to return the singleton instance.
  factory DatabaseHelper() {
    return _instance ??= DatabaseHelper._internal();
  }

  // Getter for the database instance, initializes it if it's null.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initializes the database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_eye.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            category INTEGER NOT NULL,
            paymentMethod INTEGER NOT NULL,
            note TEXT,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE expenses ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  // Inserts a new expense into the database.
  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace if ID already exists.
    );
  }

  // Updates an existing expense in the database.
  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Retrieves all expenses from the database, ordered by date descending.
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  // Retrieves all favorite expenses from the database, ordered by date descending.
  Future<List<Expense>> getFavoriteExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'isFavorite = ?',
      whereArgs: [1], // 1 represents true for isFavorite.
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  // Toggles the favorite status of an expense in the database.
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'expenses',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Deletes an expense from the database based on its ID.
  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Deletes all data from the expenses table. Use with caution!
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
  }
}
