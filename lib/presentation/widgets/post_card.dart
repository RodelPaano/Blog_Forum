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

        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: () => context.push('/post/${post.id}'),

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _author(context),

              const SizedBox(height: 10),

              _content(context),

              if (post.images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),

                  child: ImageStrip(urls: post.images, size: 56),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _author(BuildContext context) {
    return AppAvatar(
      name: post.authorName,

      imageUrl: post.authorAvatar,

      radius: 18,

      showInfo: true,

      subtitle: AppDate.relative(post.createdAt),
    );
  }

  Widget _content(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
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
      ],
    );
  }
}
