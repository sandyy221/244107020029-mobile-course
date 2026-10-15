# AI Chellenge cheklist
- Top-Level Background Handler: firebaseMessagingBackgroundHandler tetap dipertahankan sebagai fungsi top-level dengan anotasi @pragma('vm:entry-point').
- onTokenRefresh ke Backend: Di dalam initFcmToken, listener onTokenRefresh memanggil langsung fungsi onToken(newToken) (yang diarahkan ke fungsi pengiriman backend).
- Foreground Local Notification: Menggunakan _local.show(...) di dalam FirebaseMessaging.onMessage.listen agar banner pop-up muncul saat aplikasi terbuka.
- Keamanan BuildContext: Background handler, stream listener foreground, dan inisialisasi lokal tidak menyentuh BuildContext sama sekali; perutean diserahkan penuh kepada callback parameter go yang menggunakan router global.



# Tugas Refleksi
1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?

Alasan: SharedPreferences (di Android) dan NSUserDefaults (di iOS) menyimpan data dalam bentuk file XML/plist biasa di direktori aplikasi yang tidak dienkripsi secara default. Jika perangkat melakukan root / jailbreak atau mengalami eksploitasi keamanan (misal serangan local file reading), data di dalamnya dapat diakses dengan mudah oleh aplikasi pihak ketiga atau penyerang.

Risiko jika bocor: Refresh token memiliki masa berlaku (lifetime) yang jauh lebih panjang daripada access token. Jika penyerang mendapatkan refresh token Anda, mereka dapat terus-menerus menghasilkan access token baru secara sah dari server tanpa perlu mengetahui password asli pengguna, sehingga akun dapat dibajak dalam jangka panjang. Oleh karena itu, gunakan enkripsi tingkat OS seperti flutter_secure_storage (EncryptedSharedPreferences / Keychain).

2. Apa yang rusak bila onTokenRefresh diabaikan selama satu semester perkuliahan?

Dampak: Token FCM dapat berubah sewaktu-waktu akibat beberapa faktor seperti: pengguna melakukan reinstall aplikasi, menghapus data aplikasi (clear data), pencadangan sistem mengembalikan aplikasi ke perangkat baru, atau sistem Firebase melakukan rotasi token keamanan secara berkala.

Akibatnya: Jika onTokenRefresh diabaikan, backend akan tetap menyimpan token lama yang sudah kedaluwarsa (stale token). Ketika kampus mengirimkan pengumuman penting (misalnya perubahan jadwal ujian atau darurat kelas), notifikasi tidak akan pernah sampai ke perangkat mahasiswa tersebut karena token target di database server sudah tidak valid.

3. Kapan memakai topik (topic) dan kapan memakai token perangkat (device token)? Beri contoh pesan kampus untuk masing-masing.

Topik (Topic Messaging): Digunakan untuk pengiriman pesan massal ke sekelompok pengguna yang memiliki ketertarikan atau status yang sama tanpa harus mencatat token satu per satu di backend.

Contoh pesan: Pengumuman umum seluruh mahasiswa, misal: "Libur nasional hari Senin, seluruh perkuliahan ditiadakan." (Topik: pengumuman-kampus).

Token Perangkat (Device Token / Multicast): Digunakan untuk pengiriman pesan yang sifatnya personal, rahasia, atau spesifik ditujukan ke satu pengguna/perangkat tertentu.

Contoh pesan: Notifikasi nilai akademik pribadi atau status pembayaran SPP, misal: "Nilai Mata Kuliah Pemrograman Mobile Anda telah diunggah: A."

4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?

Bagian yang diperbaiki: Draf awal AI sering kali hanya mencetak token baru ke konsol log (print(newToken)) saat event onTokenRefresh terjadi.

Alasan perbaikan: Hal tersebut tidak menyelesaikan masalah bisnis di dunia nyata karena backend tidak akan pernah tahu bahwa token perangkat telah berubah. Oleh karena itu, draf tersebut diperbaiki dengan memastikan onTokenRefresh langsung memicu fungsi pengiriman ulang token (_sendTokenToBackend / onToken(newToken)) ke server backend secara otomatis.