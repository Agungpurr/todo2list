// lib/utils/todo_helpers.dart

import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoHelpers {
  // ===== PRIORITY =====
  static Color getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return Colors.green;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.high:
        return Colors.red;
    }
  }

  static String getPriorityText(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return 'Rendah';
      case TodoPriority.medium:
        return 'Sedang';
      case TodoPriority.high:
        return 'Tinggi';
    }
  }

  // ===== CATEGORY =====
  static IconData getCategoryIcon(TodoCategory category) {
    switch (category) {
      case TodoCategory.personal:
        return Icons.person;
      case TodoCategory.work:
        return Icons.work;
      case TodoCategory.shopping:
        return Icons.shopping_cart;
      case TodoCategory.health:
        return Icons.favorite;
      case TodoCategory.other:
        return Icons.more_horiz;
    }
  }

  static String getCategoryText(TodoCategory category) {
    switch (category) {
      case TodoCategory.personal:
        return 'Personal';
      case TodoCategory.work:
        return 'Pekerjaan';
      case TodoCategory.shopping:
        return 'Belanja';
      case TodoCategory.health:
        return 'Kesehatan';
      case TodoCategory.other:
        return 'Lainnya';
    }
  }

  // ===== DATE =====
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hari ini';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Besok';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static bool isOverdue(Todo todo) {
    return todo.dueDate != null &&
        todo.dueDate!.isBefore(DateTime.now()) &&
        !todo.isCompleted;
  }
}
