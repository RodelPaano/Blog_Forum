import 'dart:io';

import 'package:blog_forum_app/utils/app_diallog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase_client.dart';
import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';

import '../controllers/post_actions_controller.dart';
import '../view/comments/comment_form_view.dart';
import '../view/comments/comment_section_view.dart';
import '../view/posts/post_details_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/login_required_widget.dart';

class PostViewScreen extends StatefulWidget {
  const PostViewScreen({super.key, required this.postId});
  final String postId;

  @override
  State<PostViewScreen> createState() => _PostViewScreenState();
}

class _PostViewScreenState extends State<PostViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().getPostById(widget.postId);
      context.read<CommentProvider>().loadFor(widget.postId);
    });
  }

  void _openCommentSheet({Comment? editingComment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _CommentSheet(postId: widget.postId, editingComment: editingComment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final cs = Theme.of(context).colorScheme;

    if (postProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final post = postProvider.selectedPost;
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Post not found',
        ),
      );
    }

    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final isOwner = SupabaseService.currentUserId == post.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Post',
              onPressed: () => context.push('/post/${post.id}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Post',
              onPressed: () => PostActionsController.deletePost(
                context,
                postId: widget.postId,
                imageUrls: post.images,
              ),
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostDetailView(post: post),
                const SizedBox(height: 24),
                if (loggedIn) ...[
                  CommentSectionView(
                    postId: post.id,
                    onEdit: (c) => _openCommentSheet(editingComment: c),
                    onDelete: (c) => PostActionsController.deleteComment(
                      context,
                      comment: c,
                    ),
                  ),
                ] else
                  const LoginRequiredWidget(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: loggedIn
          ? FloatingActionButton.extended(
              heroTag: 'commentFab',
              onPressed: () => _openCommentSheet(),
              icon: const Icon(Icons.comment_outlined),
              label: const Text('Comment'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            )
          : null,
    );
  }
}

// ─── Self-contained bottom sheet for adding/editing comments ─────────────

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.postId, this.editingComment});
  final String postId;
  final Comment? editingComment;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<File> _newFiles = [];
  final List<String> _existingImages = [];
  final List<String> _toDelete = [];
  bool _submitting = false;

  bool get _isEditing => widget.editingComment != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _controller.text = widget.editingComment!.content;
      _existingImages.addAll(widget.editingComment!.images);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (_isEditing) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final valid = await PostActionsController.pickImages(
      context,
      currentCount: _existingImages.length + _newFiles.length,
    );
    if (valid.isNotEmpty) setState(() => _newFiles.addAll(valid));
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty && _newFiles.isEmpty) return;

    setState(() => _submitting = true);
    final provider = context.read<CommentProvider>();

    if (_isEditing) {
      await provider.update(
        original: widget.editingComment!,
        content: _controller.text.trim(),
        existingImages: _existingImages,
        newFiles: _newFiles,
        toDelete: _toDelete,
      );
    } else {
      await provider.add(
        postId: widget.postId,
        content: _controller.text.trim(),
        imageFiles: _newFiles,
      );
    }

    if (!mounted) return;
    if (provider.error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
      AppDialog.showError(context, provider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AbsorbPointer(
                absorbing: _submitting,
                child: Opacity(
                  opacity: _submitting ? 0.6 : 1.0,
                  child: CommentFormView(
                    controller: _controller,
                    focusNode: _focusNode,
                    newFiles: _newFiles,
                    existingImages: _existingImages,
                    toDelete: _toDelete,
                    editingComment: widget.editingComment,
                    onSubmit: _submit,
                    onCancel: () => Navigator.of(context).pop(),
                    onChanged: () => setState(() {}),
                    onPick: _pickImages,
                  ),
                ),
              ),
              if (_submitting) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
