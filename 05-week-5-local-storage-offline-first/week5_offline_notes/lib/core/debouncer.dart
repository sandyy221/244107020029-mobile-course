import 'dart:async';

import 'package:flutter/foundation.dart';

/// Utilitas Debouncer untuk menunda eksekusi aksi hingga jeda waktu tertentu berlalu.
/// Sangat berguna untuk optimasi pencarian teks real-time agar tidak memicu
/// komputasi berat pada setiap ketukan keyboard (stroke).
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({Duration? delay, int? milliseconds})
    : delay = delay ?? Duration(milliseconds: milliseconds ?? 300);

  /// Menjadwalkan [action] untuk dieksekusi setelah [delay].
  /// Jika dipanggil kembali sebelum jeda waktu selesai, timer sebelumnya dibatalkan.
  void run(VoidCallback action) {
    cancel();
    _timer = Timer(delay, action);
  }

  /// Membatalkan timer aktif jika ada.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Membuang debouncer dan membebaskan timer.
  void dispose() {
    cancel();
  }

  /// Mengecek apakah debouncer sedang menunggu eksekusi.
  bool get isRunning => _timer?.isActive ?? false;
}
