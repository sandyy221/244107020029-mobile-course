import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../models/post.dart';
import '../local/db.dart';
import 'dart:convert';

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
  Future<List<Post>> readCachedPosts() async {
    final db = await openNotesDb();
    final maps = await db.query('cached_posts');
    
    return maps.map((row) {
      final jsonMap = jsonDecode(row['payload'] as String);
      return Post.fromJson(jsonMap);
    }).toList();
  }
  Future<void> refreshPostsInBackground() async {
    try {
      final response = await _dio.get('https://jsonplaceholder.typicode.com/posts');
      final List data = response.data;

      final db = await openNotesDb();
      final batch = db.batch();
      
      // Bersihkan cache lama
      batch.delete('cached_posts');
      
      final now = DateTime.now().toIso8601String();
      for (var item in data) {
        batch.insert('cached_posts', {
          'id': item['id'],
          'payload': jsonEncode(item),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Abaikan error jaringan agar app offline tidak crash
    }
  }

  // 3. Cache-First Read (Sesuai Soal 1)
  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await readCachedPosts(); // Kembalikan cache seketika
    refreshPostsInBackground(); // Refresh background
    return cached;
  }
}