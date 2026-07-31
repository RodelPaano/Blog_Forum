import 'package:blog_forum_app/models/comment.dart' show Comment;
import 'package:blog_forum_app/presentation/views/comments/comment_card.dart';
import 'package:blog_forum_app/providers/comment_provider.dart'
    show CommentProvider;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        BuildContext,
        Widget,
        StatelessWidget,
        Column,
        CrossAxisAlignment,
        Row,
        Icon,
        Icons,
        Theme;
import 'package:provider/provider.dart' show WatchContext;

class CommentSectionView extends StatelessWidget {
  const CommentSectionView({
    super.key,
    required this.postId,
    required this.onEdit,
    required this.onDelete,
  });

  final String postId;

  final Function(Comment) onEdit;

  final Function(Comment) onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<CommentProvider>();
    final comments = provider.commentsFor(postId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.forum_outlined, size: 20, color: cs.primary),
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
        if (comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: cs.outline.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'No comments yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Be the first to share your thoughts!',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
          )
        else
          ...comments.map((comment) {
            return CommentCard(
              comment: comment,
              onEdit: () => onEdit(comment),
              onDelete: () => onDelete(comment),
            );
          }),
      ],
    );
  }
}
