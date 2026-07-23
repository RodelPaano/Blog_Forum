import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../core/sanitizers.dart';
import '../core/supabase_client.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../services/storage_service.dart';
import '../utils/pagination.dart';

class PostProvider extends ChangeNotifier {
  final _repo = PostRepository();
  final _storage = StorageService();

  final Paginator<Post> _paginator = Paginator<Post>(
    pageSize: AppConfig.pageSize,
  );
  bool _loading = false;
  String? _error;

  List<Post> get posts => _paginator.items;
  bool get isLoading => _loading;
  bool get hasMore => _paginator.hasMore;
  String? get error => _error;

  Future<void> loadInitial() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _paginator.reset(
        load: (page, limit) => _repo.getAll(page: page, limit: limit),
      );
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('loadInitial', e);
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
        load: (page, limit) => _repo.getAll(page: page, limit: limit),
      );
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Post?> createPost({
    required String title,
    required String content,
    required List<File> imageFiles,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final cleanTitle = Sanitizers.cleanText(
        title,
        maxLength: AppConfig.maxTitleLength,
      );
      final cleanContent = Sanitizers.cleanText(
        content,
        maxLength: AppConfig.maxContentLength,
      );

      final uploadedUrls = <String>[];
      for (final f in imageFiles) {
        uploadedUrls.add(
          await _storage.uploadImage(XFile(f.path), folder: 'posts'),
        );
      }

      final post = await _repo.create(
        Post(
          id: '',
          userId: SupabaseService.currentUserId,
          title: cleanTitle,
          content: cleanContent,
          images: uploadedUrls,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _paginator.prepend(post);
      _error = null;
      return post;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('createPost', e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Post?> updatePost({
    required String postId,
    required String title,
    required String content,
    required List<String> existingImageUrls,
    required List<File> newImageFiles,
    required List<String> imagesToDelete,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final cleanTitle = Sanitizers.cleanText(
        title,
        maxLength: AppConfig.maxTitleLength,
      );
      final cleanContent = Sanitizers.cleanText(
        content,
        maxLength: AppConfig.maxContentLength,
      );

      if (imagesToDelete.isNotEmpty) {
        await _storage.deleteImages(imagesToDelete);
      }
      final newUrls = <String>[];
      for (final f in newImageFiles) {
        newUrls.add(await _storage.uploadImage(XFile(f.path), folder: 'posts'));
      }
      final allImages = [...existingImageUrls, ...newUrls];

      // Sanitize: drop any URLs that fail our allowlist
      final safeImages = allImages
          .where((u) => Sanitizers.safeImageUrl(u) != null)
          .toList();

      final updated = await _repo.update(
        Post(
          id: postId,
          userId: SupabaseService.currentUserId,
          title: cleanTitle,
          content: cleanContent,
          images: safeImages,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _paginator.replace(updated);
      _error = null;
      return updated;
    } on AppException catch (e) {
      _error = e.message;
      AppLogger.error('updatePost', e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(String postId, List<String> imageUrls) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.delete(postId);
      await _storage.deleteImages(imageUrls);
      _paginator.removeWhere((p) => p.id == postId);
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
