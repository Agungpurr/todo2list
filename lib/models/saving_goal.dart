// lib/models/saving_goal.dart

class SavingGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime createdAt;
  final String emoji;

  SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    DateTime? createdAt,
    this.emoji = '🎯',
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  bool get isAchieved => currentAmount >= targetAmount;

  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  SavingGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    String? emoji,
    bool clearTargetDate = false,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      createdAt: createdAt ?? this.createdAt,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'emoji': emoji,
    };
  }

  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
      targetDate: map['targetDate'] != null
          ? DateTime.parse(map['targetDate'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      emoji: map['emoji'] as String? ?? '🎯',
    );
  }
}

// Catatan setor/tarik dana ke saving goal, supaya ada histori
class SavingGoalEntry {
  final String id;
  final String goalId;
  final double amount; // positif = setor, negatif = tarik
  final DateTime date;
  final String? note;

  SavingGoalEntry({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory SavingGoalEntry.fromMap(Map<String, dynamic> map) {
    return SavingGoalEntry(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}
