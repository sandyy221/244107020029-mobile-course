import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../models/post.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(dioProvider));
});

class PostRepository {
  final Dio _dio;

  PostRepository(this._dio);

  Future<List<Post>> fetchPosts({required int page, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/posts',
        queryParameters: {
          '_page': page,
          '_limit': limit,
        },
      );

      final List data = response.data as List;
      return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      rethrow;
    }
  }
}