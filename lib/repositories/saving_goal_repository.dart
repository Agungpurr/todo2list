// lib/repositories/saving_goal_repository.dart

import 'package:uuid/uuid.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../database/finance_database_helper.dart';
import 'transaction_repository.dart';

class SavingGoalRepository {
  final _dbHelper = FinanceDatabaseHelper.instance;
  final _transactionRepo = TransactionRepository();
  final _uuid = const Uuid();

  Future<List<SavingGoal>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.query('saving_goals', orderBy: 'createdAt DESC');
    return result.map((map) => SavingGoal.fromMap(map)).toList();
  }

  Future<SavingGoal?> getById(String id) async {
    final db = await _dbHelper.database;
    final result =
        await db.query('saving_goals', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return SavingGoal.fromMap(result.first);
  }

  Future<void> insert(SavingGoal goal) async {
    final db = await _dbHelper.database;
    await db.insert('saving_goals', goal.toMap());
  }

  Future<void> update(SavingGoal goal) async {
    final db = await _dbHelper.database;
    await db.update(
      'saving_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db
        .delete('saving_goal_entries', where: 'goalId = ?', whereArgs: [id]);
    await db.delete('transactions', where: 'goalId = ?', whereArgs: [id]);
    await db.delete('saving_goals', where: 'id = ?', whereArgs: [id]);
  }

  // Tambah/tarik dana dari goal. amount boleh negatif untuk penarikan.
  Future<void> addEntry(String goalId, double amount, {String? note}) async {
    final db = await _dbHelper.database;
    final entry = SavingGoalEntry(
      id: _uuid.v4(),
      goalId: goalId,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    await db.insert('saving_goal_entries', entry.toMap());

    final goal = await getById(goalId);
    if (goal != null) {
      final newAmount = (goal.currentAmount + amount).clamp(0, double.infinity);
      await update(goal.copyWith(currentAmount: newAmount.toDouble()));

      // Otomatis buat transaksi pengeluaran saat setor tabungan
      if (amount > 0) {
        final transaction = Transaction(
          id: _uuid.v4(),
          title: 'Tabungan: ${goal.title}',
          amount: amount,
          type: TransactionType.expense,
          category: TransactionCategory.tabungan,
          date: DateTime.now(),
          note: note ?? 'Setor ke tabungan ${goal.emoji} ${goal.title}',
          goalId: goalId,
        );
        await _transactionRepo.insert(transaction);
      }
    }
  }

  Future<List<SavingGoalEntry>> getEntries(String goalId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'saving_goal_entries',
      where: 'goalId = ?',
      whereArgs: [goalId],
      orderBy: 'date DESC',
    );
    return result.map((map) => SavingGoalEntry.fromMap(map)).toList();
  }
}
