import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/api_client.dart';
import 'data/auth_repository.dart';
import 'data/token_store.dart';
import 'messaging/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initLocalNotifications();
  await requestNotificationPermission();

  final dio = buildApiClient(TokenStore(), AuthRepository());

  Future<void> sendToken(String token) async {
    try {
      await dio.post('/devices', data: {'fcm_token': token, 'platform': 'android'});
    } catch (e) {
      debugPrint('Gagal kirim token ke backend: $e');
    }
  }

  await initFcmToken(onToken: sendToken);

  runApp(const ProviderScope(child: MyApp()));
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Campus Notify',
      home: const Scaffold(
        body: Center(child: Text('Campus Notify')),
      ),
    );
  }
}