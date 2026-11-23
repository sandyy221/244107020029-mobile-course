import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/validate.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

void main() {
  testWidgets('Smoke test verifikasi UI NotesPage dan validator catatan', (
    WidgetTester tester,
  ) async {
    // Verifikasi logika validator
    expect(NoteValidator.validateTitle(''), 'Judul tidak boleh kosong');
    expect(NoteValidator.validateTitle('Catatan Penting'), isNull);

    // Build widget dengan ProviderScope dan override provider async
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesListProvider.overrideWith((ref) async => []),
          dirtyCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan halaman NotesPage ter-render dengan judul dan tombol add
    expect(find.text('Catatan Offline'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(
      find.text('Belum ada catatan. Klik + untuk membuat.'),
      findsOneWidget,
    );
  });
}
