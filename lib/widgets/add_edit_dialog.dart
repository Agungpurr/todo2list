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
  DateTime? _dueDate; // tanggal saja (jam selalu 00:00, jam asli di _dueTime)
  TimeOfDay? _dueTime;
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
    _tags = List.from(todo?.tags ?? []);

    if (todo?.dueDate != null) {
      final d = todo!.dueDate!;
      _dueDate = DateTime(d.year, d.month, d.day);
      _dueTime = TimeOfDay(hour: d.hour, minute: d.minute);
    }
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

  // Gabungkan _dueDate + _dueTime jadi satu DateTime lengkap.
  // Kalau jam belum dipilih, default jam 23:59 (akhir hari) supaya
  // notifikasi "2 jam sebelum" tetap masuk akal.
  DateTime? get _combinedDueDateTime {
    if (_dueDate == null) return null;
    final time = _dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _dueTime = time);
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
      dueDate: _combinedDueDateTime,
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

            // Due Date + Time Picker
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _dueDate == null ? null : _pickTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Jam',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.access_time),
                        enabled: _dueDate != null,
                      ),
                      child: Text(
                        _dueTime == null ? '--:--' : _dueTime!.format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_dueDate != null) ...[
              const SizedBox(height: 4),
              if (_dueTime == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Belum pilih jam — pengingat akan dianggap jam 23:59',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _dueDate = null;
                  _dueTime = null;
                }),
                icon: const Icon(Icons.clear),
                label: const Text('Hapus tanggal & jam'),
              ),
            ],
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
