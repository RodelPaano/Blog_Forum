import 'package:blog_forum_app/models/comment.dart' show Comment;
import 'package:blog_forum_app/presentation/view/comments/comment_card.dart';
import 'package:blog_forum_app/providers/comment_provider.dart'
    show CommentProvider;
import 'package:flutter/material.dart'
    show BuildContext, Widget, StatelessWidget, Column;
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
    final provider = context.watch<CommentProvider>();

    final comments = provider.commentsFor(postId);

    return Column(
      children: comments.map((comment) {
        return CommentCard(
          comment: comment,

          onEdit: () {
            onEdit(comment);
          },

          onDelete: () {
            onDelete(comment);
          },
        );
      }).toList(),
    );
  }
}
