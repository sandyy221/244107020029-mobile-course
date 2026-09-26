import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/paged_post_page.dart'; // Sesuaikan dengan lokasi PagedPostPage kamu

void main() {
  runApp(
    // Wajib ada ProviderScope agar Riverpod bisa berjalan
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Riverpod Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Arahkan home ke PagedPostPage
      home: const PagedPostPage(),
    );
  }
}