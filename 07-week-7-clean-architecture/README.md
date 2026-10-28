# Refleksi
1. Mengapa interface repository harus tinggal di domain, bukan di data? Apa yang rusak bila dibalik?
jawaban: Aturan dependensi Clean Architecture mengharuskan panah mengarah ke dalam, data bergantung ke domain, bukan sebaliknya. Interface repository adalah kontrak yang dibutuhkan oleh domain use case memanggil fetchAnnouncements() tanpa peduli datanya dari mana. jadi yang memiliki kontrak itu adalah domain, dan data hanya memenuhinya.

2. Kapan use case benar-benar dibutuhkan, dan kapan repository langsung ke notifier sudah cukup?
jawaban: Use case dibutuhkan ketika sebuah operasi:
- menggabungkan lebih dari satu repository (misalnya login lalu simpan token lalu daftarkan token FCM ke backend), atau
- punya aturan bisnis yang layak diuji sendiri (validasi, pengurutan, filter, sinkronisasi). Repository langsung ke notifier sudah cukup ketika operasinya hanya meneruskan satu panggilan tanpa logika tambahan, misalnya login() yang cuma memanggil repository.login().

3. Apa biaya over-engineering (use case per CRUD satu-baris) bagi tim kecil? Kapan biayanya sepadan?
jawaban:Biayanya over-engineering:
- Jumlah file dan provider bertambah. Satu perubahan kecil menyentuh banyak file.
- Anggota baru butuh waktu lebih lama memahami alur, padahal tiap lapisan hanya meneruskan data.
- Waktu pengembangan fitur terbuang untuk boilerplate yang tidak melindungi apa pun.

Biaya ini sepadan ketika:
- logika bisnis nyata dan akan berubah, sehingga perlu diuji terpisah dari UI dan jaringan,
- tim atau aplikasi cukup besar sehingga orang bekerja paralel di fitur berbeda,
- sumber data kemungkinan berganti atau bertambah (online, offline, cache).

4. Bagian mana dari usulan AI yang Anda tolak atau sederhanakan, dan mengapa?
jawaban: Menolak use case Login: di kode auth_provider.dart hanya memanggil satu method AuthRepository, tanpa logika tambahan, jadi use case hanya akan meneruskan panggilan.