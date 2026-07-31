import 'dart:io';

import 'package:blog_forum_app/core/exceptions.dart'
    show AuthException, ValidationException;
import 'package:image_picker/image_picker.dart';

import '../core/config.dart';
import '../core/sanitizers.dart';
import '../core/supabase_client.dart';
import '../models/comment.dart';
import '../repositories/comment_repository.dart';
import '../services/storage_service.dart';

class CommentService {
  final CommentRepository _repo;
  final StorageService _storage;

  CommentService({CommentRepository? repo, StorageService? storage})
    : _repo = repo ?? CommentRepository(),
      _storage = storage ?? StorageService();

  // ─── Fetch ─────────────────────────────────────────────────

  Future<List<Comment>> getByPost(String postId) {
    return _repo.getByPost(postId);
  }

  // ─── Add ───────────────────────────────────────────────────

  Future<Comment> add({
    required String postId,
    required String content,
    required List<File> imageFiles,
    String? userId,
  }) async {
    userId ??= SupabaseService.currentUserId;
    // Validation
    if (userId.isEmpty) {
      throw const AuthException('User must be logged in to comment');
    }
    if (content.trim().isEmpty && imageFiles.isEmpty) {
      throw const ValidationException(
        'Comment must have content or at least one image.',
      );
    }

    // Sanitize
    final cleanContent = Sanitizers.cleanText(
      content,
      maxLength: AppConfig.maxCommentLength,
    );

    // Upload images
    final urls = <String>[];
    for (final f in imageFiles) {
      urls.add(await _storage.uploadImage(XFile(f.path), folder: 'comments'));
    }

    // Build and save
    return await _repo.create(
      Comment(
        id: '',
        postId: postId,
        userId: userId,
        content: cleanContent,
        images: urls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ─── Update ────────────────────────────────────────────────

  Future<Comment> update({
    required Comment original,
    required String content,
    required List<String> existingImages,
    required List<File> newFiles,
    required List<String> toDelete,
  }) async {
    // Validation
    final user = SupabaseService.currentUserId;
    final hasContent = content.trim().isNotEmpty;
    final hasImages = existingImages.isNotEmpty || newFiles.isNotEmpty;

    if (user.isEmpty) {
      throw const AuthException(
        'User must be logged in to update this comment',
      );
    }
    if (!hasContent && !hasImages) {
      throw const ValidationException(
        'Updated comment must have content or at least one image.',
      );
    }

    // Sanitize
    final cleanContent = Sanitizers.cleanText(
      content,
      maxLength: AppConfig.maxCommentLength,
    );

    // Delete removed images
    if (toDelete.isNotEmpty) {
      await _storage.deleteImages(toDelete);
    }

    // Upload new images
    final newUrls = <String>[];
    for (final f in newFiles) {
      newUrls.add(
        await _storage.uploadImage(XFile(f.path), folder: 'comments'),
      );
    }

    // Merge and sanitize image URLs
    final allImages = [
      ...existingImages,
      ...newUrls,
    ].where((u) => Sanitizers.safeImageUrl(u) != null).toList();

    return _repo.update(
      original.copyWith(content: cleanContent, images: allImages),
    );
  }

  // ─── Delete ────────────────────────────────────────────────

  Future<void> delete(Comment comment) async {
    await _repo.delete(comment.id);

    if (comment.images.isNotEmpty) {
      await _storage.deleteImages(comment.images);
    }
  }
}
