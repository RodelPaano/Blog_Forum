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
  int _selectedNavIndex = 0;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        _isMobile = constraints.maxWidth < 800;
        return Scaffold(
          appBar: _isMobile
              ? AppBar(
                  title: const Text('Blog Forum'),
                  elevation: 2,
                )
              : _buildDesktopAppBar(loggedIn),
          drawer: _isMobile ? _buildDrawer(loggedIn) : null,
          body: RefreshIndicator(
            onRefresh: () => posts.loadInitial(),
            child: _buildBody(posts, loggedIn),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(bool loggedIn) {
    return AppBar(
      title: const Text('Blog Forum'),
      elevation: 2,
      actions: [
        if (!loggedIn) ...[
          TextButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Sign In'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => context.push('/register'),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Sign Up'),
          ),
          const SizedBox(width: 16),
        ] else ...[
          TextButton.icon(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_rounded),
            label: const Text('Profile'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => context.push('/post/new'),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('New Post'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildDrawer(bool loggedIn) {
    final auth = context.watch<AuthProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: user?.userMetadata?['avatar_url'] != null
                      ? NetworkImage(user!.userMetadata!['avatar_url'])
                      : null,
                  child: user?.userMetadata?['avatar_url'] == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loggedIn
                            ? (user?.userMetadata?['full_name'] ?? 'User')
                            : 'Guest',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loggedIn ? 'Welcome back!' : 'Explore amazing posts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedNavIndex == 0
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_outlined,
                color: _selectedNavIndex == 0
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            title: Text(
              'Home',
              style: TextStyle(
                fontWeight: _selectedNavIndex == 0
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: _selectedNavIndex == 0
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            selected: _selectedNavIndex == 0,
            onTap: () {
              setState(() => _selectedNavIndex = 0);
              context.go('/');
              Navigator.pop(context);
            },
          ),
          if (loggedIn) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(
                color: Colors.grey[300],
                thickness: 1,
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outlined, color: Colors.blue),
              ),
              title: const Text('Profile'),
              onTap: () {
                context.push('/profile');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.green),
              ),
              title: const Text('New Post'),
              onTap: () {
                context.push('/post/new');
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(
                color: Colors.grey[300],
                thickness: 1,
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red),
              ),
              title: const Text('Logout'),
              onTap: () async {
                await auth.signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(
                color: Colors.grey[300],
                thickness: 1,
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.login_outlined, color: Colors.purple),
              ),
              title: const Text('Sign In'),
              onTap: () {
                context.push('/login');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_outlined, color: Colors.orange),
              ),
              title: const Text('Sign Up'),
              onTap: () {
                context.push('/register');
                Navigator.pop(context);
              },
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBody(PostProvider posts, bool loggedIn) {
    if (posts.error != null && posts.posts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          ErrorBanner(
            message: posts.error!,
            onRetry: () => posts.loadInitial(),
          ),
        ],
      );
    }
    if (posts.isLoading && posts.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (posts.posts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.article_outlined,
            title: 'No posts yet',
            subtitle: 'Be the first to write something!',
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: posts.posts.length + (posts.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= posts.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final Post p = posts.posts[i];
        return PostCard(post: p);
      },
    );
  }
}