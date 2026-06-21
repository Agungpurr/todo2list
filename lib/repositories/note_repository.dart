// lib/repositories/note_repository.dart

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/note.dart';

class NoteRepository {
  final DatabaseHelper _dbHelper;

  NoteRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ===== CREATE =====
  Future<void> insert(Note note) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableNotes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===== READ =====
  Future<List<Note>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      orderBy: 'date DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  // Ambil semua note yang tanggalnya (kolom `date`) sama dengan tanggal ini.
  // Dipakai oleh CalendarPage.
  Future<List<Note>> getByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  // Search berdasarkan title, isi teks polos (content_plain), atau tags
  Future<List<Note>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'title LIKE ? OR content_plain LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getByTag(String tag) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<int> getTotalCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableNotes}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===== UPDATE =====
  Future<void> update(Note note) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableNotes,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // ===== DELETE =====
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableNotes);
  }
}
