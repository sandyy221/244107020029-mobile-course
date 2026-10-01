import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/framework.dart';
import 'pages/notes_page.dart';
import 'pages/settings_page.dart';
void main() {
  runApp(
    // Wajib ada ProviderScope agar Riverpod bisa berjalan
    const ProviderScope(
      child: MyApp(),
    ),
    
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca status dark mode (AsyncValue)
    final darkModeAsync = ref.watch(darkModeProvider);

    return darkModeAsync.when(
      data: (isDark) => MaterialApp(
        title: 'Offline Notes',
        debugShowCheckedModeBanner: false,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: const NotesPage(),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, __) => MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: const NotesPage(),
      ),
    );
  }
}