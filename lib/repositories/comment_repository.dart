import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;

import '../core/exceptions.dart';
import '../core/supabase_client.dart';
import '../models/comment.dart';
import 'generic_repository.dart';
import 'profile_repository.dart';

class CommentRepository extends GenericRepository<Comment> {
  @override
  Future<List<Comment>> getAll({int page = 0, int limit = 100}) async {
    try {
      final res = await SupabaseService.client
          .from('comments')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .order('created_at', ascending: true)
          .range(page * limit, page * limit + limit - 1);
      return (res as List)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<List<Comment>> getByPost(String postId) async {
    try {
      final res = await SupabaseService.client
          .from('comments')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return (res as List)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<Comment?> getById(String id) async {
    try {
      final res = await SupabaseService.client
          .from('comments')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return Comment.fromJson(res);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<Comment> create(Comment item) async {
    if (item.userId.isEmpty) {
      throw const AuthException('User must be logged in to comment');
    }
    try {
      await ProfileRepository().ensureProfileExists(item.userId);
      final res = await SupabaseService.client
          .from('comments')
          .insert({
            'post_id': item.postId,
            'user_id': item.userId,
            'content': item.content,
            'images': item.images,
          })
          .select('*, profiles:user_id(full_name, avatar_url)')
          .single();
      return Comment.fromJson(res);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw mapError(e);
    }
  }


  @override
  Future<Comment> update(Comment item) async {
    try {
      final res = await SupabaseService.client
          .from('comments')
          .update({
            'content': item.content,
            'images': item.images,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', item.id)
          .select('*, profiles:user_id(full_name, avatar_url)')
          .single();
      return Comment.fromJson(res);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await SupabaseService.client.from('comments').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw mapError(e);
    }
  }
}
