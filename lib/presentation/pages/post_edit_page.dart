import 'package:flutter/material.dart';

import '../views/posts/post_edit_view.dart';

class PostEditPage extends StatelessWidget {
  const PostEditPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: PostEditView(postId: postId),
    );
  }
}
