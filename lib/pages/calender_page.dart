// lib/pages/calendar_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/todo.dart';
import '../models/note.dart';
import '../models/transaction.dart';
import '../repositories/todo_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/transaction_repository.dart';
import '../utils/todo_helpers.dart';

import '../widgets/todo_card.dart';
import '../widgets/note_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_edit_dialog.dart';
import '../widgets/add_edit_note_dialog.dart';
import '../widgets/add_edit_transaction_dialog.dart';
import '../widgets/filter_dialog.dart';
import '../services/notification_service.dart';

import 'notes_list_page.dart';
import 'settings_page.dart';
import 'todo_list_page.dart';
import 'finance_page.dart';

// Item gabungan untuk ditampilkan di kalender: bisa Todo, Note, atau Transaction
class _CalendarItem {
  final Todo? todo;
  final Note? note;
  final Transaction? transaction;
  _CalendarItem.fromTodo(this.todo)
      : note = null,
        transaction = null;
  _CalendarItem.fromNote(this.note)
      : todo = null,
        transaction = null;
  _CalendarItem.fromTransaction(this.transaction)
      : todo = null,
        note = null;
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TodoRepository _todoRepository = TodoRepository();
  final NoteRepository _noteRepository = NoteRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final NotificationService _notifService = NotificationService();

  List<Todo> _todos = [];
  List<Note> _notes = [];
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<_CalendarItem>> _itemsByDate = {};

  // ===== FILTER STATE (dipindah dari TodoListPage) =====
  TodoCategory? _filterCategory;
  TodoPriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final todos = await _todoRepository.getAll();
    final notes = await _noteRepository.getAll();
    final transactions = await _transactionRepository.getAll();
    setState(() {
      _todos = todos;
      _notes = notes;
      _transactions = transactions;
      _itemsByDate = _groupByDate(todos, notes, transactions);
      _isLoading = false;
    });
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<DateTime, List<_CalendarItem>> _groupByDate(
      List<Todo> todos, List<Note> notes, List<Transaction> transactions) {
    final Map<DateTime, List<_CalendarItem>> map = {};

    void addItem(DateTime date, _CalendarItem item) {
      final key = _dateOnly(date);
      map.putIfAbsent(key, () => []);
      map[key]!.add(item);
    }

    for (final todo in todos) {
      addItem(todo.createdAt, _CalendarItem.fromTodo(todo));
      if (todo.dueDate != null) {
        addItem(todo.dueDate!, _CalendarItem.fromTodo(todo));
      }
    }
    for (final note in notes) {
      addItem(note.date, _CalendarItem.fromNote(note));
    }
    for (final transaction in transactions) {
      addItem(transaction.date, _CalendarItem.fromTransaction(transaction));
    }

    return map;
  }

  List<_CalendarItem> _getItemsForDay(DateTime day) {
    return _itemsByDate[_dateOnly(day)] ?? [];
  }

  List<Todo> _getTodosForDay(DateTime day) {
    final seen = <String>{};
    final result = <Todo>[];
    for (final item in _getItemsForDay(day)) {
      if (item.todo != null && seen.add(item.todo!.id)) {
        result.add(item.todo!);
      }
    }
    return result;
  }

  List<Note> _getNotesForDay(DateTime day) {
    return _getItemsForDay(day)
        .where((i) => i.note != null)
        .map((i) => i.note!)
        .toList();
  }

  List<Transaction> _getTransactionsForDay(DateTime day) {
    return _getItemsForDay(day)
        .where((i) => i.transaction != null)
        .map((i) => i.transaction!)
        .toList();
  }

  // Terapkan filter kategori & priority (dipindah dari TodoListPage)
  List<Todo> _applyFilter(List<Todo> todos) {
    return todos.where((todo) {
      if (_filterCategory != null && todo.category != _filterCategory) {
        return false;
      }
      if (_filterPriority != null && todo.priority != _filterPriority) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _addTransactionForSelectedDay() async {
    await showDialog(
      context: context,
      builder: (_) => AddEditTransactionDialog(
        initialDate: _selectedDay,
        onSave: (newTx) async {
          await _transactionRepository.insert(newTx);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _editTransaction(Transaction transaction) async {
    await showDialog(
      context: context,
      builder: (_) => AddEditTransactionDialog(
        transaction: transaction,
        onSave: (updated) async {
          await _transactionRepository.update(updated);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Transaksi'),
            content: Text('Yakin ingin menghapus "${transaction.title}"?'),
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
    if (!confirmed) return;
    await _transactionRepository.delete(transaction.id);
    await _loadData();
  }

  Future<void> _addNoteForSelectedDay() async {
    await showDialog(
      context: context,
      builder: (_) => AddEditNoteDialog(
        initialDate: _selectedDay,
        onSave: (newNote) async {
          await _noteRepository.insert(newNote);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _editNote(Note note) async {
    await showDialog(
      context: context,
      builder: (_) => AddEditNoteDialog(
        note: note,
        onSave: (updated) async {
          await _noteRepository.update(updated);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Note'),
            content: Text('Yakin ingin menghapus "${note.title}"?'),
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
    if (!confirmed) return;
    await _noteRepository.delete(note.id);
    await _loadData();
  }

  Future<void> _toggleTodo(Todo todo) async {
    await _todoRepository.toggleCompleted(todo.id, !todo.isCompleted);
    await _loadData();
  }

  Future<void> _editTodo(Todo todo) async {
    await showDialog(
      context: context,
      builder: (_) => AddEditDialog(
        todo: todo,
        onSave: (updated) async {
          await _todoRepository.update(updated);
          // Reschedule reminder (service sudah cancel yang lama di dalamnya)
          await _notifService.scheduleTodoReminders(updated);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteTodo(Todo todo) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Todo'),
            content: Text('Yakin ingin menghapus "${todo.title}"?'),
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
    if (!confirmed) return;
    await _todoRepository.delete(todo.id);
    await _loadData();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => FilterDialog(
        selectedCategory: _filterCategory,
        selectedPriority: _filterPriority,
        onCategoryChanged: (cat) => setState(() => _filterCategory = cat),
        onPriorityChanged: (p) => setState(() => _filterPriority = p),
        onReset: () => setState(() {
          _filterCategory = null;
          _filterPriority = null;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTodos = _applyFilter(_getTodosForDay(_selectedDay))
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    final selectedNotes = _getNotesForDay(_selectedDay);
    final selectedTransactions = _getTransactionsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Jurnal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesListPage()),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Todo List',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TodoListPage()),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Keuangan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinancePage()),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Active Filters
                if (_filterCategory != null || _filterPriority != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_filterCategory != null)
                          Chip(
                            label: Text(
                                TodoHelpers.getCategoryText(_filterCategory!)),
                            onDeleted: () =>
                                setState(() => _filterCategory = null),
                          ),
                        if (_filterPriority != null)
                          Chip(
                            label: Text(
                                TodoHelpers.getPriorityText(_filterPriority!)),
                            onDeleted: () =>
                                setState(() => _filterPriority = null),
                          ),
                      ],
                    ),
                  ),
                Card(
                  margin: const EdgeInsets.all(8),
                  child: TableCalendar<_CalendarItem>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: _getItemsForDay,
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 4,
                    ),
                    // marker custom: todo = merah, note = biru
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        final items = events;
                        if (items.isEmpty) return null;
                        final hasTodo = items.any((i) => i.todo != null);
                        final hasNote = items.any((i) => i.note != null);
                        final hasTransaction =
                            items.any((i) => i.transaction != null);
                        return Positioned(
                          bottom: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasTodo)
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasNote)
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasTransaction)
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.event_note, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatSelectedDate(_selectedDay),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: _addTransactionForSelectedDay,
                        icon: const Icon(Icons.attach_money, size: 18),
                        tooltip: 'Tambah Transaksi',
                        color: Colors.green[700],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _addNoteForSelectedDay,
                        icon: const Icon(Icons.note_add, size: 16),
                        label: const Text('Note'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: (selectedTodos.isEmpty &&
                          selectedNotes.isEmpty &&
                          selectedTransactions.isEmpty)
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (selectedTransactions.isNotEmpty) ...[
                                _sectionLabel(
                                    '💰 Transaksi (${selectedTransactions.length})'),
                                ...selectedTransactions
                                    .map((t) => TransactionCard(
                                          transaction: t,
                                          onTap: () => _editTransaction(t),
                                          onDelete: () => _deleteTransaction(t),
                                        )),
                                const SizedBox(height: 8),
                              ],
                              if (selectedNotes.isNotEmpty) ...[
                                _sectionLabel(
                                    '📓 Note (${selectedNotes.length})'),
                                ...selectedNotes.map((note) => NoteCard(
                                      note: note,
                                      onTap: () => _editNote(note),
                                      onDelete: () => _deleteNote(note),
                                    )),
                                const SizedBox(height: 8),
                              ],
                              if (selectedTodos.isNotEmpty) ...[
                                _sectionLabel(
                                    '📝 Todo (${selectedTodos.length})'),
                                ...selectedTodos.map((todo) => TodoCard(
                                      todo: todo,
                                      onTap: () => _editTodo(todo),
                                      onToggle: () => _toggleTodo(todo),
                                      onDelete: () => _deleteTodo(todo),
                                    )),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada todo, note, atau transaksi di tanggal ini',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
