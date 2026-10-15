# Dokumentasi AI Prompt Challenge

# 1. Prompt yang Digunakan
"Minta AI coding assistant dengan prompt berikut: Aplikasi Flutter Campus Notification App. Stack: firebase_messaging, flutter_local_notifications, flutter_secure_storage, go_router, Riverpod. Buatkan PushService dengan: requestPermission + getToken + onTokenRefresh, onMessage (local notification), onMessageOpenedApp + getInitialMessage (navigasi), subscribe/unsubscribe topic, background handler top-level dengan @pragma('vm:entry-point'). Tandai bagian yang BERBEDA untuk Android 13+ vs iOS, dan bagian yang tidak boleh mengakses BuildContext."

# 2. Output Awal AI
AI memberikan struktur `PushService` dasar, tapi pada bagian `onTokenRefresh` hanya melakukan pencetakan log biasa tanpa memanggil fungsi API ke backend. Selain itu, penanganan navigasi di dalam background handler sempat didefinisikan menggunakan metode kelas yang tidak valid untuk isolate Flutter.

# 3. Perbaikan Manual
- Mengubah fungsi `onTokenRefresh` agar memanggil fungsi callback pengiriman token ke backend (`POST /devices`).
- Memastikan `firebaseMessagingBackgroundHandler` murni berada di tingkat atas (top-level function) dengan anotasi `@pragma('vm:entry-point')`.
- Memisahkan manajemen rute menggunakan konstanta terpusat di `lib/routes.dart` agar sinkron dengan GoRouter.

# 4. Alasan Teknis
Fungsi background harus top-level karena berjalan pada isolate yang terpisah dari siklus hidup UI utama aplikasi (`Root Isolate`). Akses terhadap `BuildContext` di dalam callback FCM dihindari sepenuhnya demi mencegah error `Navigator` ketika widget belum terpasang atau sedang dalam transisi.