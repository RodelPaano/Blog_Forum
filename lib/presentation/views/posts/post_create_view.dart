import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/validators.dart';
import '../../../providers/post_provider.dart';
import '../../../utils/app_dialog.dart';
import '../../controllers/post_actions_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/mobile_page.dart';

class PostCreateView extends StatefulWidget {
  const PostCreateView({super.key});

  @override
  State<PostCreateView> createState() => _PostCreateViewState();
}

class _PostCreateViewState extends State<PostCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<File> _imageFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final valid = await PostActionsController.pickImages(
      context,
      currentCount: _imageFiles.length,
    );
    if (valid.isNotEmpty) setState(() => _imageFiles.addAll(valid));
  }

  void _removeImage(int index) {
    setState(() => _imageFiles.removeAt(index));
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PostProvider>();
    final success = await provider.createPost(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      imageFiles: _imageFiles,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published successfully!')),
      );
      context.go('/');
    } else if (provider.error != null) {
      AppDialog.showError(context, provider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLoading = context.watch<PostProvider>().isLoading;

    return MobilePage(
      child: Form(
        key: _formKey,
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
                    controller: _titleController,
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
                    controller: _contentController,
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
                        onPressed: _pickImages,
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
                    files: _imageFiles,
                    onPick: _pickImages,
                    onRemoveNew: _removeImage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Publish Post',
              isLoading: isLoading,
              onPressed: _submitPost,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
