# AI-Assisted Development Log (`docs/ai-log.md`)

**Mata Kuliah:** Pemrograman Mobile  
**Topik:** #09 | AI-Assisted Development / Vibe Coding  
**Proyek Basis:** `week5_offline_notes` (Offline Notes dengan SQLite & Riverpod)  
**Fitur yang Ditambahkan:** Pencarian & Filter Judul Catatan (*Search & Filter*) dengan Empty State  

---

## 1. Praktikum 1: Prompt & Context Engineering

### 1.1. Formula 5 Slot (Prompt Inti)
Penyusunan prompt mengikuti formula 5 slot yang ketat agar menghasilkan kode yang modular, bebas halusinasi, dan mudah diuji:

```text
[Peran]
Bertindaklah sebagai Senior Flutter Developer.

[Konteks]
Proyek mobile Flutter 3.x menggunakan feature-first Clean Architecture (presentation -> domain <- data).
State management menggunakan Riverpod (AsyncNotifier).
Penyimpanan lokal menggunakan SQLite (sqflite_common_ffi).
Model Note memiliki field: id, title, body, updatedAt, dirty.

[Tugas]
Buat fitur pencarian dan filter catatan berdasarkan judul atau isi:
1. Logika filter murni di domain use case (tanpa ketergantungan UI/DB).
2. Notifier reaktif di presentation layer untuk mengelola query dan filtered notes.
3. Search bar di UI AppBar beserta empty state:
   - Empty state 1: Ketika database catatan masih kosong sama sekali ("Belum ada catatan").
   - Empty state 2: Ketika query pencarian tidak menemukan catatan yang cocok ("Tidak ada catatan yang cocok").
4. Tombol clear untuk mereset query pencarian.

[Batas]
- Jangan ubah arsitektur dasar.
- Jangan panggil SQLite/database langsung dari widget.
- Jangan gunakan package eksternal baru selain yang sudah ada di pubspec.yaml.
- Fungsi filter harus murni Dart (tanpa import package:flutter atau package:sqflite).
- Panjang fungsi/widget maksimal 80 baris per modul.

[Output]
Berikan:
1. Kode use case filter (lib/domain/search_notes.dart).
2. Kode AsyncNotifier & State (lib/presentation/notes_search_notifier.dart).
3. Kode UI SearchNotesPage (lib/pages/search_notes_page.dart).
4. Unit test suite dan widget test pembukti (test/search_filter_test.dart).
```

### 1.2. Konteks yang Disertakan & Perlindungan Privasi
- **Struktur Folder yang Disertakan:**
  ```text
  week5_offline_notes/
  ├── lib/
  │   ├── core/ (validate.dart)
  │   ├── data/ (local/db.dart, local/note.dart, repositories/note_repository.dart, providers.dart)
  │   └── pages/ (notes_page.dart)
  └── pubspec.yaml (flutter_riverpod, sqflite, sqflite_common_ffi, dio)
  ```
- **Prinsip Privasi:** Tidak ada token autentikasi, kredensial, atau path absolut yang diekspos dalam prompt AI.

---

## 2. Praktikum 2: Log Generate & Verifikasi Awal

### 2.1. Kode Output Awal dari AI (Sebelum Verifikasi)
Berikut adalah potongan kode awal yang diusulkan oleh AI sebelum dilakukan audit manual:

```dart
// DRAFT KASAR DARI AI (Mengandung bug logika dan masalah arsitektur)
class NotesPageWithSearch extends StatefulWidget {
  @override
  _NotesPageWithSearchState createState() => _NotesPageWithSearchState();
}

class _NotesPageWithSearchState extends State<NotesPageWithSearch> {
  String search = '';

  List<Note> getFiltered(List<Note> all) {
    // BUG LOGIKA: Case-sensitive & tidak menangani spasi kosong!
    return all.where((n) => n.title.contains(search)).toList();
  }

  // AI juga sempat mengusulkan query langsung ke database:
  // db.rawQuery("SELECT * FROM notes WHERE title LIKE '%$search%'"); // RISIKO SQL INJECTION!
}
```

### 2.2. Verifikasi 6 Langkah

1. **Baca Tiap Baris:** Mengidentifikasi bahwa implementasi awal AI mencampur logika filter di dalam `StatefulWidget`, yang melanggar pemisahan concern dan menyulitkan testing.
2. **Cek Import:** Memastikan layer domain (`lib/domain/search_notes.dart`) tidak mengimpor `package:flutter`, `sqflite`, atau `dio`. File hanya mengimpor model entity Dart murni.
3. **Cek API:** Autocomplete IDE dan dokumentasi resmi Dart memverifikasi bahwa `.trim()`, `.toLowerCase()`, dan `.contains()` adalah metode standar `String`.
4. **Jalankan Static Analysis:** Menjalankan `flutter analyze` untuk menjamin tidak ada warning, unused imports, atau deprecation.
5. **Uji Test Sukses & Gagal:** Menulis unit test untuk skenario sukses (query cocok, case-insensitive) dan skenario gagal/edge cases (query kosong, spasi whitespace, tidak cocok).
6. **Uji Manual:** Menguji langsung pada 3 kondisi query:
   - Query `""` (kosong): Menampilkan seluruh catatan.
   - Query `"belanja"`: Menampilkan catatan "Belanja Bulanan" meskipun dicari dengan huruf kecil.
   - Query `"zzz"`: Menampilkan ikon `Icons.search_off` dan teks error ramah.

### 2.3. Bukti Wajib: Halusinasi & Bug Logika AI yang Ditemukan
| Jenis Celah | Kode Awal AI | Dampak Bug / Risiko | Cara Pembuktian |
|---|---|---|---|
| **Bug Logika 1: Case-Sensitivity** | `n.title.contains(query)` | Catatan dengan judul "Belanja Bulanan" **tidak ditemukan** jika pengguna mencari "belanja" (huruf kecil). | Unit test gagal pada test case `expect(filterNotes(list, 'belanja'), hasLength(1))` sebelum diperbaiki. |
| **Bug Logika 2: Whitespace Bypass** | `query.isEmpty` tanpa `.trim()` | Mengetik spasi `"   "` dianggap sebagai pencarian karakter spasi, sehingga menyembunyikan catatan yang tidak memuat spasi ganda. | Unit test gagal pada query `'     '`. Diperbaiki dengan `final trimmed = query.trim(); if (trimmed.isEmpty) return notes;`. |
| **Halusinasi Arsitektur 3** | Menyarankan `rawQuery("... LIKE '%$search%'")` langsung di widget | Pelanggaran Clean Architecture (widget memanggil database) dan risiko SQL injection bila parameter tidak di-escape. | Penolakan langsung saat membaca kode; diganti dengan filter in-memory murni di use case domain. |

---

## 3. Praktikum 3: Debug & Refactoring ke Clean Architecture

### 3.1. Siklus Debug dengan Test Merah (Red-to-Green Testing)
1. **Reproduksi:** Memasukkan query huruf kecil `'belanja'` pada catatan `'Belanja Bulanan'` -> hasil kosong.
2. **Isolasi:** Memindahkan fungsi filter ke `lib/domain/search_notes.dart` sebagai pure function `filterNotes(notes, query)`.
3. **Test Merah:** Menjalankan test case:
   ```dart
   test('filter abaikan huruf besar/kecil', () {
     final result = filterNotes(sampleNotes, 'belanja');
     expect(result, hasLength(1));
   });
   ```
   *Hasil:* **FAILED** pada kode awal AI.
4. **Perbaikan Kode:**
   ```dart
   List<Note> filterNotes(List<Note> notes, String query) {
     final trimmed = query.trim();
     if (trimmed.isEmpty) return notes;
     final lower = trimmed.toLowerCase();
     return notes.where((n) {
       return n.title.toLowerCase().contains(lower) ||
           n.body.toLowerCase().contains(lower);
     }).toList();
   }
   ```
5. **Test Hijau:** Menjalankan kembali pengujian -> **ALL TESTS PASSED**.

### 3.2. Pemisahan Layer Bersih (Clean Architecture Mapping)
- **Widget Layer (`lib/pages/search_notes_page.dart`):**  
  Hanya bertanggung jawab merender UI, AppBar, search bar, empty state visual, dan FAB. Tidak ada query SQL maupun filtering manual di dalam build widget.
- **Notifier / Presentation Layer (`lib/presentation/notes_search_notifier.dart`):**  
  `NotesSearchNotifier` mengelola state `NotesSearchState`, mengambil catatan dari repository, dan menyediakan getter `filtered` yang memanggil domain use case.
- **Domain Layer (`lib/domain/search_notes.dart`):**  
  Memuat use case murni `filterNotes` tanpa dependensi eksternal. Dapat diuji secara instan dengan unit test.
- **Data Layer (`lib/data/repositories/note_repository.dart`):**  
  Mengurus persistensi SQLite tanpa terpengaruh logika pencarian UI.

---

## 4. AI Challenge: AI Senior Developer Review & Verification

### 4.1. Prompt Review AI
```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### 4.2. Tabel Usulan AI vs Keputusan Final Developer

| No | Temuan AI | Level | Rekomendasi AI | Keputusan | Alasan Teknis & Bukti |
|:--:|---|:---:|---|:---:|---|
| **1** | Input Whitespace Handling | **Blocker** | String spasi `"   "` harus diperlakukan sama dengan string kosong `""` agar tidak merusak filter. | **DITERIMA** | **Bukti:** Ditambahkan `query.trim().isEmpty` pada use case domain. Terbukti lolos pada unit test `query kosong atau hanya spasi kembalikan semua catatan`. |
| **2** | Pemisahan State & Domain Use Case | **Saran** | Pisahkan filter ke layer `domain/` murni dan pisahkan query state ke `AsyncNotifier`. | **DITERIMA** | **Bukti:** Dibuat `lib/domain/search_notes.dart` dan `lib/presentation/notes_search_notifier.dart`. Memenuhi aturan Dependency Rule. |
| **3** | Penggunaan SQLite FTS5 (Full-Text Search) Virtual Table | **Blocker** | Ganti filter in-memory dengan migrasi skema tabel SQLite FTS5 virtual table dan tokenizer Porter stemmer. | **DITOLAK** | **Alasan:** *Over-engineering* yang berlebihan untuk aplikasi catatan offline personal dengan ratusan catatan. Migrasi FTS5 menambah kompleksitas DDL SQLite, memperbesar ukuran database, dan membuat dependensi FFI lebih rentan platform error tanpa memberikan peningkatan performa yang terukur pada dataset lokal. Filter in-memory di domain use case jauh lebih sederhana, cepat, dan mudah diuji. |

---

## 5. Ringkasan Kualitas Kode & Hasil Mesin

- **Static Analysis:** `flutter analyze` -> `No issues found!` (0 issues).
- **Code Formatter:** `dart format --set-exit-if-changed .` -> Terformat rapi.
- **Test Suite:** `flutter test test/search_filter_test.dart` -> 6 Unit Tests + 3 Widget Tests = **9 Tests PASSED**.
