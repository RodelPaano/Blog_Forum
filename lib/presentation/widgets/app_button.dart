import 'package:flutter/material.dart';

enum AppButtonType { filled, tonal, elevated, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.filled,
    this.icon,
    this.isLoading = false,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? callback = isLoading ? null : onPressed;

    const loading = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    final Widget child = isLoading ? loading : Text(label);

    switch (type) {
      case AppButtonType.filled:
        return icon == null
            ? FilledButton(onPressed: callback, style: style, child: child)
            : FilledButton.icon(
                onPressed: callback,
                style: style,
                icon: isLoading ? loading : Icon(icon),
                label: Text(label),
              );

      case AppButtonType.tonal:
        return icon == null
            ? FilledButton.tonal(
                onPressed: callback,
                style: style,
                child: child,
              )
            : FilledButton.tonalIcon(
                onPressed: callback,
                style: style,
                icon: isLoading ? loading : Icon(icon),
                label: Text(label),
              );

      case AppButtonType.elevated:
        return icon == null
            ? ElevatedButton(onPressed: callback, style: style, child: child)
            : ElevatedButton.icon(
                onPressed: callback,
                style: style,
                icon: isLoading ? loading : Icon(icon),
                label: Text(label),
              );

      case AppButtonType.outlined:
        return icon == null
            ? OutlinedButton(onPressed: callback, style: style, child: child)
            : OutlinedButton.icon(
                onPressed: callback,
                style: style,
                icon: isLoading ? loading : Icon(icon),
                label: Text(label),
              );

      case AppButtonType.text:
        return icon == null
            ? TextButton(onPressed: callback, style: style, child: child)
            : TextButton.icon(
                onPressed: callback,
                style: style,
                icon: isLoading ? loading : Icon(icon),
                label: Text(label),
              );
    }
  }
}
