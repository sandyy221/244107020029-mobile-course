import 'models/post.dart';

class PagedPostsState {
  final List<Post> items;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const PagedPostsState({
    this.items = const [],
    this.page = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PagedPostsState copyWith({
    List<Post>? items,
    int? page,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PagedPostsState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}