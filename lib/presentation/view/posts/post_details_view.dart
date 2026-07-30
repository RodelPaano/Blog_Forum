import 'package:flutter/material.dart';

import '../../../models/post.dart';
import '../../../utils/date_utils.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/image_gallery.dart';

class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isEdited =
        (post.updatedAt.millisecondsSinceEpoch -
                    post.createdAt.millisecondsSinceEpoch)
                .abs() >=
            1000;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// AUTHOR ROW
          Row(
            children: [
              AppAvatar(
                name: post.authorName,
                imageUrl: post.authorAvatar,
                radius: isDesktop ? 22 : 20,
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
                            post.authorName?.trim().isNotEmpty == true
                                ? post.authorName!
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
                      AppDate.display(post.createdAt, post.updatedAt),
                      style: TextStyle(
                        color: cs.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// TITLE
          SelectableText(
            post.title,
            style: TextStyle(
              fontSize: isDesktop ? 22 : 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          /// CONTENT
          SelectableText(
            post.content,
            style: TextStyle(
              fontSize: isDesktop ? 15 : 14,
              height: 1.5,
              color: cs.onSurface,
            ),
          ),

          if (post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ImageGrid(urls: post.images),
            ),
        ],
      ),
    );
  }
}
