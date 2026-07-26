import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../utils/pagination.dart';

class PostProvider extends ChangeNotifier {
  final PostService _service;

  PostProvider({PostService? service}) : _service = service ?? PostService();

  // ─── State ─────────────────────────────────────────────────

  final Paginator<Post> _paginator = Paginator<Post>(
    pageSize: AppConfig.pageSize,
  );
  bool _loading = false;
  String? _error;

  // ─── Getters ───────────────────────────────────────────────

  List<Post> get posts => _paginator.items;
  bool get isLoading => _loading;
  bool get hasMore => _paginator.hasMore;
  String? get error => _error;

  // ─── Load ──────────────────────────────────────────────────

  Future<void> loadInitial() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _paginator.reset(
        load: (page, limit) => _service.getAll(page: page, limit: limit),
      );
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('PostProvider.loadInitial', e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_paginator.hasMore || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      await _paginator.loadMore(
        load: (page, limit) => _service.getAll(page: page, limit: limit),
      );
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('PostProvider.loadMore', e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Create ────────────────────────────────────────────────

  Future<Post?> createPost({
    required String title,
    required String content,
    required List<File> imageFiles,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final post = await _service.create(
        title: title,
        content: content,
        imageFiles: imageFiles,
      );
      _paginator.prepend(post);
      return post;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('PostProvider.createPost', e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Update ────────────────────────────────────────────────

  Future<Post?> updatePost({
    required String postId,
    required String title,
    required String content,
    required List<String> existingImageUrls,
    required List<File> newImageFiles,
    required List<String> imagesToDelete,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.update(
        postId: postId,
        title: title,
        content: content,
        existingImageUrls: existingImageUrls,
        newImageFiles: newImageFiles,
        imagesToDelete: imagesToDelete,
      );
      _paginator.replace(updated);
      return updated;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('PostProvider.updatePost', e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Delete ────────────────────────────────────────────────

  Future<bool> deletePost({
    required String postId,
    required List<String> imageUrls,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.delete(postId: postId, imageUrls: imageUrls);
      _paginator.removeWhere((p) => p.id == postId);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('PostProvider.deletePost', e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
