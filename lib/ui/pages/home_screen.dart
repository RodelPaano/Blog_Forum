import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
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
        final maxContentWidth = _isMobile ? double.infinity : 1100.0;

        return Scaffold(
          key: _drawerKey,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.article_rounded,
                    color: cs.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Blog Forum',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: _isMobile ? 18 : 20,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            elevation: 0,
            surfaceTintColor: cs.surface,
            backgroundColor: cs.surface,
            automaticallyImplyLeading: _isMobile,
            actions: _isMobile
                ? null
                : [
                    if (!loggedIn) ...[
                      TextButton.icon(
                        onPressed: () => context.push('/login'),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Sign In'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/register'),
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Sign Up'),
                      ),
                      const SizedBox(width: 24),
                    ] else ...[
                      TextButton.icon(
                        onPressed: () => context.push('/profile'),
                        icon: const Icon(Icons.person_rounded, size: 18),
                        label: const Text('Profile'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/post/new'),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('New Post'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamed('/login');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Logout'),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ],
          ),
          drawer: _isMobile ? _buildDrawer(loggedIn) : null,
          body: RefreshIndicator(
            onRefresh: () => posts.loadInitial(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                    if (posts.error != null && posts.posts.isEmpty)
                      ErrorBanner(
                        message: posts.error!,
                        onRetry: () => posts.loadInitial(),
                      )
                    else if (posts.isLoading && posts.posts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(60.0),
                          child: CircularProgressIndicator(color: cs.primary),
                        ),
                      )
                    else if (posts.posts.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 100,
                          horizontal: 24,
                        ),
                        child: EmptyState(
                          icon: Icons.article_outlined,
                          title: 'No posts yet',
                          subtitle: 'Be the first to write something!',
                        ),
                      )
                    else
                      ...List.generate(
                        posts.posts.length + (posts.hasMore ? 1 : 0),
                        (i) {
                          if (i >= posts.posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          final Post p = posts.posts[i];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: _isMobile ? 10 : 14,
                            ),
                            child: PostCard(post: p),
                          );
                        },
                      ),
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
                    letterSpacing: -0.5,
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
                    letterSpacing: -0.3,
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

  Widget _buildDrawer(bool loggedIn) {
    final auth = context.watch<AuthProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.35),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: cs.primary,
                        backgroundImage:
                            user?.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user!.userMetadata!['avatar_url'])
                            : null,
                        child: user?.userMetadata?['avatar_url'] == null
                            ? Icon(
                                Icons.person_rounded,
                                color: cs.onPrimary,
                                size: 26,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loggedIn
                                  ? (user?.userMetadata?['full_name'] ?? 'User')
                                  : 'Guest',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loggedIn ? 'Welcome back!' : 'Explore posts',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _DrawerTile(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  isSelected: true,
                  onTap: () {
                    _drawerKey.currentState?.closeDrawer();
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (mounted) context.go('/');
                    });
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Divider(height: 1),
                ),
                if (loggedIn) ...[
                  _DrawerTile(
                    icon: Icons.person_outlined,
                    title: 'Profile',
                    onTap: () {
                      _drawerKey.currentState?.closeDrawer();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted) context.push('/profile');
                      });
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.edit_outlined,
                    title: 'New Post',
                    onTap: () {
                      _drawerKey.currentState?.closeDrawer();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted) context.push('/post/new');
                      });
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Divider(height: 1),
                  ),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    iconColor: cs.error,
                    textColor: cs.error,
                    onTap: () async {
                      _drawerKey.currentState?.closeDrawer();
                      await auth.signOut();
                      if (!mounted) return;
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted) context.go('/');
                      });
                    },
                  ),
                ] else ...[
                  _DrawerTile(
                    icon: Icons.login_outlined,
                    title: 'Sign In',
                    onTap: () {
                      _drawerKey.currentState?.closeDrawer();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted) context.push('/login');
                      });
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.person_add_outlined,
                    title: 'Sign Up',
                    onTap: () {
                      _drawerKey.currentState?.closeDrawer();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted) context.push('/register');
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    this.isSelected = false,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.45)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color:
                  iconColor ?? (isSelected ? cs.primary : cs.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor ?? (isSelected ? cs.primary : cs.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
