import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/post_provider.dart';
import '../../utils/app_diallog.dart';
import '../controllers/post_actions_controller.dart';
import '../view/posts/post_create_view.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: PostCreateView(
        formKey: _formKey,
        titleController: _titleController,
        contentController: _contentController,
        imageFiles: _imageFiles,
        isLoading: isLoading,
        onPickImages: _pickImages,
        onRemoveImage: _removeImage,
        onSubmit: _submitPost,
      ),
    );
  }
}
