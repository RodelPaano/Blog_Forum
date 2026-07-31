import 'dart:io';

import 'package:blog_forum_app/models/comment.dart';
import 'package:blog_forum_app/providers/comment_provider.dart';
import 'package:blog_forum_app/utils/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/post_actions_controller.dart';
import 'comment_form_view.dart';

/// Bottom sheet for adding or editing a comment on a post.
/// Self-contained: owns its form state and submit logic.
class CommentSheet extends StatefulWidget {
  const CommentSheet({super.key, required this.postId, this.editingComment});

  final String postId;
  final Comment? editingComment;

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<File> _newFiles = [];
  final List<String> _existingImages = [];
  final List<String> _toDelete = [];
  bool _submitting = false;

  bool get _isEditing => widget.editingComment != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _controller.text = widget.editingComment!.content;
      _existingImages.addAll(widget.editingComment!.images);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (_isEditing) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final valid = await PostActionsController.pickImages(
      context,
      currentCount: _existingImages.length + _newFiles.length,
    );
    if (valid.isNotEmpty) setState(() => _newFiles.addAll(valid));
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty && _newFiles.isEmpty) return;

    setState(() => _submitting = true);
    final provider = context.read<CommentProvider>();

    if (_isEditing) {
      await provider.update(
        original: widget.editingComment!,
        content: _controller.text.trim(),
        existingImages: _existingImages,
        newFiles: _newFiles,
        toDelete: _toDelete,
      );
    } else {
      await provider.add(
        postId: widget.postId,
        content: _controller.text.trim(),
        imageFiles: _newFiles,
      );
    }

    if (!mounted) return;
    if (provider.error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
      AppDialog.showError(context, provider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AbsorbPointer(
                absorbing: _submitting,
                child: Opacity(
                  opacity: _submitting ? 0.6 : 1.0,
                  child: CommentFormView(
                    controller: _controller,
                    focusNode: _focusNode,
                    newFiles: _newFiles,
                    existingImages: _existingImages,
                    toDelete: _toDelete,
                    editingComment: widget.editingComment,
                    onSubmit: _submit,
                    onCancel: () => Navigator.of(context).pop(),
                    onChanged: () => setState(() {}),
                    onPick: _pickImages,
                  ),
                ),
              ),
              if (_submitting) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
