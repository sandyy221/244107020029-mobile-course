import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();

/// Rute dari klik notifikasi yang belum bisa diproses (app belum siap).
String? pendingDeepLink;

/// Callback navigasi, diisi oleh listenForeground().
void Function(String route)? _goRoute;

// ---------- Praktikum 2 ----------

Future<bool> requestNotificationPermission() async {
  // - Android 13+ (API 33+) secara otomatis meminta izin runtime POST_NOTIFICATIONS melalui method ini.
  // - iOS memerlukan izin eksplisit untuk alert, badge, dan sound.
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false, // Diatur manual via requestNotificationPermission()
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground -> pindah halaman.
      final route = response.payload;
      if (route == null || route.isEmpty) return;
      if (_goRoute != null) {
        _goRoute!(route); // app sudah hidup -> langsung navigasi
      } else {
        pendingDeepLink = route; // app belum siap -> simpan dulu
      }
    },
  );
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  // 1. Ambil token saat ini dan kirim ke backend.
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  // 2. onTokenRefresh: Token bisa berubah (reinstall, clear data, rotasi keamanan).
  // Wajib mengirim token baru ini ke backend (di-handle oleh callback onToken).
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await onToken(newToken);
  });

  // 3. Langganan topik kampus.
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

// ---------- Praktikum 3 ----------

/// Wajib top-level (bukan method kelas) karena berjalan di isolate terpisah.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase terinisialisasi jika butuh akses plugin Firebase di background
  await Firebase.initializeApp();

  // TIDAK BOLEH mengakses BuildContext / Riverpod / State widget di sini.
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = (data['route'] as String?) ?? '/';
  return route.startsWith('/') ? route : '/$route';
}

void listenForeground(void Function(String route) go) {
  _goRoute = go;

  // Foreground: sistem TIDAK menampilkan banner otomatis,
  // jadi tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    // TIDAK BOLEH menggunakan BuildContext langsung. Navigasi wajib via callback `go` 
    // yang mengimplementasikan router global (misal GoRouter via Ref).
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  // Background -> banner sistem diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(routeFromMessage(message.data));
  });
}

/// Terminated -> aplikasi dibuka dari notifikasi.
Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    go(routeFromMessage(initial.data));
  } else if (pendingDeepLink != null) {
    go(pendingDeepLink!);
  }
  pendingDeepLink = null;
}

// ---------- Topik ----------

Future<void> subscribePengumuman() =>
    FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');

Future<void> unsubscribePengumuman() =>
    FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');