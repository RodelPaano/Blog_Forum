import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../view/posts/post_view_list.dart';
import '../widgets/navigation_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final cs = Theme.of(context).colorScheme;

    // Desktop: web-style top navigation bar
    if (isDesktop) {
      return Scaffold(
        appBar: NavigationWidget(
          isMobile: false,
          loggedIn: loggedIn,
        ),
        body: PostListView(loggedIn: loggedIn),
      );
    }

    // Mobile: bottom navigation bar like a native app
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: cs.surface,
        backgroundColor: cs.surface,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.article_rounded,
                color: cs.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Blog Forum',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: PostListView(loggedIn: loggedIn),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => _onMobileNavTap(index, loggedIn),
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        elevation: 3,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          if (loggedIn) ...[
            const NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(Icons.add_box_rounded),
              label: 'New Post',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.logout_rounded, color: cs.error),
              selectedIcon: Icon(Icons.logout_rounded, color: cs.error),
              label: 'Logout',
            ),
          ] else ...[
            const NavigationDestination(
              icon: Icon(Icons.login_rounded),
              selectedIcon: Icon(Icons.login_rounded),
              label: 'Sign In',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_add_outlined),
              selectedIcon: Icon(Icons.person_add_rounded),
              label: 'Sign Up',
            ),
          ],
        ],
      ),
    );
  }

  void _onMobileNavTap(int index, bool loggedIn) {
    if (index == 0) {
      // Home — already here, just reset index
      setState(() => _currentIndex = 0);
      return;
    }

    if (loggedIn) {
      switch (index) {
        case 1: // New Post
          context.push('/post/new');
          break;
        case 2: // Profile
          context.push('/profile');
          break;
        case 3: // Logout
          _handleLogout();
          break;
      }
    } else {
      switch (index) {
        case 1: // Sign In
          context.push('/login');
          break;
        case 2: // Sign Up
          context.push('/register');
          break;
      }
    }

    // Reset to home after navigation
    setState(() => _currentIndex = 0);
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) context.go('/');
  }
}
