import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/domain/search_notes.dart';
import 'package:week5_offline_notes/pages/search_notes_page.dart';
import 'package:week5_offline_notes/presentation/notes_search_notifier.dart';

void main() {
  group('filterNotes - Unit Test Use Case Domain (Week 9 AI-Assisted)', () {
    final sampleNotes = [
      Note(
        id: 1,
        title: 'Belanja Bulanan',
        body: 'Beli susu, telur, dan roti gandum',
        updatedAt: DateTime(2026, 10, 1),
      ),
      Note(
        id: 2,
        title: 'Tugas Kuliah Mobile',
        body: 'Selesaikan Codelab Minggu 9 Riverpod',
        updatedAt: DateTime(2026, 10, 2),
      ),
      Note(
        id: 3,
        title: 'Daftar Rencana Liburan',
        body: 'Pergi ke pantai atau gunung',
        updatedAt: DateTime(2026, 10, 3),
      ),
    ];

    test('filter abaikan huruf besar/kecil (case-insensitive test)', () {
      final resultLower = filterNotes(sampleNotes, 'belanja');
      expect(resultLower, hasLength(1));
      expect(resultLower.first.title, 'Belanja Bulanan');

      final resultUpper = filterNotes(sampleNotes, 'BELANJA');
      expect(resultUpper, hasLength(1));
      expect(resultUpper.first.title, 'Belanja Bulanan');

      final resultMixed = filterNotes(sampleNotes, 'bElAnJa');
      expect(resultMixed, hasLength(1));
    });

    test('query kosong atau hanya spasi kembalikan semua catatan', () {
      final resultEmpty = filterNotes(sampleNotes, '');
      expect(resultEmpty, hasLength(3));

      final resultSpaces = filterNotes(sampleNotes, '     ');
      expect(resultSpaces, hasLength(3));
    });

    test('query tak cocok kembalikan list kosong (empty state trigger)', () {
      final result = filterNotes(sampleNotes, 'zzz-tak-ada-di-catatan');
      expect(result, isEmpty);
    });

    test('pencarian cocok pada isi catatan (body match)', () {
      final result = filterNotes(sampleNotes, 'roti');
      expect(result, hasLength(1));
      expect(result.first.title, 'Belanja Bulanan');
    });

    test('pencarian cocok sebagian kata (substring match)', () {
      final result = filterNotes(sampleNotes, 'Kuliah');
      expect(result, hasLength(1));
      expect(result.first.title, 'Tugas Kuliah Mobile');
    });

    test('menangani list catatan kosong tanpa crash', () {
      final result = filterNotes([], 'apapun');
      expect(result, isEmpty);
    });
  });

  group('SearchNotesPage - Widget Test Empty State & Filter UI', () {
    testWidgets('menampilkan empty state umum ketika tidak ada catatan', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSearchProvider.overrideWith(() => _FakeSearchNotifier([])),
            dirtyCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: SearchNotesPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Catatan Offline'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Belum ada catatan.\nKlik + untuk membuat.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
    });

    testWidgets('menampilkan empty state pencarian saat query tidak cocok', (
      tester,
    ) async {
      final notes = [
        Note(
          id: 1,
          title: 'Catatan Penting',
          body: 'Isi rahasia',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSearchProvider.overrideWith(
              () => _FakeSearchNotifier(notes, query: 'xyz'),
            ),
            dirtyCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: SearchNotesPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(
        find.text('Tidak ada catatan yang cocok dengan "xyz"'),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan list catatan saat ada data cocok', (tester) async {
      final notes = [
        Note(
          id: 1,
          title: 'Belajar Flutter AI',
          body: 'Praktikum Minggu 9',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSearchProvider.overrideWith(() => _FakeSearchNotifier(notes)),
            dirtyCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: SearchNotesPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Belajar Flutter AI'), findsOneWidget);
      expect(find.text('Praktikum Minggu 9'), findsOneWidget);
    });
  });
}

class _FakeSearchNotifier extends NotesSearchNotifier {
  _FakeSearchNotifier(this.initialNotes, {this.query = ''});

  final List<Note> initialNotes;
  final String query;

  @override
  Future<NotesSearchState> build() async {
    return NotesSearchState(allNotes: initialNotes, query: query);
  }
}
