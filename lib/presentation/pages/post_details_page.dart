import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase_client.dart';
import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';

import '../controllers/post_actions_controller.dart';
import '../views/comments/comment_section_view.dart';
import '../views/comments/comment_sheet.dart';
import '../views/posts/post_detail_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/login_required_widget.dart';

class PostDetailsPage extends StatefulWidget {
  const PostDetailsPage({super.key, required this.postId});
  final String postId;

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<PostProvider>().getPostById(widget.postId);
      context.read<CommentProvider>().loadFor(widget.postId);
    });
  }

  @override
  void dispose() {
    context.read<PostProvider>().clearSelectedPost();
    super.dispose();
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
          CommentSheet(postId: widget.postId, editingComment: editingComment),
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
              onPressed: () async {
                final provider = context.read<PostProvider>();
                await context.push('/post/${post.id}/edit');

                if (!mounted) return;

                await provider.getPostById(widget.postId);
              },
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


