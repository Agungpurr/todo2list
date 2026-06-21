// lib/widgets/add_edit_saving_goal_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/saving_goal.dart';

class AddEditSavingGoalDialog extends StatefulWidget {
  final SavingGoal? goal;
  final Function(SavingGoal) onSave;

  const AddEditSavingGoalDialog({
    Key? key,
    this.goal,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditSavingGoalDialog> createState() =>
      _AddEditSavingGoalDialogState();
}

class _AddEditSavingGoalDialogState extends State<AddEditSavingGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  DateTime? _targetDate;
  String _emoji = '🎯';

  final List<String> _emojiOptions = [
    '🎯',
    '💻',
    '📱',
    '🎓',
    '✈️',
    '🏠',
    '🛵',
    '👟',
    '🎮',
    '📷'
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetController = TextEditingController(
        text: g != null ? g.targetAmount.toStringAsFixed(0) : '');
    _targetDate = g?.targetDate;
    _emoji = g?.emoji ?? '🎯';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final target =
        double.tryParse(_targetController.text.replaceAll('.', '')) ?? 0;

    final goal = SavingGoal(
      id: widget.goal?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      targetAmount: target,
      currentAmount: widget.goal?.currentAmount ?? 0,
      targetDate: _targetDate,
      createdAt: widget.goal?.createdAt,
      emoji: _emoji,
    );

    widget.onSave(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goal != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Target Tabungan' : 'Tambah Target Tabungan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: _emojiOptions.map((e) {
                  final selected = e == _emoji;
                  return InkWell(
                    onTap: () => setState(() => _emoji = e),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nama Target',
                  hintText: 'cth. Beli Laptop',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Jumlah (Rp)',
                  hintText: 'cth. 5000000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Target wajib diisi';
                  final parsed = double.tryParse(v.replaceAll('.', ''));
                  if (parsed == null || parsed <= 0)
                    return 'Target tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Target Tanggal (opsional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _targetDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _targetDate = null),
                          )
                        : const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    _targetDate != null
                        ? DateFormat('d MMMM yyyy', 'id_ID')
                            .format(_targetDate!)
                        : 'Tidak ditentukan',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
