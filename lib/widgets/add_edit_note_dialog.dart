// lib/widgets/add_edit_note_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:uuid/uuid.dart';

import '../models/note.dart';

const List<String> _moodOptions = [
  '😄',
  '🙂',
  '😐',
  '😢',
  '😡',
  '😴',
  '🤩',
  '😰'
];

class AddEditNoteDialog extends StatefulWidget {
  final Note? note;
  final DateTime? initialDate; // dipakai saat tambah note dari CalendarPage
  final void Function(Note note) onSave;

  const AddEditNoteDialog({
    Key? key,
    this.note,
    this.initialDate,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _tagController;
  late quill.QuillController _quillController;
  late DateTime _selectedDate;
  String? _selectedMood;
  List<String> _tags = [];

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;

    _titleController = TextEditingController(text: note?.title ?? '');
    _tagController = TextEditingController();
    _selectedDate = note?.date ?? widget.initialDate ?? DateTime.now();
    _selectedMood = note?.mood;
    _tags = List<String>.from(note?.tags ?? []);

    _quillController = note != null
        ? quill.QuillController(
            document: note.toDocument(),
            selection: const TextSelection.collapsed(offset: 0),
          )
        : quill.QuillController.basic();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _save() {
    final title = _titleController.text.trim();
    final plainText = _quillController.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul atau isi note tidak boleh kosong')),
      );
      return;
    }

    final now = DateTime.now();
    final note = Note.fromDocument(
      id: widget.note?.id ?? const Uuid().v4(),
      title: title.isEmpty ? '(Tanpa judul)' : title,
      document: _quillController.document,
      mood: _selectedMood,
      tags: _tags,
      date: _selectedDate,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(note);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;

    // Saat keyboard terbuka, sisa ruang yang tersedia berkurang sebesar
    // tinggi keyboard. Tanpa ini, Dialog tidak resize otomatis dan
    // kontennya akan overflow ke belakang keyboard.
    final availableHeight = screenHeight - keyboardHeight;
    final maxDialogHeight =
        (availableHeight * 0.9).clamp(200.0, screenHeight * 0.9);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: maxDialogHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header (fixed, tidak ikut scroll) =====
              Row(
                children: [
                  Text(
                    _isEditing ? 'Edit Note' : 'Tambah Note',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ===== Konten scrollable =====
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tanggal
                      InkWell(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit,
                                size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Judul
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Judul note...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // Mood picker
                      Text('Mood hari ini',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _moodOptions.map((mood) {
                          final selected = _selectedMood == mood;
                          return InkWell(
                            onTap: () => setState(() {
                              _selectedMood = selected ? null : mood;
                            }),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(mood,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Quill toolbar + editor
                      Text('Isi jurnal',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            quill.QuillSimpleToolbar(
                              controller: _quillController,
                              config: const quill.QuillSimpleToolbarConfig(
                                showFontFamily: false,
                                showFontSize: false,
                                showSubscript: false,
                                showSuperscript: false,
                                showSearchButton: false,
                                showClearFormat: false,
                                showCodeBlock: false,
                                showQuote: false,
                                showIndent: false,
                                showLink: false,
                                multiRowsDisplay: false,
                              ),
                            ),
                            const Divider(height: 1),
                            // Tinggi editor menyesuaikan: lebih kecil saat
                            // keyboard terbuka supaya tidak overflow.
                            SizedBox(
                              height: keyboardOpen ? 90 : 160,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: quill.QuillEditor.basic(
                                  controller: _quillController,
                                  config: const quill.QuillEditorConfig(
                                    placeholder: 'Tulis jurnal kamu di sini...',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tags
                      Text('Tags',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ..._tags.map((tag) => Chip(
                                label: Text(tag,
                                    style: const TextStyle(fontSize: 12)),
                                onDeleted: () => _removeTag(tag),
                                visualDensity: VisualDensity.compact,
                              )),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: '+ tambah tag',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 13),
                              onSubmitted: _addTag,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ===== Footer (fixed, tidak ikut scroll) =====
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
