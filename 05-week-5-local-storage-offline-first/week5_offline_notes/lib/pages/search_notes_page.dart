import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../presentation/notes_search_notifier.dart';
import 'ai_chat_page.dart';

/// Halaman catatan offline dengan fitur pencarian (Week 9 AI-Assisted).
/// Menggantikan [NotesPage] versi lama sebagai halaman utama.
class SearchNotesPage extends ConsumerStatefulWidget {
  const SearchNotesPage({super.key});

  @override
  ConsumerState<SearchNotesPage> createState() => _SearchNotesPageState();
}

class _SearchNotesPageState extends ConsumerState<SearchNotesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? titleError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Catatan Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul',
                  errorText: titleError,
                ),
                onChanged: (_) {
                  if (titleError != null) setState(() => titleError = null);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Isi Catatan'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  setState(() => titleError = 'Judul tidak boleh kosong');
                  return;
                }
                final repo = ref.read(noteRepositoryProvider);
                await repo.addNote(
                  title: titleController.text.trim(),
                  body: bodyController.text.trim(),
                );
                ref.invalidate(dirtyCountProvider);
                await ref.read(notesSearchProvider.notifier).reload();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(notesSearchProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);

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
          // Badge dirty/synced
          Padding(
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
          ),
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
        // Search bar di bawah AppBar title
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
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
              onChanged: (value) {
                setState(() {}); // rebuild tombol clear
                ref.read(notesSearchProvider.notifier).updateQuery(value);
              },
            ),
          ),
        ),
      ),
      body: searchAsync.when(
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
                  onPressed: () async {
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
