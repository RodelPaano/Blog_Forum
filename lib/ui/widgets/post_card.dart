import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../utils/date_utils.dart';
import 'app_avatar.dart';
import 'image_gallery.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(name: post.authorName, imageUrl: post.authorAvatar),
                  const SizedBox(width: 10),
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
                          AppDate.relative(post.createdAt),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 10),
                ImageStrip(urls: post.images, size: 56),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
