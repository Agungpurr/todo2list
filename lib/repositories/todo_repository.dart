// lib/repositories/todo_repository.dart

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/todo.dart';

class TodoRepository {
  final DatabaseHelper _dbHelper;

  TodoRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ===== CREATE =====
  Future<void> insert(Todo todo) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableTodos,
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===== READ =====
  Future<List<Todo>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTodos,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  Future<Todo?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Todo.fromMap(maps.first);
  }

  Future<List<Todo>> getByCategory(int categoryIndex) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'category = ?',
      whereArgs: [categoryIndex],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  Future<List<Todo>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTodos,
      where: 'title LIKE ? OR description LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  Future<int> getActiveCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTodos} WHERE is_completed = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCompletedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTodos} WHERE is_completed = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTodos}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===== UPDATE =====
  Future<void> update(Todo todo) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableTodos,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> toggleCompleted(String id, bool isCompleted) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableTodos,
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== DELETE =====
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableTodos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCompleted() async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableTodos,
      where: 'is_completed = ?',
      whereArgs: [1],
    );
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableTodos);
  }
}
