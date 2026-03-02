// lib/widgets/add_edit_dialog.dart

import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../utils/todo_helpers.dart';

class AddEditDialog extends StatefulWidget {
  final Todo? todo;
  final Function(Todo) onSave;

  const AddEditDialog({
    Key? key,
    this.todo,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<AddEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _tagController;

  late TodoPriority _priority;
  late TodoCategory _category;
  DateTime? _dueDate;
  late List<String> _tags;

  bool get _isEdit => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _descController = TextEditingController(text: todo?.description ?? '');
    _tagController = TextEditingController();
    _priority = todo?.priority ?? TodoPriority.medium;
    _category = todo?.category ?? TodoCategory.other;
    _dueDate = todo?.dueDate;
    _tags = List.from(todo?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    if (value.isNotEmpty && !_tags.contains(value)) {
      setState(() {
        _tags.add(value);
        _tagController.clear();
      });
    }
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong')),
      );
      return;
    }

    final todo = widget.todo;
    final newTodo = Todo(
      id: _isEdit ? todo!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      createdAt: _isEdit ? todo!.createdAt : DateTime.now(),
      dueDate: _dueDate,
      priority: _priority,
      category: _category,
      tags: _tags,
      isCompleted: _isEdit ? todo!.isCompleted : false,
    );

    widget.onSave(newTodo);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Todo' : 'Tambah Todo Baru'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Priority Dropdown
            DropdownButtonFormField<TodoPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Prioritas',
                border: OutlineInputBorder(),
              ),
              items: TodoPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: TodoHelpers.getPriorityColor(priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(TodoHelpers.getPriorityText(priority)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<TodoCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: TodoCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(TodoHelpers.getCategoryIcon(category), size: 16),
                      const SizedBox(width: 8),
                      Text(TodoHelpers.getCategoryText(category)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),

            // Due Date Picker
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dueDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Jatuh Tempo',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dueDate == null
                      ? 'Pilih tanggal'
                      : TodoHelpers.formatDate(_dueDate!),
                ),
              ),
            ),
            if (_dueDate != null)
              TextButton.icon(
                onPressed: () => setState(() => _dueDate = null),
                icon: const Icon(Icons.clear),
                label: const Text('Hapus tanggal'),
              ),
            const SizedBox(height: 16),

            // Tags
            const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Tambah tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addTag(_tagController.text),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text(_isEdit ? 'Update' : 'Tambah'),
        ),
      ],
    );
  }
}
