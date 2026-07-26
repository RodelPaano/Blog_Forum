import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/exceptions.dart';
import '../../core/logger.dart';
import '../../core/validators.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../repositories/post_repository.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/loading_button.dart';
import '../widgets/mobile_page.dart';

class PostEditScreen extends StatefulWidget {
  const PostEditScreen({super.key, required this.postId});
  final String postId;
  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
  final _form = GlobalKey<FormState>();
  final _repo = PostRepository();
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _content = TextEditingController();

  final List<String> _existingImages = [];
  final List<File> _newFiles = [];
  final List<String> _toDelete = [];
  Post? _original;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.getById(widget.postId);
      if (!mounted) return;
      if (p == null) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _original = p;
        _title.text = p.title;
        _content.text = p.content;
        _existingImages.addAll(p.images);
        _loading = false;
      });
    } on AppException catch (e) {
      AppLogger.error('Load post for edit', e);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pick() async {
    final remain =
        AppConfig.maxImagesPerPost -
        (_existingImages.length + _newFiles.length);
    if (remain <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum number of images reached.')),
      );
      return;
    }
    final picks = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 800);
    if (picks.isEmpty) return;
    setState(() {
      _newFiles.addAll(picks.take(remain).map((x) => File(x.path)));
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _original == null) return;
    final res = await context.read<PostProvider>().updatePost(
      postId: _original!.id,
      title: _title.text.trim(),
      content: _content.text.trim(),
      existingImageUrls: _existingImages,
      newImageFiles: _newFiles,
      imagesToDelete: _toDelete,
    );
    if (!mounted) return;
    if (res != null) {
      context.pop(res);
    } else {
      final err = context.read<PostProvider>().error ?? 'Update failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final busy = context.watch<PostProvider>().isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: MobilePage(
        child: Form(
          key: _form,
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
                      controller: _title,
                      maxLength: AppConfig.maxTitleLength,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(
                          Icons.title_rounded,
                          color: cs.primary,
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
                      validator: Validators.postTitle,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _content,
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
                          onPressed: _pick,
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
                      onPick: _pick,
                      onRemoveNew: (i) => setState(() => _newFiles.removeAt(i)),
                      onRemoveExisting: (i) {
                        setState(() {
                          _toDelete.add(_existingImages.removeAt(i));
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LoadingFilledButton(
                label: 'Save Changes',
                isLoading: busy,
                onPressed: _submit,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
