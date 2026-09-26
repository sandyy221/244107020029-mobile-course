class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userId: json['userId'] is int
          ? json['userId']
          : (int.tryParse(json['userId']?.toString() ?? '') ?? 0),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }
}