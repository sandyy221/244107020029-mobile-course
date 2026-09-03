Hasil pembelajarab pertemuan 1
Tujuannya mempelajari dasar-dasar pengembangan aplikasi mobile berbasis Flutter/Dart. Memahami struktur dasar widget (StatelessWidget) dan cara menampilkan tata letak UI sederhana (layouting) di tengah layar.

Menampilkan judul aplikasi "Profil Mahasiswa".
Visual Icon: Menampilkan ikon akademis (Icons.school) berukuran besar.

Nama mahasiswa ('Nama Anda') dengan ukuran teks lebih besar (fontSize: 24). Deskripsi mata kuliah/pertemuan ('Pemrograman Mobile – Minggu 1').

Tata Letak Terpusat (Centered Layout): Seluruh elemen disusun secara vertikal (Column) dan diletakkan tepat di tengah layar (Center).
Bebas Banner Debug: Properti debugShowCheckedModeBanner: false digunakan untuk menghilangkan pita "DEBUG" di sudut kanan atas layar.

Stack Teknologi menggunakan bahasa pemrograman: Dart
Framework: Flutter (dengan komponen UI Material App)
IDE/Editor: VS Code / Android Studio

Cara menjalankannya Pastikan Flutter SDK dan emulator/perangkat fisik sudah siap. Langkah pertama:
Buat/buka proyek Flutter di IDE.
Salin kode di atas ke dalam file lib/main.dart.
Jalankan perintah "flutter run"

Hasil yang dicapai mengerti cara kerja main(), runApp(), MaterialApp, dan Scaffold. Dan juga memahami tetang widget:
- StatelessWidget: Digunakan karena tampilan bersifat statis (tidak berubah-ubah).
- Column: Untuk menyusun widget secara vertikal dari atas ke bawah.
- SizedBox: Digunakan untuk memberi jarak vertikal antar komponen (spacing).
- TextStyle: Untuk mengostumisasi ukuran dan tampilan teks.