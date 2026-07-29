import 'package:blog_forum_app/presentation/widgets/app_button_type.dart';
import 'package:flutter/material.dart'
    show
        AlertDialog,
        BuildContext,
        Text,
        showDialog,
        ScaffoldMessenger,
        SnackBar;
import 'package:flutter/widgets.dart';

class AppDialog {
  static Future<bool> confirmDialog(
    BuildContext context, {
    required String title,
    String? subtitle,
    String cancelText = 'Cancel',
    String confirm = 'Confirm',
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: subtitle != null ? Text(subtitle) : null,
        actions: [
          AppButton(
            label: cancelText,
            type: AppButtonType.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: confirm,
            type: AppButtonType.tonal,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return ok ?? false;
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
