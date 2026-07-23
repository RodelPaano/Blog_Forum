import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../core/sanitizers.dart';
import '../core/supabase_client.dart';
import '../models/comment.dart';
import '../repositories/comment_repository.dart';
import '../services/storage_service.dart';

class CommentProvider extends ChangeNotifier {
  final _repo = CommentRepository();
  final _storage = StorageService();

  final Map<String, List<Comment>> _byPost = {};
  final Set<String> _loadingPosts = {};
  String? _error;

  bool isLoadingFor(String postId) => _loadingPosts.contains(postId);
  String? get error => _error;

  List<Comment> commentsFor(String postId) =>
      List.unmodifiable(_byPost[postId] ?? const []);

  Future<void> loadFor(String postId) async {
    if (_loadingPosts.contains(postId)) return;
    _loadingPosts.add(postId);
    notifyListeners();
    try {
      _byPost[postId] = await _repo.getByPost(postId);
      _error = null;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('loadFor comments', e);
    } finally {
      _loadingPosts.remove(postId);
      notifyListeners();
    }
  }

  Future<Comment?> add({
    required String postId,
    required String content,
    required List<File> imageFiles,
  }) async {
    try {
      final cleanContent = Sanitizers.cleanText(
        content,
        maxLength: AppConfig.maxCommentLength,
      );

      final urls = <String>[];
      for (final f in imageFiles) {
        urls.add(await _storage.uploadImage(XFile(f.path), folder: 'comments'));
      }

      final comment = await _repo.create(
        Comment(
          id: '',
          postId: postId,
          userId: SupabaseService.currentUserId,
          content: cleanContent,
          images: urls,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _byPost.putIfAbsent(postId, () => []).add(comment);
      _error = null;
      notifyListeners();
      return comment;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> update({
    required Comment original,
    required String content,
    required List<String> existing,
    required List<File> newFiles,
    required List<String> toDelete,
  }) async {
    try {
      final cleanContent = Sanitizers.cleanText(
        content,
        maxLength: AppConfig.maxCommentLength,
      );

      if (toDelete.isNotEmpty) {
        await _storage.deleteImages(toDelete);
      }
      final newUrls = <String>[];
      for (final f in newFiles) {
        newUrls.add(
          await _storage.uploadImage(XFile(f.path), folder: 'comments'),
        );
      }
      final allImages = [
        ...existing,
        ...newUrls,
      ].where((u) => Sanitizers.safeImageUrl(u) != null).toList();

      final updated = await _repo.update(
        original.copyWith(content: cleanContent, images: allImages),
      );
      final list = _byPost[original.postId];
      if (list != null) {
        final idx = list.indexWhere((c) => c.id == updated.id);
        if (idx != -1) list[idx] = updated;
        notifyListeners();
      }
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(Comment comment) async {
    try {
      await _repo.delete(comment.id);
      if (comment.images.isNotEmpty) {
        await _storage.deleteImages(comment.images);
      }
      _byPost[comment.postId]?.removeWhere((c) => c.id == comment.id);
      notifyListeners();
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
