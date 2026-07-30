import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/comment.dart';
import '../../widgets/image_picker_widget.dart';

class CommentFormView extends StatelessWidget {
  const CommentFormView({
    super.key,
    required this.controller,
    this.focusNode,
    required this.newFiles,
    required this.existingImages,
    required this.toDelete,
    required this.onSubmit,
    required this.onChanged,
    required this.onPick,
    this.editingComment,
    this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final List<File> newFiles;
  final List<String> existingImages;
  final List<String> toDelete;
  final Comment? editingComment;

  final VoidCallback onSubmit;
  final VoidCallback onChanged;
  final VoidCallback onPick;
  final VoidCallback? onCancel;

  bool get _isEditing => editingComment != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isDesktop ? 22 : 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isEditing
                      ? Icons.edit_note_rounded
                      : Icons.mode_comment_outlined,
                  color: cs.onPrimaryContainer,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _isEditing ? "Edit Comment" : "Add a Comment",
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Editing Active",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEditing
                          ? "Modify your response below"
                          : "Share your thoughts with the community",
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// TEXT FIELD
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: isDesktop ? 3 : 2,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            style: TextStyle(fontSize: isDesktop ? 15 : 14, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: _isEditing
                  ? "Update your comment..."
                  : "Write a constructive comment...",
              hintStyle: TextStyle(
                color: cs.outline.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              filled: true,
              fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: cs.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// IMAGE PICKER
          ImagePickerWidget(
            files: newFiles,
            existingUrls: existingImages,
            onPick: onPick,
            onRemoveExisting: (index) {
              toDelete.add(existingImages[index]);
              existingImages.removeAt(index);
              onChanged();
            },
            onRemoveNew: (index) {
              newFiles.removeAt(index);
              onChanged();
            },
          ),

          const SizedBox(height: 16),

          Divider(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),

          const SizedBox(height: 14),

          /// BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onCancel != null) ...[
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text("Cancel"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              FilledButton.icon(
                onPressed: onSubmit,
                icon: Icon(
                  _isEditing ? Icons.check_rounded : Icons.send_rounded,
                  size: 18,
                ),
                label: Text(
                  _isEditing ? "Update Comment" : "Post Comment",
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
