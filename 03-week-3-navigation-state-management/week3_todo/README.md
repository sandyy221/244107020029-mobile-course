# week3_todo

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



# REFLEKSI_PRAKTIKUM_3
mengapa menampilkan ulang data lama (stale data) dengan indikator refresh kadang lebih baik daripada mengosongkan layar? Kapan pola itu penting?

jawaban:
Mengurangi Perceived Latency (Sensasi Lambat), Mencegah Momen Berkedip (Layout Shift / Flickering), Perlindungan Terhadap Gangguan Jaringan. Jika koneksi internet mendadak terputus saat refresh, pengguna masih bisa melihat dan menggunakan data lama daripada dihadapkan pada layar kosong. Pola ini penting ketika, Aplikasi Berbasis Feed & Lini Masa (Social Media & News) Pengguna dapat membaca postingan yang sudah termuat saat aplikasi secara diam-diam memuat konten terbaru di latar belakang (Pull-to-Refresh), Daftar Harga & Pasar Finansial (E-commerce / FinTech) Pengguna tetap perlu referensi harga atau detail produk sebelumnya saat sistem memperbarui angka real-time.
