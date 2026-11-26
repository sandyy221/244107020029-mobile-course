import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week5_offline_notes/ai/ai_service.dart';
import 'package:week5_offline_notes/pages/ai_chat_page.dart';

void main() {
  group('AiService - Unit Test Integrasi & Privasi (Week 10)', () {
    test('sanitasi prompt berhasil menyamarkan nomor telepon sensitif', () {
      final aiService = AiService();
      final rawPrompt =
          'Tolong simpan nomor penting 081234567890 untuk catatan ini';
      final sanitized = aiService.sanitizePrompt(rawPrompt);

      expect(sanitized, contains('[NOMOR_DISAMARKAN]'));
      expect(sanitized.contains('081234567890'), isFalse);
    });

    test(
      'fallback offline menghasilkan respons terstruktur saat tanpa API key',
      () async {
        final aiService = AiService();
        final result = await aiService.askWithFallback(
          'Bagaimana cara ringkas catatan?',
        );

        expect(result.isUser, isFalse);
        expect(result.isOfflineFallback, isTrue);
        expect(result.text, contains('merangkum catatan'));
        expect(result.text, contains('Mode Offline'));
      },
    );

    test('fallback offline memberikan saran judul produktif', () async {
      final aiService = AiService();
      final result = await aiService.askWithFallback('Beri saya ide judul');

      expect(result.text, contains('Saran format judul'));
      expect(result.isOfflineFallback, isTrue);
    });

    test('fallback offline memberikan tips belajar mobile', () async {
      final aiService = AiService();
      final result = await aiService.askWithFallback(
        'Tips belajar mobile programming',
      );

      expect(result.text, contains('Clean Architecture'));
      expect(result.isOfflineFallback, isTrue);
    });

    test('memproses respons sukses dari mock Gemini API (HTTP 200)', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'dummy_key_123');
        final responseBody = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Ini adalah jawaban cerdas dari model Gemini 1.5 Flash.',
                  },
                ],
              },
            },
          ],
        };
        return http.Response(jsonEncode(responseBody), 200);
      });

      // Secure storage mock in memory
      FlutterSecureStorage.setMockInitialValues({
        'ai_api_key': 'dummy_key_123',
      });

      final aiService = AiService(client: mockClient);
      final responseText = await aiService.ask('Halo Gemini');

      expect(
        responseText,
        'Ini adalah jawaban cerdas dari model Gemini 1.5 Flash.',
      );
    });

    test(
      'melemparkan exception ketika API key belum diset saat memanggil ask()',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        final aiService = AiService();

        expect(
          () => aiService.ask('Pertanyaan tanpa kunci'),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('AiChatPage - Widget Test Antarmuka Chat & Dialog', () {
    testWidgets('menampilkan pesan sapaan awal, suggestions, dan input bar', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AiChatPage())),
      );

      await tester.pumpAndSettle();

      // Memastikan elemen utama ter-render
      expect(find.text('Asisten AI Catatan'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Ringkas catatanku'), findsOneWidget);
      expect(find.text('Tips belajar Flutter'), findsOneWidget);
    });

    testWidgets('membuka dialog pengaturan API Key saat ikon kunci ditekan', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AiChatPage())),
      );

      await tester.pumpAndSettle();

      // Klik tombol ikon kunci di AppBar
      await tester.tap(find.byIcon(Icons.key));
      await tester.pumpAndSettle();

      // Dialog terbuka
      expect(find.text('Pengaturan API Key'), findsOneWidget);
      expect(find.text('Google Gemini API Key'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Tutup dialog
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan API Key'), findsNothing);
    });

    testWidgets(
      'mengirim pesan via quick suggestion chip dan menerima respons',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: AiChatPage())),
        );

        await tester.pumpAndSettle();

        // Klik chip 'Tips belajar Flutter'
        await tester.tap(find.text('Tips belajar Flutter'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verifikasi pesan user muncul (pada chip dan pada bubble chat)
        expect(find.text('Tips belajar Flutter'), findsNWidgets(2));
        // Verifikasi respons offline muncul
        expect(
          find.textContaining('Tips Belajar Pemrograman Mobile'),
          findsOneWidget,
        );
      },
    );
  });
}
