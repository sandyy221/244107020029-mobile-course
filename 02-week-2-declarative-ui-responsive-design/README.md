Tugas refleksi

1. Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?
jawaban: 
Imperative: mengubah UI secara manual, mengambil objek UI dan merubah propertinya langsung saat data berubah contohnya: button.setText("Selesai") atau element.style.display = 'none'. sedangkan Declarative fokus pada apa bentuk UI yang diinginkan untuk suatu status ($UI = f(state)$).

2. Kapan Expanded membantu dan kapan penggunaannya justru menghasilkan layout error?
jawaban: 
Widget Expanded membantu dalam Row, Column, atau Flex untuk memaksa child widget mengisi sisa ruang kosong pada sumbu utama (main axis), mencegah overflow pada layar kecil. Penyebab Layout Errornya terjadi ketika Expanded diletakkan di dalam kontainer dengan ukuran tidak terbatas (unbounded constraints)

3. Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?
jawaban:
Breakpoint memastikan responsivitas di berbagai ukuran layar seperti mobile, tablet, desktop. Mencegah elemen terpotong, ukuran tombol yang terlalu kecil untuk disentuh.

4. Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?
jawaban: 
dari hasil analisa, AI menambahkan beberapa perubahan. yang pertama:
- Header Profil: Dibuat menggunakan gabungan Container, Row, CircleAvatar, serta Column & Expanded untuk menampilkan informasi mahasiswa.
- Perbaikan Tema & Kartu: Menggunakan warna dinamis dari Theme.of(context).colorScheme agar komponen kartu dan teks otomatis menyesuaikan kontras ketika berpindah antara mode terang dan gelap.
- Aksesibilitas: Ditambahkan pada pembacaan gambar/avatar profil, tombol toggle tema, dan pembacaan angka pada kartu indikator.


