// lib/services/finance_database_helper.dart
//
// CATATAN INTEGRASI:
// Jika Anda sudah punya `database_helper.dart` (untuk tabel todos/notes),
// JANGAN pakai file ini sebagai database terpisah. Sebaiknya pindahkan
// isi `_createFinanceTables` ke dalam `onCreate`/`onUpgrade` database
// utama Anda, dan naikkan `version` di sana, supaya semua tabel
// (todos, notes, transactions, budgets, saving_goals) berada di satu
// file .db yang sama.
//
// File ini disediakan sebagai database mandiri (siap pakai) apabila
// Anda belum punya database_helper terpusat, atau ingin memisahkan
// database modul finance dari modul todo/note.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FinanceDatabaseHelper {
  static final FinanceDatabaseHelper instance = FinanceDatabaseHelper._init();
  static Database? _database;

  FinanceDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        goalId TEXT 
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        budgetLimit REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE saving_goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        targetDate TEXT,
        createdAt TEXT NOT NULL,
        emoji TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE saving_goal_entries (
        id TEXT PRIMARY KEY,
        goalId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (goalId) REFERENCES saving_goals (id) ON DELETE CASCADE
      )
    ''');

    await db
        .execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db
        .execute('CREATE INDEX idx_budgets_month_year ON budgets(month, year)');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN goalId TEXT',
      );
    }
  }
}
