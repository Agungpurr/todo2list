// lib/models/todo.dart

enum TodoPriority { low, medium, high }

enum TodoCategory { personal, work, shopping, health, other }

class Todo {
  final String id;
  String title;
  String description;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? dueDate;
  TodoPriority priority;
  TodoCategory category;
  List<String> tags;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.priority = TodoPriority.medium,
    this.category = TodoCategory.other,
    this.tags = const [],
  });

  // Convert Todo to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'priority': priority.index,
      'category': category.index,
      'tags': tags.join(','),
    };
  }

  // Create Todo from Map (from database)
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      priority: TodoPriority.values[map['priority'] as int],
      category: TodoCategory.values[map['category'] as int],
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
    );
  }

  // Create a copy with updated fields
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    bool clearDueDate = false,
    TodoPriority? priority,
    TodoCategory? category,
    List<String>? tags,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() =>
      'Todo(id: $id, title: $title, isCompleted: $isCompleted)';
}
