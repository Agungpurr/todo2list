// lib/widgets/add_fund_dialog.dart

import 'package:flutter/material.dart';
import '../models/saving_goal.dart';

class AddFundDialog extends StatefulWidget {
  final SavingGoal goal;
  final Function(double amount, String? note) onAdd;

  const AddFundDialog({
    Key? key,
    required this.goal,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddFundDialog> createState() => _AddFundDialogState();
}

class _AddFundDialogState extends State<AddFundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isWithdraw = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    widget.onAdd(
      _isWithdraw ? -amount : amount,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.goal.emoji} ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Setor')),
                ButtonSegment(value: true, label: Text('Tarik')),
              ],
              selected: {_isWithdraw},
              onSelectionChanged: (s) => setState(() => _isWithdraw = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Jumlah wajib diisi';
                final parsed = double.tryParse(v.replaceAll('.', ''));
                if (parsed == null || parsed <= 0) return 'Jumlah tidak valid';
                if (_isWithdraw && parsed > widget.goal.currentAmount) {
                  return 'Tidak bisa menarik lebih dari saldo (${widget.goal.currentAmount.toStringAsFixed(0)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
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
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
