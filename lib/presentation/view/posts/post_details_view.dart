import 'package:flutter/material.dart';

import '../../../models/post.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/image_gallery.dart';

class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cs.surface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          AppAvatar(
            name: post.authorName,

            imageUrl: post.authorAvatar,

            radius: 20,

            showInfo: true,
          ),

          const SizedBox(height: 16),

          Text(
            post.title,

            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          Text(post.content),

          if (post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),

              child: ImageGrid(urls: post.images),
            ),
        ],
      ),
    );
  }
}
