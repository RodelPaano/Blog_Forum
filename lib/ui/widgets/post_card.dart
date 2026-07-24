import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../utils/date_utils.dart';

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
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4), width: 1),
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: post.authorAvatar != null
                        ? CachedNetworkImageProvider(post.authorAvatar!)
                        : null,
                    child: post.authorAvatar == null
                        ? Text(
                            (post.authorName ?? '?').characters.first.toUpperCase(),
                            style: TextStyle(color: cs.onPrimaryContainer, fontSize: 14),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName ?? 'Anonymous',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface),
                        ),
                        Text(
                          AppDate.relative(post.createdAt),
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface, height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
              ),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: post.images[i],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.broken_image, size: 20, color: cs.outline),
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
      ),
    );
  }
}