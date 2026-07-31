import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../models/post.dart';
import '../../../providers/post_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/post_card.dart';
import '../home_header_view.dart';

class PostListView extends StatefulWidget {
  const PostListView({super.key, required this.loggedIn});

  final bool loggedIn;

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  final ScrollController _scroll = ScrollController();

  bool get _isMobile {
    return MediaQuery.of(context).size.width < 800;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadMore();
    });

    _scroll.addListener(_loadMore);
  }

  void _loadMore() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - AppConstants.loadMoreThreshold) {
      context.read<PostProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();

    return RefreshIndicator(
      onRefresh: provider.refreshPosts,
      child: ListView(
        controller: _scroll,
        padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 12 : 24,
          vertical: _isMobile ? 12 : 20,
        ),
        children: [
          HomeHeaderView(loggedIn: widget.loggedIn),

          const SizedBox(height: 24),

          if (provider.error != null && provider.posts.isEmpty)
            ErrorBanner(
              message: provider.error!,
              onRetry: provider.refreshPosts,
            )
          else if (provider.isLoading && provider.posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 100),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: EmptyState(
                icon: Icons.article_outlined,
                title: 'No posts yet',
                subtitle: 'Be the first to create one.',
              ),
            )
          else
            ...provider.posts.map(
              (Post post) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PostCard(post: post),
              ),
            ),

          if (provider.hasMore)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
