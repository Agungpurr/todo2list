// lib/models/budget.dart

import 'transaction.dart';

class Budget {
  final String id;
  final TransactionCategory category;
  final double limit;
  final int month; // 1-12
  final int year;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
    required this.year,
  });

  Budget copyWith({
    String? id,
    TransactionCategory? category,
    double? limit,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'limit': limit,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.lainnyaExpense,
      ),
      limit: (map['limit'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }
}
