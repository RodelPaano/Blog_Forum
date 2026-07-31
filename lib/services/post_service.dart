import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../core/config.dart';
import '../core/exceptions.dart';
import '../core/sanitizers.dart';
import '../core/supabase_client.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../services/storage_service.dart';

class PostService {
  final PostRepository _repo;
  final StorageService _storage;

  PostService({PostRepository? repo, StorageService? storage})
    : _repo = repo ?? PostRepository(),
      _storage = storage ?? StorageService();

  // ─── Fetch ─────────────────────────────────────────────────

  Future<List<Post>> getAll({required int page, required int limit}) {
    return _repo.getAll(page: page, limit: limit);
  }

  Future<Post> getPostById(String postId) async {
    final post = await _repo.getById(postId);

    if (post == null) throw const DatabaseException('Post not found');

    return post;
  }

  // ─── Create ────────────────────────────────────────────────

  Future<Post> create({
    required String title,
    required String content,
    required List<File> imageFiles,
  }) async {
    // Validation
    if (title.trim().isEmpty) {
      throw ArgumentError('Title must not be empty.');
    }
    if (content.trim().isEmpty) {
      throw ArgumentError('Content must not be empty.');
    }

    // Sanitize
    final cleanTitle = Sanitizers.cleanText(
      title,
      maxLength: AppConfig.maxTitleLength,
    );
    final cleanContent = Sanitizers.cleanText(
      content,
      maxLength: AppConfig.maxContentLength,
    );

    // Upload images
    final uploadedUrls = <String>[];
    for (final f in imageFiles) {
      uploadedUrls.add(
        await _storage.uploadImage(XFile(f.path), folder: 'posts'),
      );
    }

    return _repo.create(
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
  }

  // ─── Update ────────────────────────────────────────────────

  Future<Post> update({
    required String postId,
    required String title,
    required String content,
    required List<String> existingImageUrls,
    required List<File> newImageFiles,
    required List<String> imagesToDelete,
  }) async {
    // Validation
    if (title.trim().isEmpty) {
      throw ArgumentError('Title must not be empty.');
    }
    if (content.trim().isEmpty) {
      throw ArgumentError('Content must not be empty.');
    }

    // Sanitize
    final cleanTitle = Sanitizers.cleanText(
      title,
      maxLength: AppConfig.maxTitleLength,
    );
    final cleanContent = Sanitizers.cleanText(
      content,
      maxLength: AppConfig.maxContentLength,
    );

    // Delete removed images
    if (imagesToDelete.isNotEmpty) {
      await _storage.deleteImages(imagesToDelete);
    }

    // Upload new images
    final newUrls = <String>[];
    for (final f in newImageFiles) {
      newUrls.add(await _storage.uploadImage(XFile(f.path), folder: 'posts'));
    }

    // Merge and sanitize image URLs
    final allImages = [
      ...existingImageUrls,
      ...newUrls,
    ].where((u) => Sanitizers.safeImageUrl(u) != null).toList();

    return _repo.update(
      Post(
        id: postId,
        userId: SupabaseService.currentUserId,
        title: cleanTitle,
        content: cleanContent,
        images: allImages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ─── Delete ────────────────────────────────────────────────

  Future<void> delete({
    required String postId,
    required List<String> imageUrls,
  }) async {
    await _repo.delete(postId);

    if (imageUrls.isNotEmpty) {
      await _storage.deleteImages(imageUrls);
    }
  }
}
