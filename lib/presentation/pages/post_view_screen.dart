import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/supabase_client.dart';
import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../utils/app_diallog.dart';
import '../../utils/image_utils.dart';
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
  final _comment = TextEditingController();
  final List<File> _newFiles = [];
  final List<String> _existingImages = [];
  final List<String> _toDelete = [];
  final _picker = ImagePicker();
  Comment? _editingComment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().getPostById(widget.postId);
      context.read<CommentProvider>().loadFor(widget.postId);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _resetForm() {
    _comment.clear();
    _newFiles.clear();
    _existingImages.clear();
    _toDelete.clear();
    setState(() => _editingComment = null);
  }

  Future<void> _submitComment() async {
    if (_comment.text.trim().isEmpty) return;
    final provider = context.read<CommentProvider>();

    if (_editingComment != null) {
      await provider.update(
        original: _editingComment!,
        content: _comment.text.trim(),
        existingImages: _existingImages,
        newFiles: _newFiles,
        toDelete: _toDelete,
      );
    } else {
      await provider.add(
        postId: widget.postId,
        content: _comment.text.trim(),
        imageFiles: _newFiles,
      );
    }

    if (!mounted) return;
    if (provider.error == null) _resetForm();
  }

  void _startEditComment(Comment comment) {
    setState(() {
      _editingComment = comment;
      _comment.text = comment.content;
      _existingImages
        ..clear()
        ..addAll(comment.images);
    });
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await AppDialog.confirmDialog(
      context,
      title: 'Delete Comment',
      subtitle: 'Are you sure you want to delete this comment?',
      cancelText: 'Cancel Delete',
      confirm: 'confirm',
    );
    if (!confirmed || !mounted) return;

    await context.read<CommentProvider>().delete(
      comment: comment,
      imageUrls: comment.images,
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await AppDialog.confirmDialog(
      context,
      title: 'Delete Post',
      subtitle: 'Are you sure? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    final postProvider = context.read<PostProvider>();
    await postProvider.deletePost(
      postId: widget.postId,
      imageUrls: postProvider.selectedPost!.images,
    );
    if (!mounted) return;

    if (postProvider.error == null) {
      context.go('/');
    } else {
      AppDialog.showError(context, postProvider.error!);
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    final valid = <File>[];
    final rejected = <String>[];

    for (final xFile in picked) {
      if (await ImageUtils.isValidImage(xFile)) {
        valid.add(File(xFile.path));
      } else {
        rejected.add(xFile.name);
      }
    }

    if (!mounted) return;

    if (rejected.isNotEmpty) {
      AppDialog.showError(
        context,
        'Skipped ${rejected.length} invalid file(s): ${rejected.join(', ')}',
      );
    }

    if (valid.isNotEmpty) {
      setState(() => _newFiles.addAll(valid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

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
              onPressed: _deletePost,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostDetailView(post: post),
            const SizedBox(height: 24),
            if (loggedIn) ...[
              CommentFormView(
                controller: _comment,
                newFiles: _newFiles,
                existingImages: _existingImages,
                toDelete: _toDelete,
                editingComment: _editingComment,
                onSubmit: _submitComment,
                onCancel: _editingComment != null ? _resetForm : null,
                onChanged: () => setState(() {}),
                onPick: _pickImages,
              ),
              const SizedBox(height: 16),
              CommentSectionView(
                postId: post.id,
                onEdit: _startEditComment,
                onDelete: _deleteComment,
              ),
            ] else
              const LoginRequiredWidget(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
