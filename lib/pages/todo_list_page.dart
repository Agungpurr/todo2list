// lib/pages/todo_list_page.dart

import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';
import '../services/notification_service.dart';
import '../utils/todo_helpers.dart';
import '../widgets/add_edit_dialog.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/info_chip.dart';
import '../widgets/stat_card.dart';
import '../widgets/todo_card.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TodoRepository _repository = TodoRepository();
  final NotificationService _notifService = NotificationService();

  List<Todo> _todos = [];
  bool _isLoading = true;

  String _searchQuery = '';
  TodoCategory? _filterCategory;
  TodoPriority? _filterPriority;
  bool _showCompletedOnly = false;
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTodos();
    // Reschedule semua reminder todo + refresh isi daily reminder setiap
    // kali halaman utama dibuka. Ini fallback tambahan selain boot receiver,
    // supaya kalau ada reminder yang ke-skip (misal HP mati lama), tetap
    // ter-reschedule saat user buka app lagi.
    _notifService.rescheduleAllTodoReminders();
    _notifService.refreshDailyReminderIfEnabled();
  }

  // ===== DATA LOADING =====
  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    final todos = await _repository.getAll();

    // Insert demo data if empty
    if (todos.isEmpty) {
      await _insertDemoData();
      final freshTodos = await _repository.getAll();
      setState(() {
        _todos = freshTodos;
        _isLoading = false;
      });
    } else {
      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    }
  }

  Future<void> _insertDemoData() async {
    final demoTodos = [
      Todo(
        id: '1',
        title: 'Belajar Flutter',
        description: 'Mempelajari widget dan state management',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().add(const Duration(days: 3)),
        priority: TodoPriority.high,
        category: TodoCategory.work,
        tags: ['coding', 'flutter'],
      ),
      Todo(
        id: '2',
        title: 'Belanja Bulanan',
        description: 'Beli beras, minyak, dan sayuran',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        priority: TodoPriority.medium,
        category: TodoCategory.shopping,
        tags: ['groceries'],
      ),
      Todo(
        id: '3',
        title: 'Olahraga Pagi',
        description: 'Jogging 30 menit',
        createdAt: DateTime.now(),
        dueDate: DateTime.now(),
        priority: TodoPriority.high,
        category: TodoCategory.health,
        tags: ['health', 'morning'],
        isCompleted: true,
      ),
    ];

    for (final todo in demoTodos) {
      await _repository.insert(todo);
    }
  }

  // ===== CRUD OPERATIONS =====
  Future<void> _addTodo(Todo todo) async {
    await _repository.insert(todo);
    await _notifService.scheduleTodoReminders(todo);
    await _loadTodos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateTodo(Todo todo) async {
    await _repository.update(todo);
    // Reschedule (otomatis cancel yang lama dulu di dalam service)
    await _notifService.scheduleTodoReminders(todo);
    await _loadTodos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    final confirmed = await _showDeleteConfirm(todo);
    if (!confirmed) return;

    await _repository.delete(todo.id);
    await _notifService.cancelTodoReminders(todo.id);
    await _loadTodos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo berhasil dihapus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    final newCompleted = !todo.isCompleted;
    await _repository.toggleCompleted(todo.id, newCompleted);

    // Kalau ditandai selesai, batalkan reminder yang masih nyangkut.
    // Kalau dibatalkan selesainya lagi, dan masih punya dueDate, reminder
    // dijadwalkan ulang.
    if (newCompleted) {
      await _notifService.cancelTodoReminders(todo.id);
    } else if (todo.dueDate != null) {
      final updated = todo.copyWith(isCompleted: false);
      await _notifService.scheduleTodoReminders(updated);
    }

    await _loadTodos();
  }

  // ===== FILTERING =====
  List<Todo> get _filteredTodos {
    return _todos.where((todo) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = todo.title.toLowerCase().contains(q) ||
            todo.description.toLowerCase().contains(q) ||
            todo.tags.any((tag) => tag.toLowerCase().contains(q));
        if (!match) return false;
      }

      if (_filterCategory != null && todo.category != _filterCategory) {
        return false;
      }
      if (_filterPriority != null && todo.priority != _filterPriority) {
        return false;
      }
      if (_showCompletedOnly && !todo.isCompleted) return false;
      if (_showActiveOnly && todo.isCompleted) return false;

      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return b.priority.index.compareTo(a.priority.index);
      });
  }

  // ===== DIALOGS =====
  void _showAddEditDialog({Todo? todo}) {
    showDialog(
      context: context,
      builder: (_) => AddEditDialog(
        todo: todo,
        onSave: (newTodo) {
          if (todo == null) {
            _addTodo(newTodo);
          } else {
            _updateTodo(newTodo);
          }
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirm(Todo todo) async {
    return await showDialog<bool>(
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

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    final activeTodos = _todos.where((t) => !t.isCompleted).length;
    final completedTodos = _todos.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        // Tombol kembali otomatis muncul (leading) karena halaman ini
        // diakses lewat Navigator.push dari CalendarPage.
        title: const Text('📝 Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _showCompletedOnly = value == 'completed';
                _showActiveOnly = value == 'active';
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('Semua')),
              const PopupMenuItem(value: 'active', child: Text('Aktif')),
              const PopupMenuItem(value: 'completed', child: Text('Selesai')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari todo...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Aktif',
                          value: activeTodos.toString(),
                          color: Colors.blue,
                          icon: Icons.pending_actions,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Selesai',
                          value: completedTodos.toString(),
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Total',
                          value: _todos.length.toString(),
                          color: Colors.orange,
                          icon: Icons.list_alt,
                        ),
                      ),
                    ],
                  ),
                ),

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

                // Todo List
                Expanded(
                  child: _filteredTodos.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadTodos,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredTodos.length,
                            itemBuilder: (context, index) {
                              final todo = _filteredTodos[index];
                              return TodoCard(
                                todo: todo,
                                onTap: () => _showAddEditDialog(todo: todo),
                                onToggle: () => _toggleTodo(todo),
                                onDelete: () => _deleteTodo(todo),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Todo'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _todos.isEmpty ? 'Belum ada todo' : 'Tidak ada todo yang cocok',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          if (_todos.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}
