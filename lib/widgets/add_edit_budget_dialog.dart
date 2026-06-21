// lib/widgets/add_edit_budget_dialog.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../utils/finance_helpers.dart';

class AddEditBudgetDialog extends StatefulWidget {
  final Budget? budget;
  final int month;
  final int year;
  final List<TransactionCategory> excludeCategories;
  final Function(Budget) onSave;

  const AddEditBudgetDialog({
    Key? key,
    this.budget,
    required this.month,
    required this.year,
    this.excludeCategories = const [],
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditBudgetDialog> createState() => _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends State<AddEditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitController;
  late TransactionCategory _category;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
        text: widget.budget != null
            ? widget.budget!.limit.toStringAsFixed(0)
            : '');
    final available = _availableCategories;
    _category = widget.budget?.category ??
        (available.isNotEmpty ? available.first : TransactionCategory.makanan);
  }

  List<TransactionCategory> get _availableCategories {
    if (widget.budget != null) {
      return TransactionCategoryX.expenseCategories;
    }
    return TransactionCategoryX.expenseCategories
        .where((c) => !widget.excludeCategories.contains(c))
        .toList();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final limit =
        double.tryParse(_limitController.text.replaceAll('.', '')) ?? 0;

    final budget = Budget(
      id: widget.budget?.id ?? const Uuid().v4(),
      category: _category,
      limit: limit,
      month: widget.month,
      year: widget.year,
    );

    widget.onSave(budget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.budget != null;
    final available = _availableCategories;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Budget' : 'Tambah Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (available.isEmpty && !isEdit)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Semua kategori sudah punya budget bulan ini.',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              DropdownButtonFormField<TransactionCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: (isEdit
                        ? TransactionCategoryX.expenseCategories
                        : available)
                    .map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    enabled: isEdit || !widget.excludeCategories.contains(cat),
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
                onChanged:
                    isEdit ? null : (v) => setState(() => _category = v!),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit Budget (Rp)',
                hintText: 'cth. 500000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Limit wajib diisi';
                final parsed = double.tryParse(v.replaceAll('.', ''));
                if (parsed == null || parsed <= 0) return 'Limit tidak valid';
                return null;
              },
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
          onPressed: (available.isEmpty && !isEdit) ? null : _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
