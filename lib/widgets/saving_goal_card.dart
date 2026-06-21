// lib/widgets/saving_goal_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/saving_goal.dart';
import '../utils/finance_helpers.dart';

class SavingGoalCard extends StatelessWidget {
  final SavingGoal goal;
  final VoidCallback onTap;
  final VoidCallback onAddFund;
  final VoidCallback onDelete;

  const SavingGoalCard({
    Key? key,
    required this.goal,
    required this.onTap,
    required this.onAddFund,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressPercent = (goal.progress * 100).toStringAsFixed(0);

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
                  Text(goal.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (goal.targetDate != null)
                          Text(
                            'Target: ${DateFormat('d MMM yyyy', 'id_ID').format(goal.targetDate!)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  if (goal.isAchieved)
                    const Icon(Icons.celebration, color: Colors.amber, size: 22)
                  else
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: onAddFund,
                      tooltip: 'Tambah dana',
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
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  color: goal.isAchieved ? Colors.amber : Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${FinanceHelpers.formatRupiah(goal.currentAmount)} ($progressPercent%)',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'dari ${FinanceHelpers.formatRupiah(goal.targetAmount)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (goal.isAchieved)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '🎉 Target tercapai!',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
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
