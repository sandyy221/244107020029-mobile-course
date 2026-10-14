// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';


void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Buat GoRouter di dalam build method supaya bisa mendengarkan perubahan Riverpod
    final goRouter = GoRouter(
      redirect: (context, state) {
        // Membaca status login dari authStateProvider
        final loggedIn = ref.read(authStateProvider).value ?? false;
        final goingLogin = state.matchedLocation == '/login';
        
        if (!loggedIn && !goingLogin) return '/login';
        if (loggedIn && goingLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login', 
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/', 
          builder: (_, __) => const HomePage(),
        ),
        GoRoute(
          path: '/pengumuman/:id',
          builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Aplikasi Guard Route',
      routerConfig: goRouter,
    );
  }
}

// --- Dummy Pages (Pindahkan ke file terpisah nantinya) ---
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login Page')));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home Page')));
}

class AnnouncementPage extends StatelessWidget {
  final String id;
  const AnnouncementPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Pengumuman ID: $id')));
}