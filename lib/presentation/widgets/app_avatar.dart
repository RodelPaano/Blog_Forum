import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,

    required this.name,

    this.imageUrl,

    this.radius = 18,

    this.icon,

    this.showInfo = false,

    this.subtitle,

    this.nameFontSize,
  });

  final String? name;

  final String? imageUrl;

  final double radius;

  final IconData? icon;

  // show avatar + name + subtitle
  final bool showInfo;

  final String? subtitle;

  final double? nameFontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final avatar = CircleAvatar(
      radius: radius,

      backgroundColor: cs.primaryContainer,

      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl!)
          : null,

      child: imageUrl == null || imageUrl!.isEmpty
          ? icon != null
                ? Icon(icon, size: radius, color: cs.onPrimaryContainer)
                : Text(
                    _initial,

                    style: TextStyle(
                      color: cs.onPrimaryContainer,

                      fontSize: radius * .75,

                      fontWeight: FontWeight.w700,
                    ),
                  )
          : null,
    );

    // avatar only
    if (!showInfo) {
      return avatar;
    }

    // avatar + information

    return Row(
      children: [
        avatar,

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                name?.trim().isNotEmpty == true ? name! : 'Anonymous',

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: nameFontSize ?? 14,

                  fontWeight: FontWeight.w600,

                  color: cs.onSurface,
                ),
              ),

              if (subtitle != null)
                Text(
                  subtitle!,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String get _initial {
    final value = name?.trim();

    if (value == null || value.isEmpty) {
      return '?';
    }

    return value.characters.first.toUpperCase();
  }
}
