import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../utils/date_utils.dart';

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
                CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.authorAvatar != null
                      ? CachedNetworkImageProvider(comment.authorAvatar!)
                      : null,
                  child: comment.authorAvatar == null
                      ? Text(
                          (comment.authorName ?? '?').characters.first
                              .toUpperCase(),
                        )
                      : null,
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
                        AppDate.relative(comment.createdAt),
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
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: comment.images.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: comment.images[i],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: cs.surfaceContainerHigh,
                          child: const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
