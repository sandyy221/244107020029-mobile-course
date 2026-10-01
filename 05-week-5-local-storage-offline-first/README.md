# AI Prompt Challenge
1. SharedPreferences:

Kelebihan: Konfigurasi zero-setup, sangat ringan untuk data flag sederhana.
Kekurangan: Tidak efisien dan berisiko mengalami kebocoran memori / corrupt jika memuat data koleksi besar secara terus-menerus.

2. Hive:

Kelebihan: Performa baca-tulis NoSQL berkecepatan tinggi karena langsung disimpan di memori.
Kekurangan: Penanganan migrasi skema rumit dan berisiko tinggi saat relasi data bertambah kompleks.

3. sqflite:

Kelebihan: Standar industri relational DB tanpa code generation, performa teruji untuk 1000+ baris data.
Kekurangan: Query ditulis dalam bentukan String polos (raw SQL) yang rentan typo dan error saat runtime.

4. Drift:

Kelebihan: Sangat type-safe, mendukung query stream-based secara otomatis, serta migrasi skema yang terstruktur.
Kekurangan: Menambahkan waktu build karena ketergantungan pada build_runner.

Untuk menangani 1000+ catatan beserta dukungan antrean sinkronisasi offline, digunakan skema tabel relational SQLite berikut:

CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 1 -- 1: Perlu disinkronkan, 0: Sudah tersinkron
);

-- Index untuk mempercepat query filter sync dan pendaftaran list
CREATE INDEX idx_notes_dirty ON notes(dirty);
CREATE INDEX idx_notes_updated ON notes(updated_at DESC);

Rekomendasi Final:
1. Untuk kebutuhan data (prefrrensi tema) adalah SharedPreferences, alasannya data berbentuk key-value sederhana (is_dark_mode), fleksibel, serta tidak memerlukan struktur relasional/query kompleks.

2. Untuk Daftar Catatan (1000+ Data) adalah sqflite / Drift, alasannya Mampu mengelola ribuan baris data secara efisien dengan indeks, mendukung query terfilter untuk dirty queue, dan tidak membuat performa memori melambat.

# Ai 
1. Apakah AI menempatkan daftar catatan di SharedPreferences? (menolak: rapuh untuk koleksi).
Ai menolak, alasannya menyimpan daftar koleksi catatan di SharedPreferences berisiko karena seluruh file preference dibaca secara synchronous saat start-up, yang akan menyebabkan lag atau app crash jika data catatan mencapai ribuan.

2. Apakah skema AI mendukung antrean sync (dirty flag / updated_at) atau hanya CRUD polos?
Ai mendukung, dengan alasan kehadiran flag `dirty` memungkinkan aplikasi mengetahui catatan mana yang dibuat/diubah secara offline untuk kemudian dikirim ke server lewat method `syncNotes()`[cite: 3].

3. Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?
Disesuaikan via Riverpod Refetching (`ref.invalidate`).

4. Apakah estimasi boilerplate AI masuk akal setelah Anda mencoba instalasinya (flutter pub add + migrasi skema)?
masuk akal, karena project menggunakan `sqflite` (tanpa Drift)[cite: 3], reaktivitas tidak berjalan via SQL stream watch secara otomatis, melainkan menggunakan pola pembaruan Riverpod (`ref.invalidate(dirtyCountProvider)`)[cite: 3]

5. Keputusan final Anda beserta alasannya, boleh berbeda dari rekomendasi AI selama berargumen.
menurut saya, Preferensi Tema lebih baik menggunakan SharedPreferences (prefs.dart)[cite: 4]. Penyimpanan Catatan & Cache API: Menggunakan sqflite (db.dart)[cite: 3, 4]. Alasannya, memberikan performa query SQLite yang cepat untuk 1000 data catatan dengan dukungan offline queue tanpa menambah kompleksitas code generator tambahan pada project flutter.

# Refleksi
Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?
haredPreferences tidak mendukung kueri terstruktur (indexing, filtering, sorting), tidak mendukung relasi data, dan membaca seluruh file XML/Plist ke memori (in-memory caching) setiap kali dibaca. Jika dilanggar jika jumlah catatan membengkak, serialisasi/deserialisasi JSON berukuran besar akan memblokir main thread, menyebabkan UI lag atau freeze.

Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain (misalnya network-first untuk data harga real-time)?
Kapan Cukup / Tepat Digunakan? untuk data yang jarang berubah dan prioritas kecepatan render tinggi (contoh: daftar artikel/postingan, profil pengguna, katalog produk). network-first Dibutuhkan saat data sangat dinamis dan nilai keakuratan adalah prioritas utama. sedangkan Stale-While-Revalidate Cocok untuk data yang ingin tampil cepat tetapi tetap langsung diperbarui secara background (contoh: feed media sosial).

Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah (tabel outbox) menjadi perlu?
Proses pembacaan dirty flag dilakukan secara asynchronous (Future / Stream di Riverpod) pada background thread. UI langsung merender data lokal dari SQLite tanpa menunggu response jaringan. Saat ada koneksi, proses sinkronisasi berjalan terpisah (non-blocking) dan hanya mengirim data berstatus dirty = 1. Setelah sukses, flag diubah menjadi dirty = 0 dan UI di-refresh melalui ref.invalidate()
Tabel outbox terpisah menjadi wajib saat aplikasi membutuhkan urutan eksekusi presisi (FIFO) dan penanganan operasi kompleks, seperti:
- Urutan transaksi yang tergantung waktu (misal: Create -> Update -> Delete pada catatan yang sama saat offline).
- Menampung payload bervariasi (operasi gabungan: POST, PUT, DELETE) beserta jumlah retry count dan histori pesan error jika sync gagal berturut-turut.

Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?
Penggunaan StateProvider Polos Tanpa Tipe Data / Notifier:
Sebab Ditolak: Rekomendasi awal menggunakan StateProvider tanpa type annotation eksplisit memicu error type inference pada Riverpod versi terbaru. Solusinya, dialihkan ke AsyncNotifierProvider / NotifierProvider standar Riverpod 2.x/3.x yang lebih type-safe, menjaga arsitektur tetap bersih, serta memudahkan manajemen state saat aplikasi bertambah kompleks.