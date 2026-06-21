// lib/widgets/add_edit_transaction_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../utils/finance_helpers.dart';

class AddEditTransactionDialog extends StatefulWidget {
  final Transaction? transaction;
  final DateTime? initialDate;
  final Function(Transaction) onSave;

  const AddEditTransactionDialog({
    Key? key,
    this.transaction,
    this.initialDate,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditTransactionDialog> createState() =>
      _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _type;
  late TransactionCategory _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _titleController = TextEditingController(text: t?.title ?? '');
    _amountController = TextEditingController(
        text: t != null ? t.amount.toStringAsFixed(0) : '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _type = t?.type ?? TransactionType.expense;
    _category = t?.category ?? TransactionCategory.makanan;
    _date = t?.date ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _availableCategories =>
      _type == TransactionType.expense
          ? TransactionCategoryX.expenseCategories
          : TransactionCategoryX.incomeCategories;

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _category = _availableCategories.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
            _amountController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0;

    final transaction = Transaction(
      id: widget.transaction?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      amount: amount,
      type: _type,
      category: _category,
      date: _date,
      createdAt: widget.transaction?.createdAt,
    );

    widget.onSave(transaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.arrow_upward, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Pemasukan'),
                    icon: Icon(Icons.arrow_downward, size: 16),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    _onTypeChanged(selection.first),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'cth. Makan siang',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  hintText: 'cth. 15000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Jumlah wajib diisi';
                  final parsed = double.tryParse(v.replaceAll('.', ''));
                  if (parsed == null || parsed <= 0)
                    return 'Jumlah tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<TransactionCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _availableCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FinanceHelpers.getCategoryIcon(cat),
                            size: 18,
                            color: FinanceHelpers.getCategoryColor(cat)),
                        const SizedBox(width: 8),
                        Text(FinanceHelpers.getCategoryLabel(cat)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_date)),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
