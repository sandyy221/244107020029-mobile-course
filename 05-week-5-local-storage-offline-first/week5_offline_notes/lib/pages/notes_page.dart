// lib/pages/notes_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca jumlah catatan kotor untuk Badge
    final dirtyCountAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // Badge Indikator Catatan Kotor
          dirtyCountAsync.when(
            data: (count) => Chip(
              label: Text('Dirty: $count'),
              backgroundColor: count > 0 ? Colors.orange : Colors.green,
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          
          // Tombol Pemanggil syncNotes
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final syncFn = ref.read(syncControllerProvider);
              final count = await syncFn();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count catatan berhasil disinkronkan!')),
                );
              }
            },
          ),
        ],
      ),
      body: const Center(child: Text('Daftar Catatan')),
    );
  }
}