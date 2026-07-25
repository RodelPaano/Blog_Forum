import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/exceptions.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import 'generic_repository.dart';

class ProfileRepository extends GenericRepository<UserProfile> {
  @override
  Future<List<UserProfile>> getAll({int page = 0, int limit = 50}) async {
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false)
          .range(page * limit, page * limit + limit - 1);
      return (res as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<UserProfile?> getById(String id) async {
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return UserProfile.fromJson(res);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<UserProfile> create(UserProfile item) => upsert(item);

  Future<UserProfile> upsert(UserProfile item) async {
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .upsert({
            'id': item.id,
            'email': item.email,
            'full_name': item.fullName,
            if (item.avatarUrl != null) 'avatar_url': item.avatarUrl,
          }, onConflict: 'id')
          .select()
          .single();
      return UserProfile.fromJson(res);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<UserProfile?> ensureProfileExists(String userId) async {
    if (userId.isEmpty) return null;
    final existing = await getById(userId);
    if (existing != null) return existing;

    final user = SupabaseService.auth.currentUser;
    final email = user?.email ?? '';
    final fullName = (user?.userMetadata?['full_name'] as String?) ?? 'User';

    final fallback = UserProfile(
      id: userId,
      email: email,
      fullName: fullName.isNotEmpty ? fullName : 'User',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    return await upsert(fallback);
  }

  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (fullName != null) updates['full_name'] = fullName;
      if (clearAvatar) {
        updates['avatar_url'] = null;
      } else if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }
      final res = await SupabaseService.client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return UserProfile.fromJson(res);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<UserProfile> update(UserProfile item) => updateProfile(
    userId: item.id,
    fullName: item.fullName,
    avatarUrl: item.avatarUrl,
  );

  @override
  Future<void> delete(String id) async {
    try {
      await SupabaseService.client.from('profiles').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw mapError(e);
    }
  }
}
