import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';
import '../data/local/note.dart';

// Provider untuk mengambil daftar catatan secara async
final notesListProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return await repo.fetchNotes();
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  // Modal / Dialog Tambah Catatan
  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Isi Catatan'),
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
              if (titleController.text.isNotEmpty) {
                final repo = ref.read(noteRepositoryProvider);
                await repo.addNote(
                  title: titleController.text,
                  body: bodyController.text,
                );
                // Refresh list & dirty count setelah tambah data
                ref.invalidate(notesListProvider);
                ref.invalidate(dirtyCountProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // 1. Badge Indikator Catatan Dirty
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: dirtyAsync.when(
              data: (count) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: count > 0 ? Colors.orange : Colors.green,
                  child: Text('$count', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
                label: Text(count > 0 ? 'Dirty' : 'Synced'),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
          // 2. Tombol Sync
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final syncFn = ref.read(syncControllerProvider);
              final count = await syncFn();
              ref.invalidate(notesListProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count catatan berhasil disinkronkan!')),
                );
              }
            },
          ),
        ],
      ),
      // 3. Body: Menampilkan List Catatan dari SQLite
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('Belum ada catatan. Klik + untuk membuat.'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(note.body),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (note.dirty)
                      const Icon(Icons.cloud_off, color: Colors.orange, size: 18)
                    else
                      const Icon(Icons.cloud_done, color: Colors.green, size: 18),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        if (note.id != null) {
                          final repo = ref.read(noteRepositoryProvider);
                          await repo.deleteNote(note.id!);
                          ref.invalidate(notesListProvider);
                          ref.invalidate(dirtyCountProvider);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      // 4. Tombol Tambah Catatan
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}