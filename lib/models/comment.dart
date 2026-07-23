import 'base_model.dart';

class Comment extends BaseModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final List<String> images;
  final String? authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.images,
    this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
  }) : super();

  factory Comment.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final postId = json['post_id'] as String?;
    final userId = json['user_id'] as String?;
    final createdAt = json['created_at'] as String?;
    final updatedAt = json['updated_at'] as String?;
    if (id == null ||
        postId == null ||
        userId == null ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException('Comment: missing required fields');
    }
    return Comment(
      id: id,
      postId: postId,
      userId: userId,
      content: (json['content'] as String?) ?? '',
      images: _parseImages(json['images']),
      authorName: _extractName(json),
      authorAvatar: _extractAvatar(json),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  static List<String> _parseImages(dynamic v) {
    if (v is List) return v.whereType<String>().toList(growable: false);
    return const [];
  }

  static String? _extractName(Map<String, dynamic> json) {
    final p = json['profiles'];
    if (p is Map<String, dynamic>) return p['full_name'] as String?;
    if (p is List && p.isNotEmpty) {
      final f = p.first;
      if (f is Map<String, dynamic>) return f['full_name'] as String?;
    }
    return null;
  }

  static String? _extractAvatar(Map<String, dynamic> json) {
    final p = json['profiles'];
    if (p is Map<String, dynamic>) return p['avatar_url'] as String?;
    if (p is List && p.isNotEmpty) {
      final f = p.first;
      if (f is Map<String, dynamic>) return f['avatar_url'] as String?;
    }
    return null;
  }

  Comment copyWith({
    String? content,
    List<String>? images,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id,
      postId: postId,
      userId: userId,
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
    'post_id': postId,
    'user_id': userId,
    'content': content,
    'images': images,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
