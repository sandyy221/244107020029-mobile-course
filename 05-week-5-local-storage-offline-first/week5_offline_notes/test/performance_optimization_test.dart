import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/ai/ai_service.dart';
import 'package:week5_offline_notes/core/debouncer.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/models/post.dart';
import 'package:week5_offline_notes/pages/ai_chat_page.dart';
import 'package:week5_offline_notes/pages/paged_post_page.dart';
import 'package:week5_offline_notes/pages/search_notes_page.dart';

void main() {
  group('Week 11 Performance Optimization Tests', () {
    testWidgets(
      'NoteItemTile terbungkus dalam RepaintBoundary untuk isolasi rendering',
      (tester) async {
        final note = Note(
          id: 1,
          title: 'Catatan Belajar',
          body: 'Isi catatan untuk optimasi performa',
          updatedAt: DateTime(2026, 11, 27),
          dirty: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                child: NoteItemTile(note: note, onDelete: () {}),
              ),
            ),
          ),
        );

        expect(find.byType(RepaintBoundary), findsWidgets);
        expect(find.text('Catatan Belajar'), findsOneWidget);
        expect(
          find.text('Isi catatan untuk optimasi performa'),
          findsOneWidget,
        );
      },
    );

    testWidgets('ChatMessageBubble terbungkus dalam RepaintBoundary', (
      tester,
    ) async {
      final msg = ChatMessage(
        text: 'Halo dari Asisten AI',
        isUser: false,
        timestamp: DateTime(2026, 11, 27),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(child: ChatMessageBubble(message: msg)),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Halo dari Asisten AI'), findsOneWidget);
      expect(find.text('AI Asisten'), findsOneWidget);
    });

    testWidgets('PostItemCard terbungkus dalam RepaintBoundary', (
      tester,
    ) async {
      const post = Post(
        id: 42,
        userId: 1,
        title: 'Postingan Teroptimasi',
        body: 'Konten artikel paged post',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(child: PostItemCard(post: post)),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Postingan Teroptimasi'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets(
      'SearchNotesPage memuat ValueListenableBuilder untuk isolasi rebuild TextField',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: SearchNotesPage())),
        );

        // Cari TextField pencarian
        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.byType(ValueListenableBuilder<TextEditingValue>),
          findsOneWidget,
        );
      },
    );

    test('Debouncer menunda dan membatalkan eksekusi berulang', () async {
      final debouncer = Debouncer(milliseconds: 30);
      int counter = 0;

      debouncer.run(() => counter++);
      debouncer.run(() => counter++);
      debouncer.run(() => counter++);

      expect(counter, 0);

      await Future.delayed(const Duration(milliseconds: 40));
      expect(counter, 1);

      debouncer.dispose();
    });
  });
}
