# week4_api

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# REFLEKSI
1. Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika aturan ini dilanggar?
UI layer (Widget) seharusnya hanya bertanggung jawab atas rendering visual dan merespons interaksi pengguna, bukan mengurusi protokol komunikasi data. jika aturan ini dilanggar, sulit dilakukan testing menulis UI widget test menjadi sangat rumit karena tidak bisa dengan mudah melakukan mocking respon jaringan tanpa menjalankan instance Dio sungguhan.

2. Kapan pagination client-side cukup, dan kapan harus mengandalkan pagination server (_page/_limit)?
pagination client-side cukup digunakan jika jumlah data relatif kecil dan pasti misalnya kurang dari 100–200 item, seperti daftar kategori, sedangkan jika jumlah data sangat besar atau tidak terbatas misalnya feed media sosial, e-commerce product list wajib menggunakan pagination server

3. Bagaimana exception repository berubah menjadi AsyncError tanpa try/catch di setiap widget? Kapan try/catch eksplisit tetap dibutuhkan?
Di riverpod, ketika metode di dalam AsyncNotifier (seperti metode build()) melempar exception (throw Exception()), Riverpod secara otomatis menangkap exception tersebut dan mengonversi state internal provider menjadi AsyncError(error, stackTrace). try/catch eksplisit dibutuhkan saat Translasi / Mapping Error di Layer Notifier/Repository, Saat ingin mengubah DioException yang bersifat teknis menjadi pesan yang ramah pengguna (user-friendly message) sebelum dilemparkan ke UI.

4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?
AI menambahkan pencatatan & guarding state pagination:
Masalah: Sering terjadi duplicate request (request ganda) ketika pengguna melakukan fast scrolling ke bawah.
Perbaikan: Menambahkan guard condition if (currentData.isLoadingMore || !currentData.hasMore) return; di notifier agar request susulan diabaikan saat request sebelumnya masih berjalan. kode tersebut berada di file providers.dart
