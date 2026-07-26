import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../utils/date_utils.dart';
import 'app_avatar.dart';
import 'image_gallery.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.onEdit,
    required this.onDelete,
  });

  final Comment comment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOwner = context.read<AuthProvider>().profile?.id == comment.userId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  name: comment.authorName,
                  imageUrl: comment.authorAvatar,
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        AppDate.display(comment.createdAt, comment.updatedAt),
                        style: TextStyle(color: cs.outline, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content),
            if (comment.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              ImageStrip(urls: comment.images, size: 70),
            ],
          ],
        ),
      ),
    );
  }
}
