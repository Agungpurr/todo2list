// lib/widgets/filter_dialog.dart

import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../utils/todo_helpers.dart';

class FilterDialog extends StatelessWidget {
  final TodoCategory? selectedCategory;
  final TodoPriority? selectedPriority;
  final ValueChanged<TodoCategory?> onCategoryChanged;
  final ValueChanged<TodoPriority?> onPriorityChanged;
  final VoidCallback onReset;

  const FilterDialog({
    Key? key,
    required this.selectedCategory,
    required this.selectedPriority,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Todo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: selectedCategory == null,
                onSelected: (_) {
                  onCategoryChanged(null);
                  Navigator.pop(context);
                },
              ),
              ...TodoCategory.values.map((cat) => FilterChip(
                    label: Text(TodoHelpers.getCategoryText(cat)),
                    selected: selectedCategory == cat,
                    onSelected: (_) {
                      onCategoryChanged(cat);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Prioritas:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: selectedPriority == null,
                onSelected: (_) {
                  onPriorityChanged(null);
                  Navigator.pop(context);
                },
              ),
              ...TodoPriority.values.map((p) => FilterChip(
                    label: Text(TodoHelpers.getPriorityText(p)),
                    selected: selectedPriority == p,
                    onSelected: (_) {
                      onPriorityChanged(p);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onReset();
            Navigator.pop(context);
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
