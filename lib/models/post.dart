import 'base_model.dart';

class Post extends BaseModel {
  final String userId;
  final String title;
  final String content;
  final List<String> images;
  final String? authorName;
  final String? authorAvatar;

  const Post({
    required super.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.images,
    this.authorName,
    this.authorAvatar,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final userId = json['user_id'] as String?;
    final createdAt = json['created_at'] as String?;
    final updatedAt = json['updated_at'] as String?;
    if (id == null ||
        userId == null ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException('Post: missing required fields');
    }
    return Post(
      id: id,
      userId: userId,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      images: _parseImages(json['images']),
      authorName: _extractAuthorName(json),
      authorAvatar: _extractAuthorAvatar(json),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  static List<String> _parseImages(dynamic v) {
    if (v is List) return v.whereType<String>().toList(growable: false);
    return const [];
  }

  static String? _extractAuthorName(Map<String, dynamic> json) {
    final p = json['profiles'];
    if (p is Map<String, dynamic>) return p['full_name'] as String?;
    if (p is List && p.isNotEmpty) {
      final first = p.first;
      if (first is Map<String, dynamic>) return first['full_name'] as String?;
    }
    return null;
  }

  static String? _extractAuthorAvatar(Map<String, dynamic> json) {
    final p = json['profiles'];
    if (p is Map<String, dynamic>) return p['avatar_url'] as String?;
    if (p is List && p.isNotEmpty) {
      final first = p.first;
      if (first is Map<String, dynamic>) return first['avatar_url'] as String?;
    }
    return null;
  }

  Post copyWith({
    String? title,
    String? content,
    List<String>? images,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      authorName: authorName,
      authorAvatar: authorAvatar,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'content': content,
    'images': images,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
