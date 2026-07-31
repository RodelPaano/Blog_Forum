import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../utils/app_diallog.dart';
import '../controllers/post_actions_controller.dart';
import '../view/posts/post_edit_view.dart';

class PostEditScreen extends StatefulWidget {
  const PostEditScreen({super.key, required this.postId});
  final String postId;

  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
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
      // ✅ I-update ang provider DITO — bago pa man mag-pop
      Navigator.pop(context, true);

      context.pop(); // ← wala nang return value, hindi na kailangan
    } else {
      final err = provider.error ?? 'Update failed';
      AppDialog.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final busy = context.watch<PostProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: PostEditView(
        formKey: _formKey,
        titleController: _titleController,
        contentController: _contentController,
        newFiles: _newFiles,
        existingImages: _existingImages,
        isLoading: busy,
        onPickImages: _pickImages,
        onRemoveNew: _removeNewImage,
        onRemoveExisting: _removeExistingImage,
        onSubmit: _updatePost,
      ),
    );
  }
}
