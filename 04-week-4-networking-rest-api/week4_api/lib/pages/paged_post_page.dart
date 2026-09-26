import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() => _PagedPostPageState();
}

class _PagedPostPageState extends ConsumerState<PagedPostPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(pagedPostsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(pagedPostsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Posts'),
      ),
      body: stateAsync.when(
        // 1. STATE LOADING (Pertama kali)
        loading: () => const Center(child: CircularProgressIndicator()),

        // 2. STATE ERROR (Pertama kali + Tombol Retry)
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(pagedPostsNotifierProvider.notifier)
                      .refresh(),
                  child: const Text('Coba Lagi (Retry)'),
                ),
              ],
            ),
          ),
        ),

        // 3. STATE SUCCESS / EMPTY
        data: (pagedState) {
          // Empty State
          if (pagedState.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tidak ada data postingan ditemukan.'),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(pagedPostsNotifierProvider.notifier)
                        .refresh(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          // Success State
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(pagedPostsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: pagedState.items.length + (pagedState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < pagedState.items.length) {
                  final post = pagedState.items[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${post.id}')),
                      title: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                } else {
                  // Bottom Loader untuk Pagination / Bottom Error
                  if (pagedState.error != null) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          pagedState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}