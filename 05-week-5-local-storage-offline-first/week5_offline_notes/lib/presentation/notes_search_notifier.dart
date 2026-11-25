import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/providers.dart';
import '../domain/search_notes.dart';

/// State untuk halaman catatan yang menampung semua catatan asli
/// sekaligus query pencarian aktif.
class NotesSearchState {
  const NotesSearchState({this.allNotes = const [], this.query = ''});

  final List<Note> allNotes;
  final String query;

  /// Daftar catatan setelah difilter oleh use case [filterNotes].
  List<Note> get filtered => filterNotes(allNotes, query);

  NotesSearchState copyWith({List<Note>? allNotes, String? query}) {
    return NotesSearchState(
      allNotes: allNotes ?? this.allNotes,
      query: query ?? this.query,
    );
  }
}

/// Notifier yang mengelola state pencarian catatan.
/// Mengonsumsi [noteRepositoryProvider] untuk mengambil semua catatan dari SQLite,
/// lalu menyerahkan logika filter ke use case domain [filterNotes].
class NotesSearchNotifier extends AsyncNotifier<NotesSearchState> {
  @override
  Future<NotesSearchState> build() async {
    final repo = ref.watch(noteRepositoryProvider);
    final notes = await repo.fetchNotes();
    return NotesSearchState(allNotes: notes);
  }

  /// Memperbarui query pencarian dan memicu rebuild UI secara reaktif.
  void updateQuery(String query) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(query: query));
  }

  /// Memuat ulang semua catatan dari SQLite (dipakai setelah add/delete).
  Future<void> reload() async {
    final repo = ref.read(noteRepositoryProvider);
    final notes = await repo.fetchNotes();
    final current = state.value;
    state = AsyncValue.data(
      NotesSearchState(allNotes: notes, query: current?.query ?? ''),
    );
  }
}

final notesSearchProvider =
    AsyncNotifierProvider<NotesSearchNotifier, NotesSearchState>(
      NotesSearchNotifier.new,
    );
