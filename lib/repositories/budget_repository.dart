// lib/repositories/budget_repository.dart

import '../models/budget.dart';
import '../models/transaction.dart';
import '../database/finance_database_helper.dart';

class BudgetRepository {
  final _dbHelper = FinanceDatabaseHelper.instance;

  Future<List<Budget>> getByMonth(int month, int year) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return result.map((map) => _fromDbMap(map)).toList();
  }

  Future<Budget?> getByCategoryAndMonth(
      TransactionCategory category, int month, int year) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'budgets',
      where: 'category = ? AND month = ? AND year = ?',
      whereArgs: [category.name, month, year],
    );
    if (result.isEmpty) return null;
    return _fromDbMap(result.first);
  }

  Future<void> insert(Budget budget) async {
    final db = await _dbHelper.database;
    await db.insert('budgets', _toDbMap(budget));
  }

  Future<void> update(Budget budget) async {
    final db = await _dbHelper.database;
    await db.update(
      'budgets',
      _toDbMap(budget),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // 'limit' adalah reserved word di beberapa SQL, jadi disimpan sebagai
  // 'budgetLimit' di kolom tabel.
  Map<String, dynamic> _toDbMap(Budget budget) {
    final map = budget.toMap();
    final limitValue = map.remove('limit');
    map['budgetLimit'] = limitValue;
    return map;
  }

  Budget _fromDbMap(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    copy['limit'] = copy.remove('budgetLimit');
    return Budget.fromMap(copy);
  }
}
