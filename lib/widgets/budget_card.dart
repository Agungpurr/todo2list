// lib/widgets/budget_card.dart

import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../utils/finance_helpers.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BudgetCard({
    Key? key,
    required this.budget,
    required this.spent,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = FinanceHelpers.getCategoryColor(budget.category);
    final progress =
        budget.limit <= 0 ? 0.0 : (spent / budget.limit).clamp(0.0, 1.0);
    final isOver = spent > budget.limit;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(FinanceHelpers.getCategoryIcon(budget.category),
                      color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      FinanceHelpers.getCategoryLabel(budget.category),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOver ? Colors.red : color,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.grey,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.15),
                  color: isOver ? Colors.red : color,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${FinanceHelpers.formatRupiah(spent)} terpakai',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOver ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Budget ${FinanceHelpers.formatRupiah(budget.limit)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (isOver)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '⚠️ Melebihi budget ${FinanceHelpers.formatRupiah(spent - budget.limit)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
