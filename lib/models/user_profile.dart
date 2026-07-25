// user_profile.dart
import 'base_model.dart';

class UserProfile extends BaseModel {
  final String email;
  final String fullName;
  final String? avatarUrl;

  const UserProfile({
    required super.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Safe JSON parser. Throws [FormatException] on missing required fields.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('UserProfile: id is required');
    }

    final createdRaw = json['created_at'];
    final updatedRaw = json['updated_at'];

    if (createdRaw == null) {
      throw const FormatException('UserProfile: created_at is required');
    }
    if (updatedRaw == null) {
      throw const FormatException('UserProfile: updated_at is required');
    }

    DateTime parseDate(dynamic v, String fieldName) {
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (e) {
          throw FormatException('UserProfile: invalid $fieldName format');
        }
      }
      throw FormatException(
        'UserProfile: $fieldName is required and must be a valid ISO8601 string',
      );
    }

    return UserProfile(
      id: id,
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? 'User',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: parseDate(createdRaw, 'created_at'),
      updatedAt: parseDate(updatedRaw, 'updated_at'),
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
