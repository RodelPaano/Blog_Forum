import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/validators.dart';
import '../../../models/post.dart';
import '../../../providers/post_provider.dart';
import '../../../utils/app_dialog.dart';
import '../../controllers/post_actions_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/mobile_page.dart';

class PostEditView extends StatefulWidget {
  const PostEditView({super.key, required this.postId});

  final String postId;

  @override
  State<PostEditView> createState() => _PostEditViewState();
}

class _PostEditViewState extends State<PostEditView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final List<String> _existingImages = [];
  final List<File> _newFiles = [];
  final List<String> _toDelete = [];
  Post? _original;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPost());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final provider = context.read<PostProvider>();
    final post = await provider.fetchPost(widget.postId);

    if (!mounted) return;
    if (post == null) {
      if (provider.error != null) {
        AppDialog.showError(context, provider.error!);
      }
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _original = post;
      _titleController.text = post.title;
      _contentController.text = post.content;
      _existingImages
        ..clear()
        ..addAll(post.images);
      _newFiles.clear();
      _toDelete.clear();
      _loading = false;
    });
  }

  Future<void> _pickImages() async {
    final valid = await PostActionsController.pickImages(
      context,
      currentCount: _existingImages.length + _newFiles.length,
    );
    if (valid.isNotEmpty) setState(() => _newFiles.addAll(valid));
  }

  void _removeNewImage(int index) {
    setState(() => _newFiles.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _toDelete.add(_existingImages.removeAt(index)));
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate() || _original == null) return;

    final provider = context.read<PostProvider>();
    final updated = await provider.updatePost(
      postId: _original!.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      existingImageUrls: _existingImages,
      newImageFiles: _newFiles,
      imagesToDelete: _toDelete,
    );

    if (!mounted) return;

    if (updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully')),
      );
      context.pop();
    } else {
      final err = provider.error ?? 'Update failed';
      AppDialog.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    files: _newFiles,
                    existingUrls: _existingImages,
                    onPick: _pickImages,
                    onRemoveNew: _removeNewImage,
                    onRemoveExisting: _removeExistingImage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Save Changes',
              isLoading: isLoading,
              onPressed: _updatePost,
              icon: Icons.save_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
