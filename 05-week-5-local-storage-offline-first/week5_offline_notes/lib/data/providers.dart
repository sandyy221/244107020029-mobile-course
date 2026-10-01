import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paged_posts.dart';
import 'repositories/post_repository.dart';
import 'repositories/note_repository.dart';

final pagedPostsNotifierProvider =
    AsyncNotifierProvider<PagedPostsNotifier, PagedPostsState>(
  PagedPostsNotifier.new,
);

class PagedPostsNotifier extends AsyncNotifier<PagedPostsState> {
  static const int _limit = 10;

  @override
  Future<PagedPostsState> build() async {
    return _fetchInitialPage();
  }

  Future<PagedPostsState> _fetchInitialPage() async {
    final repo = ref.watch(postRepositoryProvider);
    try {
      final posts = await repo.fetchPosts(page: 1, limit: _limit);
      return PagedPostsState(
        items: posts,
        page: 1,
        hasMore: posts.length == _limit,
      );
    } on DioException catch (e) {
      throw Exception(mapDioErrorToMessage(e));
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui.');
    }
  }

  // Reload / Retry dari awal
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitialPage());
  }

  // Infinite Scroll dengan Guard Request Ganda
  Future<void> loadMore() async {
    final currentData = state.value;
    if (currentData == null) return;

    // Guard 1 & 2: Jika sedang loading lebih banyak data atau sudah habis, abaikan request ganda
    if (currentData.isLoadingMore || !currentData.hasMore) return;

    // Set state ke loadingMore
    state = AsyncValue.data(
      currentData.copyWith(isLoadingMore: true, error: null),
    );

    final nextPage = currentData.page + 1;
    final repo = ref.read(postRepositoryProvider);

    try {
      final newPosts = await repo.fetchPosts(page: nextPage, limit: _limit);
      
      state = AsyncValue.data(
        currentData.copyWith(
          items: [...currentData.items, ...newPosts],
          page: nextPage,
          isLoadingMore: false,
          hasMore: newPosts.length == _limit,
        ),
      );
    } on DioException catch (e) {
      state = AsyncValue.data(
        currentData.copyWith(
          isLoadingMore: false,
          error: mapDioErrorToMessage(e),
        ),
      );
    } catch (_) {
      state = AsyncValue.data(
        currentData.copyWith(
          isLoadingMore: false,
          error: 'Gagal memuat halaman berikutnya.',
        ),
      );
    }
  }
}


// Helper pemetaan error
String mapDioErrorToMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Koneksi waktu habis. Silakan coba lagi.';
    case DioExceptionType.connectionError:
      return 'Gagal terhubung ke internet. Periksa koneksi Anda.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      if (code == 404) return 'Data tidak ditemukan (404).';
      if (code != null && code >= 500) return 'Masalah pada server ($code).';
      return 'Respon server gagal ($code).';
    default:
      return 'Terjadi kesalahan koneksi jaringan.';
  }
  
}
final noteRepositoryProvider = Provider((ref) => NoteRepository());

// Provider untuk Badge Dirty Count
final dirtyCountProvider = FutureProvider((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return await repo.countDirty();
});

// Controller untuk aksi Sync
final syncControllerProvider = Provider((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return () async {
    // 1. Jalankan proses syncNotes
    final syncedCount = await repo.syncNotes(repo);
    
    // 2. Refresh provider badge dirty agar nilainya kembali ke 0
    ref.invalidate(dirtyCountProvider);
    
    return syncedCount;
  };
});