import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/navigation_widget.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _drawerKey = GlobalKey<ScaffoldState>();
  bool _isMobile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadInitial();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
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
    final posts = context.watch<PostProvider>();
    final auth = context.watch<AuthProvider>();
    final loggedIn = auth.isLoggedIn;
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _isMobile = constraints.maxWidth < 800;

        return Scaffold(
          key: _drawerKey,
          appBar: NavigationWidget(
            isMobile: _isMobile,
            loggedIn: loggedIn,
            drawerKey: _drawerKey,
          ),
          drawer: _isMobile
              ? HomeDrawer(loggedIn: loggedIn, drawerKey: _drawerKey)
              : null,
          body: RefreshIndicator(
            onRefresh: () => posts.loadInitial(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _isMobile ? double.infinity : 1100.0,
                ),
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.symmetric(
                    horizontal: _isMobile ? 0 : 20,
                    vertical: _isMobile ? 8 : 20,
                  ),
                  children: [
                    if (!_isMobile) _buildHero(loggedIn, cs),
                    if (!_isMobile) const SizedBox(height: 28),
                    if (_isMobile) _buildMobileHeader(loggedIn, cs),
                    _buildPostList(posts, cs),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Post List ─────────────────────────────────────────────

  Widget _buildPostList(PostProvider posts, ColorScheme cs) {
    if (posts.error != null && posts.posts.isEmpty) {
      return ErrorBanner(
        message: posts.error!,
        onRetry: () => posts.loadInitial(),
      );
    }

    if (posts.isLoading && posts.posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(60.0),
        child: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    if (posts.posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
        child: const EmptyState(
          icon: Icons.article_outlined,
          title: 'No posts yet',
          subtitle: 'Be the first to write something!',
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(posts.posts.length, (i) {
          final Post p = posts.posts[i];
          return Padding(
            padding: EdgeInsets.only(bottom: _isMobile ? 10 : 14),
            child: PostCard(post: p),
          );
        }),
        if (posts.hasMore)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: cs.primary,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Hero / Header ─────────────────────────────────────────

  Widget _buildHero(bool loggedIn, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loggedIn ? 'Welcome back!' : 'Discover Stories',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: 0,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loggedIn
                      ? 'Share your thoughts and connect with others'
                      : 'Explore amazing posts from our community',
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              loggedIn ? Icons.edit_rounded : Icons.explore_rounded,
              size: 36,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(bool loggedIn, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loggedIn ? 'Welcome back!' : 'Discover Stories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loggedIn ? 'Share your thoughts' : 'Explore amazing posts',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              loggedIn ? Icons.edit_rounded : Icons.explore_rounded,
              size: 22,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
