// lib/repositories/transaction_repository.dart

import '../models/transaction.dart';
import '../database/finance_database_helper.dart';

class TransactionRepository {
  final _dbHelper = FinanceDatabaseHelper.instance;

  Future<List<Transaction>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getByMonth(int month, int year) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getByDateRange(start, end);
  }

  Future<Transaction?> getById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Transaction.fromMap(result.first);
  }

  Future<void> insert(Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<void> update(Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalByType(
      TransactionType type, int month, int year) async {
    final transactions = await getByMonth(month, year);
    return transactions
        .where((t) => t.type == type)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getBalance() async {
    final all = await getAll();
    double balance = 0;
    for (final t in all) {
      balance += t.type == TransactionType.income ? t.amount : -t.amount;
    }
    return balance;
  }
}
