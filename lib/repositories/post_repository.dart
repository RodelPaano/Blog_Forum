import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;

import '../core/config.dart';
import '../core/exceptions.dart';
import '../core/supabase_client.dart';
import '../models/post.dart';
import 'generic_repository.dart';
import 'profile_repository.dart';

class PostRepository extends GenericRepository<Post> {
  @override
  Future<List<Post>> getAll({
    int page = 0,
    int limit = AppConfig.pageSize,
  }) async {
    try {
      final from = page * limit;
      final to = from + limit - 1;
      final res = await SupabaseService.client
          .from('posts')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .order('created_at', ascending: false)
          .range(from, to);
      return (res as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<Post?> getById(String id) async {
    try {
      final res = await SupabaseService.client
          .from('posts')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return Post.fromJson(res);
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  Future<List<Post>> getByUser(
    String userId, {
    int page = 0,
    int limit = AppConfig.pageSize,
  }) async {
    try {
      final res = await SupabaseService.client
          .from('posts')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(page * limit, page * limit + limit - 1);
      return (res as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<Post> create(Post item) async {
    if (item.userId.isEmpty) {
      throw const AuthException('User must be logged in to create a post');
    }
    try {
      await ProfileRepository().ensureProfileExists(item.userId);
      final res = await SupabaseService.client
          .from('posts')
          .insert({
            'user_id': item.userId,
            'title': item.title,
            'content': item.content,
            'images': item.images,
          })
          .select('*, profiles:user_id(full_name, avatar_url)')
          .single();
      return Post.fromJson(res);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<Post> update(Post item) async {
    try {
      final res = await SupabaseService.client
          .from('posts')
          .update({
            'title': item.title,
            'content': item.content,
            'images': item.images,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', item.id)
          .select('*, profiles:user_id(full_name, avatar_url)')
          .single();
      return Post.fromJson(res);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await SupabaseService.client.from('posts').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }
}
