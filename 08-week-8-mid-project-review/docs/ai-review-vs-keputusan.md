# Dokumentasi AI Review vs Keputusan Final Developer

Dokumen ini mencatat proses pelaksanaan **AI Challenge**, hasil analisis tinjauan kode oleh AI Senior Flutter Developer, verifikasi teknis atas temuan tersebut, serta perbandingan antara usulan AI dengan keputusan final teknis yang diambil.

---

## 1. AI Review Prompt Challenge

Prompt berikut dijalankan pada AI coding assistant untuk mengevaluasi kode Pull Request `feat/notes-validation`:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## 2. Temuan Awal AI Assistant

Berdasarkan analisis PR, AI menghasilkan 5 temuan utama:

### Temuan 1: Input Whitespace Bypassing pada Validasi Judul
- **Level:** Blocker
- **Alasan:** Penggunaan `if (titleController.text.isNotEmpty)` pada tombol simpan masih meloloskan string yang hanya berisi karakter spasi atau tab (misal: `"   "`). Hal ini menyebabkan baris catatan kosong tersimpan di SQLite, yang akan merusak tampilan UI card catatan.
- **Usulan Kode AI:**
  ```dart
  if (titleController.text.trim().isEmpty) {
    // Tampilkan error
    return;
  }
  ```

### Temuan 2: Potensi Asynchronous Gap pada `BuildContext` Dialog
- **Level:** Blocker
- **Alasan:** Pemanggilan `Navigator.pop(ctx)` setelah operasi async `await repo.addNote(...)` tanpa memeriksa apakah widget dialog masih mounted (`ctx.mounted`) berisiko memicu crash jika pengguna membatalkan dialog sebelum proses disk I/O SQLite selesai.
- **Usulan Kode AI:**
  ```dart
  await repo.addNote(title: title, body: body);
  if (!ctx.mounted) return;
  Navigator.pop(ctx);
  ```

### Temuan 3: Logika Validasi Tergabung dalam Widget UI
- **Level:** Saran
- **Alasan:** Pengecekan kondisi validasi yang ditulis langsung di dalam `onPressed` tombol UI menyulitkan penulisan unit test mandiri tanpa harus merender widget.
- **Usulan Kode AI:** Ekstraksi logika validasi menjadi fungsi murni di `lib/core/validate.dart`.
  ```dart
  class NoteValidator {
    static String? validateTitle(String? value) { ... }
  }
  ```

### Temuan 4: Ketiadaan Pembatasan Panjang Karakter (Boundary Overflow)
- **Level:** Saran
- **Alasan:** Judul tanpa batas maksimum dapat menyebabkan crash UI atau overflow layout jika pengguna menempelkan paragraf panjang ke kolom judul.
- **Usulan Kode AI:** Tambahkan batas maksimal 100 karakter pada judul.
  ```dart
  if (title.length > 100) return 'Maksimal 100 karakter';
  ```

### Temuan 5: Usulan Penggunaan Monad `Either` / FP Library (`fpdart`) untuk Failure Handling
- **Level:** Blocker
- **Alasan:** AI menyarankan agar arsitektur Clean Architecture menerapkan Functional Programming dengan membungkus semua return value validasi dan repository ke dalam tipe `Either<ValidationFailure, NoteTitle>`.
- **Usulan Kode AI:** Menambahkan dependensi `fpdart` ke `pubspec.yaml` dan merombak entity model menjadi Value Objects terisolasi.

---

## 3. Tabel Verifikasi: Usulan AI vs Keputusan Final

| No | Temuan AI | Level | Rekomendasi AI | Keputusan Final | Alasan Teknis & Bukti |
|:--:|---|:---:|---|:---:|---|
| **1** | Validasi Whitespace Bypassing | Blocker | Gunakan `trim().isEmpty` | **DITERIMA** | **Bukti:** Terbukti bahwa string `"   "` memiliki `.isNotEmpty == true`. Validasi diperbaiki pada `NoteValidator.validateTitle` dan dibuktikan lolos via unit test `validate_note_test.dart`. |
| **2** | Asynchronous Gap `BuildContext` | Blocker | Gunakan `if (ctx.mounted)` sebelum pop | **DITERIMA** | **Bukti:** Standar Flutter Linter `use_build_context_synchronously`. Mencegah error context invalid saat operasi SQLite selesai. |
| **3** | Pemisahan Validasi ke Core | Saran | Buat `NoteValidator` mandiri | **DITERIMA** | **Bukti:** Memungkinkan unit testing tanpa overhead widget tree. Eksekusi 8 unit test berjalan dalam waktu kurang dari 1 detik. |
| **4** | Batasan Karakter Judul (100 char) | Saran | Batasi panjang judul maksimum | **DITERIMA** | **Bukti:** Melindungi integritas layout `ListTile` agar teks judul tidak memotong elemen action icon di sebelah kanan. |
| **5** | Penerapan Functional Programming (`Either`/`fpdart`) | Blocker | Tambah library `fpdart` & bungkus Value Objects | **DITOLAK** | **Alasan Penolakan:** *Over-engineering* yang tidak proporsional untuk lingkup aplikasi catatan offline ini. Menambahkan dependensi eksternal pihak ketiga memperbesar ukuran binary dan menambah kompleksitas kode tanpa urgensi bisnis. Penggunaan tipe bawaan Dart `String?` (mengembalikan null jika sukses atau pesan error jika gagal) jauh lebih idiomatis, mudah dibaca, dan zero overhead. |

---

## 4. Bukti Teknis Verifikasi (AI Verification Checklist)

### 4.1. Bukti Temuan Diterima 1: Deteksi Celah Whitespace
Unit test membuktikan bahwa validasi judul berhasil menangkap input whitespace:
```dart
test('mengembalikan pesan error ketika judul hanya berisi spasi atau whitespace', () {
  final result = NoteValidator.validateTitle('     ');
  expect(result, isNotNull);
  expect(result, 'Judul tidak boleh kosong');
});
```
*Hasil eksekusi:* `flutter test test/validate_note_test.dart` -> **PASS**.

### 4.2. Bukti Temuan Diterima 2: Pemisahan Layer & Zero Leakage
Pemeriksaan static analysis membuktikan bahwa layer `lib/core/validate.dart` murni menggunakan kode Dart standar tanpa mengimpor pustaka `flutter/material.dart`, `sqflite`, atau `dio`, sehingga memenuhi prinsip **Clean Architecture Dependency Rule**.

### 4.3. Bukti Temuan Ditolak: Penolakan Over-Engineering `fpdart`
Developer secara sadar menolak saran nomor 5. Sesuai prinsip **YAGNI (You Aren't Gonna Need It)** dan **KISS (Keep It Simple, Stupid)**, validasi form catatan sederhana tidak memerlukan kompleksitas monad FP. Hasil analisis `flutter analyze` tetap 0 issues dengan kode yang jauh lebih bersih dan mudah dipahami rekan tim.
