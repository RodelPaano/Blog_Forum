import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/config.dart';
import '../../../core/validators.dart';
import '../../widgets/app_button_type.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/mobile_page.dart';

class PostCreateView extends StatelessWidget {
  const PostCreateView({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.imageFiles,
    required this.isLoading,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final List<File> imageFiles;
  final bool isLoading;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MobilePage(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    maxLength: AppConfig.maxTitleLength,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title_rounded, color: cs.primary),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: Validators.postTitle,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    maxLines: 8,
                    minLines: 4,
                    maxLength: AppConfig.maxContentLength,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.notes_rounded, color: cs.primary),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: Validators.postContent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_rounded,
                        size: 20,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Post Images',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onPickImages,
                        icon: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                        label: Text(
                          'Add Images',
                          style: TextStyle(color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ImagePickerWidget(
                    files: imageFiles,
                    onPick: onPickImages,
                    onRemoveNew: onRemoveImage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Publish Post',
              isLoading: isLoading,
              onPressed: onSubmit,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
