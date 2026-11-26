import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/debouncer.dart';
import '../data/local/note.dart';
import '../data/providers.dart';
import '../presentation/notes_search_notifier.dart';
import 'ai_chat_page.dart';

/// Halaman catatan offline dengan fitur pencarian dan optimasi performa (Week 11).
///
/// Optimasi yang diterapkan:
/// 1. [Debouncer] (300ms) untuk mencegah komputasi filter berulang pada setiap ketukan keyboard.
/// 2. [ValueListenableBuilder] untuk tombol clear search agar mengetik tidak me-rebuild seluruh tree halaman.
/// 3. [RepaintBoundary] pada [NoteItemTile] untuk mengisolasi render layer saat scrolling.
/// 4. Ekstraksi [_AddNoteDialog] dengan pembuangan ([dispose]) controller yang aman guna mencegah memory leak.
/// 5. Granular [Consumer] untuk badge dirty count agar perubahan sync tidak me-rebuild body catatan.
class SearchNotesPage extends ConsumerStatefulWidget {
  const SearchNotesPage({super.key});

  @override
  ConsumerState<SearchNotesPage> createState() => _SearchNotesPageState();
}

class _SearchNotesPageState extends ConsumerState<SearchNotesPage> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (mounted) {
        ref.read(notesSearchProvider.notifier).updateQuery(query);
      }
    });
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddNoteDialog(
        onSave: (title, body) async {
          final repo = ref.read(noteRepositoryProvider);
          await repo.addNote(title: title, body: body);
          ref.invalidate(dirtyCountProvider);
          await ref.read(notesSearchProvider.notifier).reload();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // Tombol Buka Asisten AI (Week 10)
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            tooltip: 'Tanya Asisten AI',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatPage()),
              );
            },
          ),
          // Granular Consumer untuk badge dirty/synced agar tidak me-rebuild seluruh AppBar/Body
          const _DirtyCountBadge(),
          // Tombol Sync
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronkan catatan',
            onPressed: () async {
              final syncFn = ref.read(syncControllerProvider);
              final count = await syncFn();
              await ref.read(notesSearchProvider.notifier).reload();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count catatan berhasil disinkronkan!'),
                  ),
                );
              }
            },
          ),
        ],
        // Search bar di bawah AppBar title dengan isolasi rebuild menggunakan ValueListenableBuilder
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari catatan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(notesSearchProvider.notifier)
                                  .updateQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                );
              },
            ),
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final searchAsync = ref.watch(notesSearchProvider);

          return searchAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (state) {
              final notes = state.filtered;
              final hasQuery = state.query.trim().isNotEmpty;

              if (notes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasQuery ? Icons.search_off : Icons.note_add_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hasQuery
                            ? 'Tidak ada catatan yang cocok dengan "${state.query}"'
                            : 'Belum ada catatan.\nKlik + untuk membuat.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  // Isolasi paint layer setiap note item dengan RepaintBoundary
                  return RepaintBoundary(
                    child: NoteItemTile(
                      key: ValueKey(note.id ?? index),
                      note: note,
                      onDelete: () async {
                        if (note.id != null) {
                          final repo = ref.read(noteRepositoryProvider);
                          await repo.deleteNote(note.id!);
                          ref.invalidate(dirtyCountProvider);
                          await ref.read(notesSearchProvider.notifier).reload();
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Widget granular untuk Badge status dirty count.
class _DirtyCountBadge extends ConsumerWidget {
  const _DirtyCountBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dirtyAsync = ref.watch(dirtyCountProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: dirtyAsync.when(
        data: (count) => Chip(
          avatar: CircleAvatar(
            backgroundColor: count > 0 ? Colors.orange : Colors.green,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
          label: Text(count > 0 ? 'Dirty' : 'Synced'),
        ),
        loading: () => const SizedBox(),
        error: (_, _) => const SizedBox(),
      ),
    );
  }
}

/// Item list catatan yang diekstrak menjadi widget mandiri untuk mengoptimalkan rebuild.
class NoteItemTile extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const NoteItemTile({super.key, required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        note.dirty ? Icons.cloud_off : Icons.cloud_done,
        color: note.dirty ? Colors.orange : Colors.green,
        size: 20,
      ),
      title: Text(
        note.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: note.body.isNotEmpty ? Text(note.body) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }
}

/// Dialog tambah catatan dengan pengelolaan lifecycle controller yang aman dari memory leak.
class _AddNoteDialog extends StatefulWidget {
  final Future<void> Function(String title, String body) onSave;

  const _AddNoteDialog({required this.onSave});

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _titleError;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan Baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Judul',
              errorText: _titleError,
            ),
            onChanged: (_) {
              if (_titleError != null) {
                setState(() => _titleError = null);
              }
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Isi Catatan'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) {
                    setState(() => _titleError = 'Judul tidak boleh kosong');
                    return;
                  }
                  final navigator = Navigator.of(context);
                  setState(() => _isSaving = true);
                  await widget.onSave(title, _bodyController.text.trim());
                  if (!mounted) return;
                  navigator.pop();
                },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
