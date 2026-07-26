import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 18,
    this.icon,
    this.showName = false, // false by default — hindi masisira existing usages
    this.nameFontSize,
  });

  final String? name;
  final String? imageUrl;
  final double radius;
  final IconData? icon;
  final bool showName;
  final double? nameFontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = imageUrl;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      backgroundImage: url != null && url.isNotEmpty
          ? CachedNetworkImageProvider(url)
          : null,
      child: url == null || url.isEmpty
          ? icon != null
                ? Icon(icon, size: radius, color: cs.onPrimaryContainer)
                : Text(
                    _initial,
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: radius * 0.75,
                      fontWeight: FontWeight.w700,
                    ),
                  )
          : null,
    );

    if (!showName) return avatar;

    // Wraps avatar + name label
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 6),
        Text(
          name?.trim().isNotEmpty == true ? name! : '?',
          style: TextStyle(
            fontSize: nameFontSize ?? radius * 0.65,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String get _initial {
    final value = name?.trim();
    if (value == null || value.isEmpty) return '?';
    return value.characters.first.toUpperCase();
  }
}
