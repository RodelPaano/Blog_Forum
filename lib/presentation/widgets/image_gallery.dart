import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageStrip extends StatelessWidget {
  const ImageStrip({
    super.key,
    required this.urls,
    this.size = 64,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  final List<String> urls;
  final double size;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          return AppNetworkImage(
            url: urls[index],
            width: size,
            height: size,
            borderRadius: borderRadius,
            fit: fit,
          );
        },
      ),
    );
  }
}

class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),

      shrinkWrap: true,

      clipBehavior: Clip.none,

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,

        mainAxisSpacing: 6,

        crossAxisSpacing: 6,
      ),

      itemCount: urls.length,

      itemBuilder: (context, index) {
        return AppNetworkImage(
          url: urls[index],

          width: double.infinity,

          height: double.infinity,

          borderRadius: 8,

          fit: BoxFit.cover,
        );
      },
    );
  }
}

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  final String url;

  final double width;

  final double height;

  final double borderRadius;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),

      child: CachedNetworkImage(
        imageUrl: url,

        width: width,

        height: height,

        fit: fit,

        fadeInDuration: const Duration(milliseconds: 200),

        placeholder: (context, url) {
          return Container(
            width: width,

            height: height,

            color: cs.surfaceContainerHighest,

            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },

        errorWidget: (context, url, error) {
          return Container(
            width: width,

            height: height,

            color: cs.surfaceContainerHighest,

            child: Icon(
              Icons.broken_image_outlined,

              size: 24,

              color: cs.outline,
            ),
          );
        },
      ),
    );
  }
}
