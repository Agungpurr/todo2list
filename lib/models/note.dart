// lib/models/note.dart

import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class Note {
  final String id;
  String title;
  // content disimpan sebagai Quill Delta dalam bentuk List<dynamic> (JSON ops)
  List<dynamic> content;
  // Plain text version dari content, untuk keperluan search & preview.
  // Selalu di-generate ulang dari `content`, jangan diisi manual.
  String contentPlain;
  String? mood; // emoji, contoh: '😊'
  List<String> tags;
  final DateTime date; // tanggal jurnal (bisa beda dari createdAt)
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.contentPlain,
    this.mood,
    this.tags = const [],
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  // Buat Note baru dari sebuah quill.Document
  factory Note.fromDocument({
    required String id,
    required String title,
    required quill.Document document,
    String? mood,
    List<String> tags = const [],
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return Note(
      id: id,
      title: title,
      content: document.toDelta().toJson(),
      contentPlain: document.toPlainText().trim(),
      mood: mood,
      tags: tags,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper untuk dapat quill.Document dari content tersimpan,
  // dipakai saat membuka editor untuk edit.
  quill.Document toDocument() {
    if (content.isEmpty) {
      return quill.Document();
    }
    try {
      return quill.Document.fromJson(content);
    } catch (_) {
      return quill.Document();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': jsonEncode(content),
      'content_plain': contentPlain,
      'mood': mood,
      'tags': tags.join(','),
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    List<dynamic> parsedContent = [];
    try {
      final decoded = jsonDecode(map['content'] as String);
      if (decoded is List) parsedContent = decoded;
    } catch (_) {
      parsedContent = [];
    }

    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: parsedContent,
      contentPlain: map['content_plain'] as String? ?? '',
      mood: map['mood'] as String?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Note copyWith({
    String? title,
    List<dynamic>? content,
    String? contentPlain,
    String? mood,
    bool clearMood = false,
    List<String>? tags,
    DateTime? date,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentPlain: contentPlain ?? this.contentPlain,
      mood: clearMood ? null : (mood ?? this.mood),
      tags: tags ?? this.tags,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'Note(id: $id, title: $title, date: $date)';
}
