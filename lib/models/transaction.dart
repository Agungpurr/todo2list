// lib/models/transaction.dart

enum TransactionType { income, expense }

enum TransactionCategory {
  // Expense categories
  makanan,
  transport,
  kos,
  pendidikan,
  hiburan,
  jajan,
  pulsaInternet,
  kesehatan,
  lainnyaExpense,
  tabungan,
  // Income categories
  uangSaku,
  gaji,
  beasiswa,
  lainnyaIncome,
}

extension TransactionCategoryX on TransactionCategory {
  bool get isExpense => [
        TransactionCategory.makanan,
        TransactionCategory.transport,
        TransactionCategory.kos,
        TransactionCategory.pendidikan,
        TransactionCategory.hiburan,
        TransactionCategory.jajan,
        TransactionCategory.pulsaInternet,
        TransactionCategory.kesehatan,
        TransactionCategory.tabungan,
        TransactionCategory.lainnyaExpense,
      ].contains(this);

  bool get isIncome => !isExpense;

  static List<TransactionCategory> get expenseCategories => [
        TransactionCategory.makanan,
        TransactionCategory.transport,
        TransactionCategory.kos,
        TransactionCategory.pendidikan,
        TransactionCategory.hiburan,
        TransactionCategory.jajan,
        TransactionCategory.pulsaInternet,
        TransactionCategory.kesehatan,
        TransactionCategory.tabungan,
        TransactionCategory.lainnyaExpense,
      ];

  static List<TransactionCategory> get incomeCategories => [
        TransactionCategory.uangSaku,
        TransactionCategory.gaji,
        TransactionCategory.beasiswa,
        TransactionCategory.lainnyaIncome,
      ];
}

class Transaction {
  final String id;
  final String title;
  final String? note;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final DateTime createdAt;
  final String? goalId;

  Transaction({
    required this.id,
    required this.title,
    this.note,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    DateTime? createdAt,
    this.goalId,
  }) : createdAt = createdAt ?? DateTime.now();

  Transaction copyWith({
    String? id,
    String? title,
    String? note,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? goalId,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'goalId': goalId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      note: map['note'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.lainnyaExpense,
      ),
      goalId: map['goalId'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
