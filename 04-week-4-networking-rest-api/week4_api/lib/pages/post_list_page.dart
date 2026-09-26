import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

class PostListPage extends ConsumerWidget {
  const PostListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Menggunakan pagedPostsNotifierProvider yang sudah ada di providers.dart
    final postsAsync = ref.watch(pagedPostsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(pagedPostsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2. Format error string dengan rapi tanpa fungsi eksternal yang hilang
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(pagedPostsNotifierProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (pagedState) {
          final posts = pagedState.items;

          if (posts.isEmpty) {
            return const Center(
              child: Text('Belum ada data dari server.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(pagedPostsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(post.id.toString()),
                  ),
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}