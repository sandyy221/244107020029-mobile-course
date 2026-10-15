# AI Chellenge cheklist
- Top-Level Background Handler: firebaseMessagingBackgroundHandler tetap dipertahankan sebagai fungsi top-level dengan anotasi @pragma('vm:entry-point').
- onTokenRefresh ke Backend: Di dalam initFcmToken, listener onTokenRefresh memanggil langsung fungsi onToken(newToken) (yang diarahkan ke fungsi pengiriman backend).
- Foreground Local Notification: Menggunakan _local.show(...) di dalam FirebaseMessaging.onMessage.listen agar banner pop-up muncul saat aplikasi terbuka.
- Keamanan BuildContext: Background handler, stream listener foreground, dan inisialisasi lokal tidak menyentuh BuildContext sama sekali; perutean diserahkan penuh kepada callback parameter go yang menggunakan router global.