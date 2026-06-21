// lib/pages/notes_list_page.dart

import 'package:flutter/material.dart';

import '../models/note.dart';
import '../repositories/note_repository.dart';
import '../widgets/add_edit_note_dialog.dart';
import '../widgets/note_card.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({Key? key}) : super(key: key);

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NoteRepository _repository = NoteRepository();

  List<Note> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterTag;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = _searchQuery.isEmpty
        ? await _repository.getAll()
        : await _repository.search(_searchQuery);
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  List<Note> get _filteredNotes {
    if (_filterTag == null) return _notes;
    return _notes.where((n) => n.tags.contains(_filterTag)).toList();
  }

  List<String> get _allTags {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  Future<void> _addOrEditNote({Note? note}) async {
    await showDialog(
      context: context,
      builder: (_) => AddEditNoteDialog(
        note: note,
        onSave: (newNote) async {
          if (note == null) {
            await _repository.insert(newNote);
          } else {
            await _repository.update(newNote);
          }
          await _loadNotes();
        },
      ),
    );
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Note'),
            content: Text(
                'Yakin ingin menghapus "${note.title}"? Tindakan ini tidak bisa dibatalkan.'),
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
    await _repository.delete(note.id);
    await _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note berhasil dihapus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📓 Jurnal'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _loadNotes();
              },
              decoration: InputDecoration(
                hintText: 'Cari note...',
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
          if (_allTags.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: const Text('Semua'),
                      selected: _filterTag == null,
                      onSelected: (_) => setState(() => _filterTag = null),
                    ),
                  ),
                  ..._allTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(tag),
                          selected: _filterTag == tag,
                          onSelected: (_) => setState(() {
                            _filterTag = _filterTag == tag ? null : tag;
                          }),
                        ),
                      )),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            return NoteCard(
                              note: note,
                              onTap: () => _addOrEditNote(note: note),
                              onDelete: () => _deleteNote(note),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditNote(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Note'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _notes.isEmpty ? 'Belum ada note' : 'Tidak ada note yang cocok',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          if (_notes.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menulis jurnal',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}
