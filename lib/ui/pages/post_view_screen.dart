import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/logger.dart';
import '../../core/supabase_client.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../repositories/post_repository.dart';
import '../../utils/date_utils.dart';
import '../widgets/app_avatar.dart';
import '../widgets/comment_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/image_gallery.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/loading_button.dart';

class PostViewScreen extends StatefulWidget {
  const PostViewScreen({super.key, required this.postId});
  final String postId;
  @override
  State<PostViewScreen> createState() => _PostViewScreenState();
}

class _PostViewScreenState extends State<PostViewScreen> {
  final _repo = PostRepository();
  final _comment = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _newFiles = [];
  final List<String> _existingImages = [];
  final List<String> _toDelete = [];

  Post? _post;
  Comment? _editingComment;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.getById(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = p;
        _loading = false;
      });
      if (p != null) {
        // ignore: use_build_context_synchronously
        context.read<CommentProvider>().loadFor(p.id);
      }
    } catch (e) {
      AppLogger.error('Load post', e);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitComment() async {
    if (_post == null) return;
    if (_editingComment != null) {
      final ok = await context.read<CommentProvider>().update(
        original: _editingComment!,
        content: _comment.text.trim(),
        existingImages: _existingImages,
        newFiles: _newFiles,
        toDelete: _toDelete,
      );
      if (!mounted) return;
      if (ok) _resetForm();
      return;
    }
    if (_comment.text.trim().isEmpty && _newFiles.isEmpty) return;
    setState(() => _busy = true);
    final res = await context.read<CommentProvider>().add(
      postId: _post!.id,
      content: _comment.text.trim(),
      imageFiles: _newFiles,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res != null) _resetForm();
  }

  void _resetForm() {
    _comment.clear();
    _newFiles.clear();
    _existingImages.clear();
    _toDelete.clear();
    setState(() => _editingComment = null);
  }

  void _startEditComment(Comment c) {
    _comment.text = c.content;
    setState(() {
      _editingComment = c;
      _existingImages
        ..clear()
        ..addAll(c.images);
      _newFiles.clear();
      _toDelete.clear();
    });
  }

  Future<void> _deleteComment(Comment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<CommentProvider>().delete(
        comment: c,
        imageUrls: c.images,
      );
      if (mounted) context.pop();
      return;
    }
  }

  Future<void> _deletePost() async {
    if (_post == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final p = _post!;
    final removed = await context.read<PostProvider>().deletePost(
      postId: p.id,
      imageUrls: p.images,
    );
    if (removed && mounted) context.pop();
  }

  Future<void> _pick() async {
    final max = _editingComment != null
        ? AppConfig.maxImagesPerComment
        : AppConfig.maxImagesPerPost;
    final remain = max - (_existingImages.length + _newFiles.length);
    if (remain <= 0) return;
    final picks = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 800);
    if (picks.isEmpty) return;
    setState(() {
      _newFiles.addAll(picks.take(remain).map((x) => File(x.path)));
    });
  }

  Future<void> _handleEdit() async {
    if (_post == null) return;
    final updated = await context.push<Post>('/post/${_post!.id}/edit');
    if (!mounted) return;
    if (updated != null) {
      setState(() => _post = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully')),
      );
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final post = _post;
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Post not found',
        ),
      );
    }

    final isOwner = SupabaseService.currentUserId == post.userId;
    final comments = context.watch<CommentProvider>().commentsFor(post.id);
    final commentsLoading = context.watch<CommentProvider>().isLoadingFor(
      post.id,
    );
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_rounded),
              onPressed: _handleEdit,
            ),
          if (isOwner)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _deletePost,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            name: post.authorName,
                            imageUrl: post.authorAvatar,
                            radius: 20,
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName ?? 'Anonymous',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  AppDate.display(
                                    post.createdAt,
                                    post.updatedAt,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        post.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (post.images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ImageGrid(urls: post.images),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (context.watch<AuthProvider>().isLoggedIn) ...[
                  Row(
                    children: [
                      Icon(Icons.comment_outlined, size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Comments (${comments.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (commentsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (comments.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No comments yet',
                        subtitle: 'Be the first to share your thoughts',
                      ),
                    ),
                  ...comments.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CommentCard(
                        comment: c,
                        onEdit: () => _startEditComment(c),
                        onDelete: () => _deleteComment(c),
                      ),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: cs.outline),
                        const SizedBox(height: 12),
                        Text(
                          'Sign in to view and post comments',
                          style: TextStyle(
                            fontSize: 15,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Sign In'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text("Don't have an account? Sign up"),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (context.watch<AuthProvider>().isLoggedIn) _buildCommentComposer(),
        ],
      ),
    );
  }

  Widget _buildCommentComposer() {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_editingComment != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Editing comment',
                      style: TextStyle(fontSize: 13, color: cs.primary),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetForm,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _comment,
              maxLines: 3,
              minLines: 1,
              maxLength: AppConfig.maxCommentLength,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ImagePickerWidget(
              files: _newFiles,
              existingUrls: _existingImages,
              maxImages: _editingComment != null
                  ? AppConfig.maxImagesPerComment
                  : AppConfig.maxImagesPerPost,
              onPick: _pick,
              onRemoveNew: (i) => setState(() => _newFiles.removeAt(i)),
              onRemoveExisting: (i) {
                setState(() {
                  _toDelete.add(_existingImages.removeAt(i));
                });
              },
            ),
            const SizedBox(height: 10),
            LoadingFilledButton(
              label: _editingComment != null
                  ? 'Update Comment'
                  : 'Post Comment',
              isLoading: _busy,
              onPressed: _submitComment,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
