import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/comment.dart';
import '../../widgets/image_picker_widget.dart';

class CommentFormView extends StatelessWidget {
  const CommentFormView({
    super.key,
    required this.controller,
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
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        .1,
                      ),
                      child: Icon(
                        Icons.comment_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? "Edit Comment" : "Add a Comment",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditing
                                ? "Update your comment"
                                : "Share your thoughts",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// TEXT FIELD
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Write your comment...",
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// IMAGE SECTION TITLE
                Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Images",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

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

                const SizedBox(height: 22),

                Divider(color: Colors.grey.shade300, height: 1),

                const SizedBox(height: 18),

                /// BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(110, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),

                    if (onCancel != null) const SizedBox(width: 12),

                    FilledButton.icon(
                      onPressed: onSubmit,
                      icon: Icon(_isEditing ? Icons.check : Icons.send_rounded),
                      label: Text(
                        _isEditing ? "Update Comment" : "Post Comment",
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(180, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
