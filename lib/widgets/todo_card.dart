// lib/widgets/todo_card.dart

import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../utils/todo_helpers.dart';
import 'info_chip.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoCard({
    Key? key,
    required this.todo,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOverdue = TodoHelpers.isOverdue(todo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: todo.isCompleted ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: todo.isCompleted,
                    onChanged: (_) => onToggle(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        if (todo.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            todo.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TodoHelpers.getPriorityColor(todo.priority),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      TodoHelpers.getPriorityText(todo.priority),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  InfoChip(
                    icon: TodoHelpers.getCategoryIcon(todo.category),
                    label: TodoHelpers.getCategoryText(todo.category),
                    color: Colors.blue,
                  ),
                  if (todo.dueDate != null)
                    InfoChip(
                      icon: Icons.calendar_today,
                      label: TodoHelpers.formatDate(todo.dueDate!),
                      color: isOverdue ? Colors.red : Colors.orange,
                    ),
                  ...todo.tags.map((tag) => InfoChip(
                        icon: Icons.tag,
                        label: tag,
                        color: Colors.purple,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
