class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'content': content,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
    };
  }
}
