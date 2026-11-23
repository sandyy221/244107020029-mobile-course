import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/validate.dart';

void main() {
  group('NoteValidator - Unit Test Validasi Catatan', () {
    test('mengembalikan pesan error ketika judul adalah null', () {
      final result = NoteValidator.validateTitle(null);
      expect(result, isNotNull);
      expect(result, 'Judul tidak boleh kosong');
    });

    test('mengembalikan pesan error ketika judul adalah string kosong', () {
      final result = NoteValidator.validateTitle('');
      expect(result, isNotNull);
      expect(result, 'Judul tidak boleh kosong');
    });

    test('mengembalikan pesan error ketika judul hanya berisi spasi atau whitespace', () {
      final result = NoteValidator.validateTitle('     ');
      expect(result, isNotNull);
      expect(result, 'Judul tidak boleh kosong');
    });

    test(
      'mengembalikan pesan error ketika judul melebihi batas 100 karakter',
      () {
        final longTitle = 'a' * 101;
        final result = NoteValidator.validateTitle(longTitle);
        expect(result, isNotNull);
        expect(result, contains('maksimal 100 karakter'));
      },
    );

    test('mengembalikan null jika judul valid', () {
      final result = NoteValidator.validateTitle('Rencana Praktikum Mobile');
      expect(result, isNull);
    });

    test('validasi body mengembalikan null untuk input kosong atau normal', () {
      expect(NoteValidator.validateBody(''), isNull);
      expect(NoteValidator.validateBody('Deskripsi catatan'), isNull);
      expect(NoteValidator.validateBody(null), isNull);
    });

    test('validasi body mengembalikan error jika melebihi 1000 karakter', () {
      final longBody = 'x' * 1001;
      expect(NoteValidator.validateBody(longBody), isNotNull);
    });
  });
}
