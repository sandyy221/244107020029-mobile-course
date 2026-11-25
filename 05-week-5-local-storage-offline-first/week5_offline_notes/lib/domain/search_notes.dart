import 'package:week5_offline_notes/data/local/note.dart';

/// [Domain Layer] Use case murni untuk memfilter daftar catatan berdasarkan query.
///
/// Fungsi ini tidak mengimpor Flutter, Dio, atau SQLite — hanya Dart murni.
/// Hal ini memastikan layer domain bebas dari dependensi infrastruktur
/// sesuai prinsip Dependency Rule Clean Architecture.
///
/// Aturan filter:
///   - Query kosong atau null → kembalikan semua catatan (tidak ada filter).
///   - Query trim lalu bandingkan case-insensitive terhadap [Note.title] dan [Note.body].
///   - Cocok jika judul ATAU isi catatan mengandung query.
List<Note> filterNotes(List<Note> notes, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return notes;
  final lower = trimmed.toLowerCase();
  return notes.where((n) {
    return n.title.toLowerCase().contains(lower) ||
        n.body.toLowerCase().contains(lower);
  }).toList();
}
