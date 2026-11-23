# Review Checklist & Mid-Project Audit

Dokumen ini memuat hasil audit riwayat Git, perbaikan pesan commit lama ke standar Conventional Commits, evaluasi kesiapan paruh semester (Mid-Semester Readiness), serta checklist peer code review untuk repository proyek mobile.

---

## 1. Audit Riwayat Git (Praktikum 1)

### 1.1. Log Riwayat Commit Terakhir
Berdasarkan eksekusi `git log --oneline -15`:
```text
138a981 Tugas Refleksi
6348dfd Tugas, refleksi, dan referensi
ecc97b8 Refactoring, testing, dan error umum
90e67f0 AI chellenge & AI cheklist
77870a9 Praktikum 3: Payload, tiga app state, klik dan topik
e4312a9 Praktikum 2: FCM, permission, dan token lifecycle
c4f952a Praktikum 2: FCM, permission, dan token lifecycle
c0d0c0a Praktikum 2: FCM, permission, dan token lifecycle
5828de9 praktikum_1
69be2dd Tugas & Refleksi Week5
5e96d97 Praktikum 3: Cache-first dan antrean sync
545b61c Praktikum 2: SQLite dan repository catatan
6b1af3d Merge branch 'main' of https://github.com/sandyy221/244107020029-mobile-course
82d1d47 Praktikum 1: SharedPreferences
7026fe3 Delete Week_6.ipynb
```

### 1.2. Status Branch dan Remote
Berdasarkan eksekusi `git branch -a` dan `git status`:
```text
  develop
* feat/notes-validation
  main
  remotes/origin/develop
  remotes/origin/feat/notes-validation
  remotes/origin/main
```

### 1.3. Analisis Masalah Hygiene Git
Dari audit riwayat commit ditemukan beberapa kelemahan yang perlu diperbaiki dalam standar kolaborasi tim:
1. **Pesan Commit Tidak Mengikuti Conventional Commits**: Sebagian besar pesan commit hanya menggunakan penamaan generik/judul tugas kuliah seperti `praktikum_1`, `Tugas Refleksi`, dan `AI chellenge & AI cheklist` tanpa indikator tipe (`feat`, `fix`, `docs`, `refactor`, `test`) dan cakupan modul (`scope`).
2. **Duplikasi Commit Identik**: Terjadi commit berulang dengan pesan yang sama persis berturut-turut pada hash `c0d0c0a`, `c4f952a`, dan `e4312a9` (`Praktikum 2: FCM, permission, dan token lifecycle`).
3. **Pencampuran Perubahan (Non-Atomic Commits)**: Commit sering kali menggabungkan perubahan aset, konfigurasi platform build (Android/iOS), dan logika aplikasi dalam satu commit raksasa, menyulitkan proses review dan `git revert` jika terjadi bug regresi.
4. **Disiplin Branching**: Sebelum implementasi Week 8, commit dilakukan langsung di `main` tanpa isolasi branch fitur (`feature/*`) dan branch staging/integrasi (`develop`).

---

## 2. Perbaikan Pesan Commit Buruk (Simulasi Praktikum 1.3)

Sebagai bentuk simulasi perbaikan hygiene, berikut penulisan ulang 3 pesan commit lama menjadi format standar Conventional Commits `tipe(scope): deskripsi singkat imperatif`:

| Commit Hash | Pesan Commit Lama | Pesan Commit Baru (Conventional) | Alasan Perbaikan |
|---|---|---|---|
| `5828de9` | `praktikum_1` | `feat(auth): implementasi token store dan dio api client` | Menggunakan tipe `feat`, scope `auth`, serta menjelaskan secara eksplisit apa yang ditambahkan (token storage dan API client), bukan sekadar nomor modul praktikum. |
| `69be2dd` | `Tugas & Refleksi Week5` | `docs(notes): perbarui dokumentasi arsitektur offline-first dan refleksi sqlite` | Menggunakan tipe `docs`, scope `notes`, dan memperjelas konten dokumentasi yang diperbarui sehingga tim langsung mengetahui bahwa tidak ada perubahan logika kode. |
| `ecc97b8` | `Refactoring, testing, dan error umum` | `refactor(notify): standarisasi api error handling dan unit test auth push` | Menggunakan tipe `refactor` dan scope `notify`, memperjelas bahwa commit tersebut merestrukturisasi error handling dan menambah pengujian unit push notification. |

---

## 3. Checklist Peer Code Review (Praktikum 2)

Checklist ini wajib dipenuhi oleh reviewer sebelum memberikan status **Approve** pada Pull Request:

### A. Kebenaran Logika & Edge Cases
- [x] **Null Safety**: Semua parameter null dicek dengan aman (contoh: `NoteValidator.validateTitle(null)` mengembalikan error alih-alih melempar NPE).
- [x] **Whitespace / Empty Handling**: Input string yang hanya berisi karakter spasi `"   "` tidak dianggap valid (`title.trim().isEmpty`).
- [x] **Async Lifecycle Guard**: Callback navigasi atau UI setelah operasi async (`await repo.addNote(...)`) dilindungi oleh pengecekan mounted (`if (ctx.mounted) Navigator.pop(ctx)`).

### B. Arsitektur & Separation of Concerns
- [x] **Logika Validasi Modular**: Validasi tidak disematkan secara hardcoded di dalam widget UI, melainkan diekstraksi ke class khusus `NoteValidator` di `lib/core/validate.dart`.
- [x] **Perlindungan Multi-Layer**: Validasi diterapkan di layer UI (untuk feedback instan pengguna) dan di layer Repository (untuk mencegah corrupted state masuk ke database SQLite).
- [x] **Dependency Rule**: Layer `core` tidak memiliki dependensi balik ke presentation layer ataupun widget Flutter.

### C. Pengujian Otomatis (Testing)
- [x] **Unit Testing Komprehensif**: File `test/validate_note_test.dart` mencakup pengujian judul `null`, string kosong `""`, string spasi `"   "`, teks normal valid, serta batas maksimal karakter.
- [x] **Widget Smoke Test**: File `test/widget_test.dart` menguji rendering `NotesPage` dengan `ProviderScope` tanpa kegagalan assertion.
- [x] **Hasil Test**: 100% tes lolos (`8 passed`).

### D. Keterbacaan Kode & UX
- [x] **Feedback UI Real-time**: Menggunakan `errorText` pada `InputDecoration` dan menghapus error saat pengguna mulai mengetik kembali via listener `onChanged`.
- [x] **Formattings**: Kode diformat seragam menggunakan `dart format .`.

---

## 4. Evaluasi Kesiapan Paruh Semester (Mid-Semester Readiness Review)

| Aspek Penilaian | Target Standar | Status Proyek | Catatan Evaluasi |
|---|---|---|---|
| **Struktur Folder & Arsitektur** | Feature-First / Modular | **Lolos** | Terorganisir rapi dalam `core/`, `data/`, `pages/`, dan terisolasi per fitur. |
| **Pemeriksaan Mesin (Static Analysis)** | `flutter analyze` 0 issues | **Lolos** | Bersih total, tidak ada warning, error, maupun hint yang tertinggal. |
| **Format Standar Dart** | `dart format` bersih | **Lolos** | 100% file Dart telah diformat otomatis sesuai panduan style Dart. |
| **Pengujian Otomatis** | `flutter test` hijau | **Lolos** | Seluruh test suite (unit + widget) berhasil dieksekusi dengan status PASS. |
| **Branching & PR Discipline** | Git Flow aktif | **Lolos** | Branch `develop` menjadi target integrasi, branch `feat/notes-validation` dibuat terisolasi dan siap dimerge. |
| **CI Automation** | GitHub Actions Workflow | **Lolos** | File `.github/workflows/ci.yml` aktif memverifikasi analyze dan test pada setiap PR. |
| **Dokumentasi Proyek** | README lengkap + Screenshot | **Lolos** | Menyediakan langkah instalasi, dependensi, bukti pengujian, dan analisis AI. |

> **Kesimpulan Mid-Review:** Fondasi arsitektur, disiplin git, dan kualitas kode proyek berada dalam status **Siap (Production-Ready)** untuk melanjutkan pengembangan fitur lanjutan pada paruh semester kedua.
