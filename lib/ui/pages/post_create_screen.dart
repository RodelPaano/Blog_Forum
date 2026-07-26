import 'dart:io';
import 'package:blog_forum_app/ui/widgets/image_picker_widget.dart'
    show ImagePickerWidget;
import 'package:blog_forum_app/ui/widgets/loading_button.dart'
    show LoadingFilledButton;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/validators.dart';
import '../../providers/post_provider.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateDrawerState();
}

class _PostCreateDrawerState extends State<PostCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _files = [];

  Future<void> _pick() async {
    final remain = AppConfig.maxImagesPerPost - _files.length;
    if (remain <= 0) return;
    final picks = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 800);
    if (picks.isEmpty) return;
    setState(() {
      _files.addAll(picks.take(remain).map((x) => File(x.path)));
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final res = await context.read<PostProvider>().createPost(
      title: _title.text.trim(),
      content: _content.text.trim(),
      imageFiles: _files,
    );
    if (!mounted) return;
    if (res != null) {
      Navigator.pop(context); // close drawer
    } else {
      final err = context.read<PostProvider>().error ?? 'Failed to create post';
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
    final busy = context.watch<PostProvider>().isLoading;
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      width: MediaQuery.of(context).size.width > 600 ? 480 : double.infinity,
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, color: cs.primary),
                  const SizedBox(width: 12),
                  Text(
                    'New Post',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ─── Form ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _title,
                        maxLength: AppConfig.maxTitleLength,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: Validators.postTitle,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _content,
                        maxLines: 8,
                        minLines: 4,
                        maxLength: AppConfig.maxContentLength,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes),
                        ),
                        validator: Validators.postContent,
                      ),
                      const SizedBox(height: 8),
                      ImagePickerWidget(
                        files: _files,
                        existingUrls: const [],
                        onPick: _pick,
                        onRemoveNew: (i) => setState(() => _files.removeAt(i)),
                        onRemoveExisting: (_) {},
                      ),
                      const SizedBox(height: 24),
                      LoadingFilledButton(
                        label: 'Publish',
                        isLoading: busy,
                        onPressed: _submit,
                        icon: Icons.send,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
