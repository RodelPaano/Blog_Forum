import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../models/comment.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../utils/app_diallog.dart';
import '../../utils/image_utils.dart';

/// Reusable action controller for post & comment operations.
/// Keeps pages thin — all confirmation dialogs, provider calls,
/// and navigation live here.
class PostActionsController {
  PostActionsController._();

  // ─── Post Actions ─────────────────────────────────────────────────────

  /// Delete a post with confirmation dialog, then navigate home.
  static Future<void> deletePost(
    BuildContext context, {
    required String postId,
    required List<String> imageUrls,
  }) async {
    final confirmed = await AppDialog.confirmDialog(
      context,
      title: 'Delete Post',
      subtitle: 'Are you sure? This cannot be undone.',
    );
    if (!confirmed || !context.mounted) return;

    final provider = context.read<PostProvider>();
    await provider.deletePost(postId: postId, imageUrls: imageUrls);
    if (!context.mounted) return;

    if (provider.error == null) {
      context.go('/');
    } else {
      AppDialog.showError(context, provider.error!);
    }
  }

  // ─── Comment Actions ──────────────────────────────────────────────────

  /// Delete a comment with confirmation dialog.
  static Future<void> deleteComment(
    BuildContext context, {
    required Comment comment,
  }) async {
    final confirmed = await AppDialog.confirmDialog(
      context,
      title: 'Delete Comment',
      subtitle: 'Are you sure you want to delete this comment?',
      cancelText: 'Cancel Delete',
      confirm: 'confirm',
    );
    if (!confirmed || !context.mounted) return;

    await context.read<CommentProvider>().delete(
      comment: comment,
      imageUrls: comment.images,
    );
  }

  // ─── Image Picking ────────────────────────────────────────────────────

  static final ImagePicker _picker = ImagePicker();

  /// Pick multiple images with validation. Returns the valid files.
  /// Respects [maxTotal] limit, subtracting [currentCount].
  static Future<List<File>> pickImages(
    BuildContext context, {
    required int currentCount,
    int maxTotal = AppConfig.maxImagesPerPost,
  }) async {
    final remaining = maxTotal - currentCount;
    if (remaining <= 0) {
      AppDialog.showError(context, 'Maximum of $maxTotal images allowed.');
      return [];
    }

    final picks = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 800);
    if (picks.isEmpty) return [];

    final valid = <File>[];
    final rejected = <String>[];

    for (final xFile in picks.take(remaining)) {
      if (await ImageUtils.isValidImage(xFile)) {
        valid.add(File(xFile.path));
      } else {
        rejected.add(xFile.name);
      }
    }

    if (context.mounted && rejected.isNotEmpty) {
      AppDialog.showError(
        context,
        'Skipped ${rejected.length} invalid file(s): ${rejected.join(', ')}',
      );
    }

    return valid;
  }
}
