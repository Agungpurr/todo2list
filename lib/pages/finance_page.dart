// lib/pages/finance_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/saving_goal.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/saving_goal_repository.dart';
import '../utils/finance_helpers.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_edit_transaction_dialog.dart';
import '../widgets/budget_card.dart';
import '../widgets/add_edit_budget_dialog.dart';
import '../widgets/saving_goal_card.dart';
import '../widgets/add_edit_saving_goal_dialog.dart';
import '../widgets/add_fund_dialog.dart';
import 'finance_report_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({Key? key}) : super(key: key);

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final BudgetRepository _budgetRepo = BudgetRepository();
  final SavingGoalRepository _savingGoalRepo = SavingGoalRepository();

  late TabController _tabController;

  List<Transaction> _monthTransactions = [];
  List<Budget> _budgets = [];
  List<SavingGoal> _savingGoals = [];
  bool _isLoading = true;

  DateTime _viewedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await _transactionRepo.getByMonth(
        _viewedMonth.month, _viewedMonth.year);
    final budgets =
        await _budgetRepo.getByMonth(_viewedMonth.month, _viewedMonth.year);
    final goals = await _savingGoalRepo.getAll();
    setState(() {
      _monthTransactions = transactions;
      _budgets = budgets;
      _savingGoals = goals;
      _isLoading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + delta);
    });
    _loadData();
  }

  double get _totalIncome => _monthTransactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _monthTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  double _spentForCategory(TransactionCategory category) {
    return _monthTransactions
        .where(
            (t) => t.category == category && t.type == TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // ===== TRANSACTION CRUD =====
  void _showAddEditTransactionDialog({Transaction? transaction}) {
    showDialog(
      context: context,
      builder: (_) => AddEditTransactionDialog(
        transaction: transaction,
        onSave: (newTx) async {
          if (transaction == null) {
            await _transactionRepo.insert(newTx);
          } else {
            await _transactionRepo.update(newTx);
          }
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction t) async {
    final confirmed = await _confirmDelete('Hapus Transaksi', t.title);
    if (!confirmed) return;
    await _transactionRepo.delete(t.id);
    await _loadData();
  }

  // ===== BUDGET CRUD =====
  void _showAddEditBudgetDialog({Budget? budget}) {
    showDialog(
      context: context,
      builder: (_) => AddEditBudgetDialog(
        budget: budget,
        month: _viewedMonth.month,
        year: _viewedMonth.year,
        excludeCategories: _budgets.map((b) => b.category).toList(),
        onSave: (newBudget) async {
          if (budget == null) {
            await _budgetRepo.insert(newBudget);
          } else {
            await _budgetRepo.update(newBudget);
          }
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteBudget(Budget b) async {
    final confirmed = await _confirmDelete(
        'Hapus Budget', FinanceHelpers.getCategoryLabel(b.category));
    if (!confirmed) return;
    await _budgetRepo.delete(b.id);
    await _loadData();
  }

  // ===== SAVING GOAL CRUD =====
  void _showAddEditGoalDialog({SavingGoal? goal}) {
    showDialog(
      context: context,
      builder: (_) => AddEditSavingGoalDialog(
        goal: goal,
        onSave: (newGoal) async {
          if (goal == null) {
            await _savingGoalRepo.insert(newGoal);
          } else {
            await _savingGoalRepo.update(newGoal);
          }
          await _loadData();
        },
      ),
    );
  }

  void _showAddFundDialog(SavingGoal goal) {
    showDialog(
      context: context,
      builder: (_) => AddFundDialog(
        goal: goal,
        onAdd: (amount, note) async {
          await _savingGoalRepo.addEntry(goal.id, amount, note: note);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteGoal(SavingGoal g) async {
    final confirmed = await _confirmDelete('Hapus Target', g.title);
    if (!confirmed) return;
    await _savingGoalRepo.delete(g.id);
    await _loadData();
  }

  Future<bool> _confirmDelete(String title, String itemName) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text('Yakin ingin menghapus "$itemName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Laporan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinanceReportPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transaksi', icon: Icon(Icons.receipt_long, size: 18)),
            Tab(text: 'Budget', icon: Icon(Icons.pie_chart, size: 18)),
            Tab(text: 'Tabungan', icon: Icon(Icons.savings, size: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMonthSelector(),
                _buildSummaryCard(balance),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionTab(),
                      _buildBudgetTab(),
                      _buildSavingGoalTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _showAddEditBudgetDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Budget'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => _showAddEditGoalDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Target'),
        );
      default:
        return FloatingActionButton.extended(
          onPressed: () => _showAddEditTransactionDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Transaksi'),
        );
    }
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy', 'id_ID').format(_viewedMonth),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: balance >= 0 ? Colors.green[50] : Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Saldo Bulan Ini',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                FinanceHelpers.formatRupiah(balance),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniStat('Pemasukan', _totalIncome, Colors.green,
                        Icons.arrow_downward),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey[300]),
                  Expanded(
                    child: _miniStat('Pengeluaran', _totalExpense, Colors.red,
                        Icons.arrow_upward),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          FinanceHelpers.formatRupiah(value),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTransactionTab() {
    if (_monthTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        text: 'Belum ada transaksi bulan ini',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _monthTransactions.length,
        itemBuilder: (context, index) {
          final t = _monthTransactions[index];
          return TransactionCard(
            transaction: t,
            onTap: () => _showAddEditTransactionDialog(transaction: t),
            onDelete: () => _deleteTransaction(t),
          );
        },
      ),
    );
  }

  Widget _buildBudgetTab() {
    if (_budgets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pie_chart_outline,
        text: 'Belum ada budget bulan ini',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _budgets.length,
        itemBuilder: (context, index) {
          final b = _budgets[index];
          return BudgetCard(
            budget: b,
            spent: _spentForCategory(b.category),
            onTap: () => _showAddEditBudgetDialog(budget: b),
            onDelete: () => _deleteBudget(b),
          );
        },
      ),
    );
  }

  Widget _buildSavingGoalTab() {
    if (_savingGoals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.savings_outlined,
        text: 'Belum ada target tabungan',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _savingGoals.length,
        itemBuilder: (context, index) {
          final g = _savingGoals[index];
          return SavingGoalCard(
            goal: g,
            onTap: () => _showAddEditGoalDialog(goal: g),
            onAddFund: () => _showAddFundDialog(g),
            onDelete: () => _deleteGoal(g),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
