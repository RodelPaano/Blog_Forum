import 'dart:io';
import 'package:blog_forum_app/services/comment_service.dart';
import 'package:flutter/foundation.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';

import '../models/comment.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _service;

  CommentProvider({CommentService? service})
    : _service = service ?? CommentService();

  // ─── State ─────────────────────────────────────────────────

  final Map<String, List<Comment>> _byPost = {};
  final Set<String> _loadingPosts = {};
  String? _error;

  // ─── Getters ─────────────────────────────────────────────────

  bool isLoadingFor(String postId) => _loadingPosts.contains(postId);
  String? get error => _error;

  List<Comment> commentsFor(String postId) =>
      List.unmodifiable(_byPost[postId] ?? const []);

  // ─── Load ───────────────────────────────────────────────────
  Future<void> loadFor(String postId) async {
    if (_loadingPosts.contains(postId)) return;
    _loadingPosts.add(postId);
    _error = null;
    notifyListeners();
    try {
      _byPost[postId] = await _service.getByPost(postId);
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('CommentProvider.loadFor', e);
    } finally {
      _loadingPosts.remove(postId);
      notifyListeners();
    }
  }

  // ─── Add ───────────────────────────────────────────────
  Future<Comment?> add({
    required String postId,
    required String content,
    required List<File> imageFiles,
  }) async {
    try {
      final comment = await _service.add(
        postId: postId,
        content: content,
        imageFiles: imageFiles,
      );
      _byPost.putIfAbsent(postId, () => []).add(comment);
      _error = null;
      notifyListeners();
      return comment;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('CommentProvider.add', e);
      return null;
    }
  }

  // ─── Update ───────────────────────────────────────────────
  Future<bool> update({
    required Comment original,
    required String content,
    required List<String> existingImages,
    required List<File> newFiles,
    required List<String> toDelete,
  }) async {
    try {
      final updated = await _service.update(
        original: original,
        content: content,
        existingImages: existingImages,
        newFiles: newFiles,
        toDelete: toDelete,
      );
      final list = _byPost[original.postId];
      if (list != null) {
        final idx = list.indexWhere((c) => c.id == updated.id);
        if (idx != -1) list[idx] = updated;
      }

      _error = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('CommentProvider.update', e);
      return false;
    }
  }

  // ─── Delete ───────────────────────────────────────────────
  Future<bool> delete({
    required Comment comment,
    required List<String> imageUrls,
  }) async {
    try {
      await _service.delete(comment);
      _byPost[comment.postId]?.removeWhere((c) => c.id == comment.id);
      _error = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─── Clear Helper ───────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPost(String postId) {
    _byPost.remove(postId);
    notifyListeners();
  }
}
