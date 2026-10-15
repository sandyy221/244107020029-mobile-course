import 'package:campus_notify/messaging/push_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// pengiriman token akan gagal dan hanya dicatat di log (app tetap jalan).
final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
    GoRoute(
      path: '/pengumuman/:id',
      builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  registerBackgroundHandler();
  await initLocalNotifications();
  await requestNotificationPermission();

  // Kirim token FCM ke backend (gagal kirim hanya dicatat).
  Future<void> sendToken(String token) async {
    try {
      await dio.post('/devices', data: {
        'fcm_token': token,
        'platform': 'android',
      });
    } catch (e) {
      debugPrint('Gagal kirim token ke backend: $e');
    }
  }

  await initFcmToken(onToken: sendToken);

  // Foreground + background-diklik.
  listenForeground(router.go);

  runApp(const MyApp());

  // Terminated -> dibuka dari notifikasi (setelah frame pertama siap).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    handleTerminated(router.go);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      routerConfig: router,
    );
  }
}

/// Halaman utama sekaligus halaman Debug: menampilkan token terpotong.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _token = '...';

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then(_show);
    FirebaseMessaging.instance.onTokenRefresh.listen(_show);
  }

  void _show(String? t) {
    if (t == null || !mounted) return;
    final shown = t.length > 12 ? '${t.substring(0, 12)}...' : t;
    setState(() => _token = shown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Notify')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FCM token: $_token'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/pengumuman/3'),
              child: const Text('Buka pengumuman 3'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tujuan deep link dari notifikasi.
class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman $id')),
      body: Center(child: Text('Isi pengumuman dengan id: $id')),
    );
  }
}