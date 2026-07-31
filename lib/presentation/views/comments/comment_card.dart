import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/comment.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/date_utils.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/image_gallery.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isEdited =
        (comment.updatedAt.millisecondsSinceEpoch -
                comment.createdAt.millisecondsSinceEpoch)
            .abs() >=
        1000;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppAvatar(
                name: comment.authorName,
                imageUrl: comment.authorAvatar,
                radius: isDesktop ? 19 : 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.authorName?.trim().isNotEmpty == true
                                ? comment.authorName!
                                : 'Anonymous',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isDesktop ? 15 : 14,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isEdited) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'edited',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppDate.display(comment.createdAt, comment.updatedAt),
                      style: TextStyle(color: cs.outline, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: cs.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          const Text('Edit', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: cs.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(fontSize: 14, color: cs.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            comment.content,
            style: TextStyle(
              fontSize: isDesktop ? 15 : 14,
              height: 1.45,
              color: cs.onSurface,
            ),
          ),
          if (comment.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            ImageStrip(urls: comment.images, size: isDesktop ? 80 : 70),
          ],
        ],
      ),
    );
  }
}
