import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

// ─── AppBar (Desktop only) ──────────────────────────────────────────────────

class NavigationWidget extends StatelessWidget implements PreferredSizeWidget {
  const NavigationWidget({
    super.key,
    required this.isMobile,
    required this.loggedIn,
  });

  final bool isMobile;
  final bool loggedIn;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      surfaceTintColor: cs.surface,
      backgroundColor: cs.surface,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.article_rounded, color: cs.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Blog Forum',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      actions: [
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
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 24),
        ],
      ],
    );
  }
}
