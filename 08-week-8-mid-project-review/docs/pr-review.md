# Dokumentasi Pull Request & Peer Code Review

Dokumen ini mencatat detail pengajuan Pull Request (PR), hasil penelaahan sejawat (Peer Code Review) dengan format terstruktur, tindak lanjut perbaikan, serta proses merge ke branch integrasi `develop`.

---

## 1. Metadata Pull Request

- **Nomor PR:** #12
- **Judul PR:** `feat(notes): validasi judul kosong + test`
- **Target Branch:** `develop` <- **Source Branch:** `feat/notes-validation`
- **Terkait Issue:** `Closes #12`
- **Status Akhir:** **MERGED (Squash and Merge)**

---

## 2. Deskripsi Pull Request (PR Template)

### Masalah
Sebelum perbaikan ini, pengguna dapat menekan tombol **Simpan** pada dialog pembuatan catatan baru dengan kolom judul kosong atau hanya berisi karakter spasi (`"   "`). Kondisi ini menyebabkan:
1. Terciptanya baris data di SQLite dengan judul kosong (`""`).
2. Tampilan daftar catatan pada `NotesPage` menjadi janggal dan sulit diidentifikasi pengguna.
3. Inkonsistensi data jika catatan tersebut disinkronkan ke server cloud.

### Solusi Teknis
1. **Modul Validasi Core (`lib/core/validate.dart`)**: Dibuat class `NoteValidator` yang memvalidasi input judul (memeriksa `null`, `trim().isEmpty`, dan panjang maksimal 100 karakter).
2. **Perlindungan Data Layer (`lib/data/repositories/note_repository.dart`)**: Menambahkan validasi `NoteValidator.validateTitle(title)` sebelum record disimpan ke SQLite. Jika tidak valid, dilemparkan `ArgumentError`.
3. **Peningkatan UX UI (`lib/pages/notes_page.dart`)**: Dialog pembuatan catatan dibungkus menggunakan `StatefulBuilder` untuk menampilkan `errorText` merah langsung di bawah kolom `TextField` judul saat input tidak valid, serta menghapus error seketika saat pengguna mulai mengetik kembali via callback `onChanged`.
4. **Pembersihan Static Analysis & Formatter**: Menghapus import mati (`package:riverpod/src/framework.dart` dan `package:sqflite/sqflite.dart`), memperbaiki `unnecessary_underscores`, dan merapikan format kode dengan `dart format .`.
5. **Penambahan Test Suite**: Membuat unit test komprehensif di `test/validate_note_test.dart` dan widget test di `test/widget_test.dart`.

### Cara Pengujian
1. **Pengujian Manual:**
   - Buka aplikasi Offline Notes.
   - Tekan tombol Floating Action Button (`+`).
   - Biarkan kolom judul kosong, lalu tekan tombol **Simpan**.
   - *Hasil:* Pesan error merah `"Judul tidak boleh kosong"` muncul tepat di bawah kolom judul, dialog tidak tertutup, dan data tidak disimpan.
   - Ketik spasi beberapa kali `"    "`, lalu tekan **Simpan**.
   - *Hasil:* Error tetap muncul.
   - Ketik judul yang valid `"Rencana Belajar Mobile"`, lalu tekan **Simpan**.
   - *Hasil:* Dialog tertutup dan catatan baru berhasil ditambahkan ke daftar catatan SQLite.
2. **Pengujian Otomatis:**
   ```bash
   flutter test test/validate_note_test.dart
   flutter test test/widget_test.dart
   ```
   *Hasil:* Seluruh test lolos (`8 passed, 0 failed`).

---

## 3. Log Peer Code Review

Proses penelaahan kode dilakukan oleh reviewer sejawat menggunakan pola terstruktur: **Observasi -> Dampak -> Usulan Konkret**.

### Reviewer Comment 1 (Kebenaran & Edge Case)
> **Observasi:** Pengecekan pada tombol simpan saat ini menggunakan `titleController.text.isNotEmpty`.  
> **Dampak:** Pengguna masih bisa memasukkan string berupa spasi kosong saja (`"   "`), sehingga validasi terlewati dan database tetap menyimpan judul kosong.  
> **Usulan Konkret:** Ubah logika pengecekan menjadi `titleController.text.trim().isNotEmpty` atau gunakan validator terpusat.

### Reviewer Comment 2 (Arsitektur & Separation of Concerns)
> **Observasi:** Logika validasi string judul ditulis langsung di dalam event handler widget UI dialog.  
> **Dampak:** Logika validasi tidak bisa di-unit test secara terisolasi tanpa merender widget tree, serta berpotensi terjadi duplikasi logika jika ada form edit catatan.  
> **Usulan Konkret:** Ekstraksi fungsi validasi ke file terpisah `lib/core/validate.dart` dalam bentuk pure Dart function.

### Reviewer Comment 3 (Pengujian & Test Coverage)
> **Observasi:** Unit test yang diajukan baru menguji judul kosong, belum mencakup kasus judul `null` dan batasan panjang karakter maksimum.  
> **Dampak:** Celah batas karakter (boundary edge case) tidak terverifikasi secara otomatis saat ada perubahan di masa mendatang.  
> **Usulan Konkret:** Tambahkan test case untuk parameter `null` dan panjang karakter lebih dari 100 karakter pada `test/validate_note_test.dart`.

### Keputusan Awal Reviewer:
🔴 **Request changes**

---

## 4. Tindak Lanjut Author & Re-Review

### Tindakan Author:
1. Membuat `lib/core/validate.dart` dengan class `NoteValidator` yang menangani `null`, `trim().isEmpty`, dan batasan 100 karakter.
2. Memperbarui dialog UI untuk menggunakan `NoteValidator` serta menampilkan `errorText`.
3. Menambahkan test case boundary di `test/validate_note_test.dart`.
4. Menjalankan `flutter analyze` (0 issues) dan `dart format .`.
5. Melakukan push commit perbaikan:
   `fix(notes): perbaiki sanitasi spasi, ekstraksi validator core, dan lengkapi test`

### Keputusan Akhir Reviewer:
🟢 **Approved**  
> *"Seluruh temuan telah diperbaiki dengan sangat baik. Validasi modular di layer core, UI feedback responsif, static analysis bersih, dan test suite lengkap 100% hijau. Siap dimerge!"*

---

## 5. Proses Merge

- **Metode Merge:** `Squash and Merge`
- **Pesan Commit Merge:** `feat(notes): validasi judul kosong + test (#12)`
- **Hasil:** Issue #12 tertutup otomatis, branch `feat/notes-validation` berhasil diintegrasikan ke branch `develop`.
