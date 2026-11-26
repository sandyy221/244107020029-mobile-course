import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/debouncer.dart';

void main() {
  group('Debouncer Performance Utility Tests', () {
    test(
      'hanya mengeksekusi pemanggilan terakhir setelah jeda waktu selesai',
      () async {
        final debouncer = Debouncer(milliseconds: 50);
        int executionCount = 0;
        String lastValue = '';

        // Simulasikan 5 kali ketukan cepat pengguna
        for (int i = 1; i <= 5; i++) {
          debouncer.run(() {
            executionCount++;
            lastValue = 'ketukan-$i';
          });
          await Future.delayed(const Duration(milliseconds: 10));
        }

        expect(
          executionCount,
          0,
          reason: 'Belum boleh dieksekusi sebelum delay selesai',
        );

        // Tunggu hingga jeda debouncer (50ms) selesai
        await Future.delayed(const Duration(milliseconds: 60));

        expect(executionCount, 1, reason: 'Harus dieksekusi tepat 1 kali');
        expect(
          lastValue,
          'ketukan-5',
          reason: 'Harus mengeksekusi nilai terakhir',
        );

        debouncer.dispose();
      },
    );

    test('cancel() membatalkan eksekusi yang sedang dijadwalkan', () async {
      final debouncer = Debouncer(milliseconds: 50);
      bool executed = false;

      debouncer.run(() {
        executed = true;
      });

      expect(debouncer.isRunning, isTrue);
      debouncer.cancel();
      expect(debouncer.isRunning, isFalse);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(executed, isFalse);

      debouncer.dispose();
    });
  });
}
