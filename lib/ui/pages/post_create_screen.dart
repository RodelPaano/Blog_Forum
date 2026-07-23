import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/validators.dart';
import '../../providers/post_provider.dart';
import '../widgets/image_picker_widget.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});
  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _files = [];

  Future<void> _pick() async {
    final remain = AppConfig.maxImagesPerPost - _files.length;
    if (remain <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum number of images reached for this post.'),
        ),
      );
      return;
    }
    final picks = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 800,
    );
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
      context.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            FilledButton.icon(
              onPressed: busy ? null : _submit,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
