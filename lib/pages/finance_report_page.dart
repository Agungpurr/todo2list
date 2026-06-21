// lib/pages/finance_report_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../utils/finance_helpers.dart';
import '../services/finance_export_service.dart';

class FinanceReportPage extends StatefulWidget {
  const FinanceReportPage({Key? key}) : super(key: key);

  @override
  State<FinanceReportPage> createState() => _FinanceReportPageState();
}

class _FinanceReportPageState extends State<FinanceReportPage> {
  final TransactionRepository _repository = TransactionRepository();

  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isExporting = false;

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await _repository.getByDateRange(
      _dateRange.start,
      DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day,
          23, 59, 59),
    );
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  void _setQuickRange(int monthsBack) {
    final now = DateTime.now();
    if (monthsBack == 0) {
      setState(() {
        _dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      });
    } else {
      setState(() {
        _dateRange = DateTimeRange(
          start: DateTime(now.year, now.month - monthsBack, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      });
    }
    _loadData();
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  Map<TransactionCategory, double> get _expenseByCategory {
    final map = <TransactionCategory, double>{};
    for (final t
        in _transactions.where((t) => t.type == TransactionType.expense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  // Tren per bulan dalam rentang yang dipilih (maks 12 titik agar tetap rapi)
  List<_MonthlyTrend> get _monthlyTrend {
    final Map<String, _MonthlyTrend> map = {};
    for (final t in _transactions) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(
          key, () => _MonthlyTrend(t.date.year, t.date.month, 0, 0));
      if (t.type == TransactionType.income) {
        map[key]!.income += t.amount;
      } else {
        map[key]!.expense += t.amount;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) =>
          DateTime(a.year, a.month).compareTo(DateTime(b.year, b.month)));
    if (list.length > 12) {
      return list.sublist(list.length - 12);
    }
    return list;
  }

  Future<void> _export(String format) async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada transaksi untuk diexport')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      if (format == 'csv') {
        await FinanceExportService.exportCsv(_transactions, _dateRange);
      } else {
        await FinanceExportService.exportPdf(
          _transactions,
          _dateRange,
          totalIncome: _totalIncome,
          totalExpense: _totalExpense,
          expenseByCategory: _expenseByCategory,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Laporan Keuangan'),
        actions: [
          PopupMenuButton<String>(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onSelected: _isExporting ? null : _export,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateRangeSelector(),
                  const SizedBox(height: 16),
                  _buildSummaryRow(),
                  const SizedBox(height: 24),
                  if (_transactions.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _sectionTitle('Pengeluaran per Kategori'),
                    const SizedBox(height: 8),
                    _buildCategoryPieChart(),
                    const SizedBox(height: 12),
                    _buildCategoryLegend(),
                    const SizedBox(height: 24),
                    _sectionTitle('Tren Bulanan'),
                    const SizedBox(height: 8),
                    _buildMonthlyTrendChart(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${DateFormat('d MMM yyyy', 'id_ID').format(_dateRange.start)} - ${DateFormat('d MMM yyyy', 'id_ID').format(_dateRange.end)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Bulan Ini'),
              onPressed: () => _setQuickRange(0),
            ),
            ActionChip(
              label: const Text('3 Bulan'),
              onPressed: () => _setQuickRange(2),
            ),
            ActionChip(
              label: const Text('6 Bulan'),
              onPressed: () => _setQuickRange(5),
            ),
            ActionChip(
              label: const Text('1 Tahun'),
              onPressed: () => _setQuickRange(11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final balance = _totalIncome - _totalExpense;
    return Row(
      children: [
        Expanded(
            child: _summaryBox(
                'Pemasukan', _totalIncome, Colors.green, Icons.arrow_downward)),
        const SizedBox(width: 8),
        Expanded(
            child: _summaryBox(
                'Pengeluaran', _totalExpense, Colors.red, Icons.arrow_upward)),
        const SizedBox(width: 8),
        Expanded(
            child: _summaryBox(
                'Selisih',
                balance,
                balance >= 0 ? Colors.blue : Colors.red,
                Icons.account_balance_wallet)),
      ],
    );
  }

  Widget _summaryBox(String label, double value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            const SizedBox(height: 2),
            Text(
              FinanceHelpers.formatRupiahCompact(value),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final data = _expenseByCategory;
    if (data.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Tidak ada data pengeluaran')),
      );
    }
    final total = data.values.fold<double>(0.0, (a, b) => a + b);

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: data.entries.map((entry) {
            final percent = (entry.value / total * 100);
            return PieChartSectionData(
              color: FinanceHelpers.getCategoryColor(entry.key),
              value: entry.value,
              title: percent >= 5 ? '${percent.toStringAsFixed(0)}%' : '',
              radius: 60,
              titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryLegend() {
    final data = _expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: data.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: FinanceHelpers.getCategoryColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(FinanceHelpers.getCategoryLabel(entry.key),
                      style: const TextStyle(fontSize: 13))),
              Text(
                FinanceHelpers.formatRupiah(entry.value),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyTrendChart() {
    final trend = _monthlyTrend;
    if (trend.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Tidak ada data tren')),
      );
    }

    final maxY = trend
        .map((t) => t.income > t.expense ? t.income : t.expense)
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox();
                  final t = trend[i];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM', 'id_ID')
                          .format(DateTime(t.year, t.month)),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.income))
                  .toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData:
                  BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
            ),
            LineChartBarData(
              spots: trend
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
                  .toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData:
                  BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Tidak ada transaksi pada rentang ini',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTrend {
  final int year;
  final int month;
  double income;
  double expense;
  _MonthlyTrend(this.year, this.month, this.income, this.expense);
}
