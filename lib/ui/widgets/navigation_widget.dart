import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import 'app_avatar.dart';

// ─── AppBar ────────────────────────────────────────────────────────────────

class NavigationWidget extends StatelessWidget implements PreferredSizeWidget {
  const NavigationWidget({
    super.key,
    required this.isMobile,
    required this.loggedIn,
    required this.drawerKey,
  });

  final bool isMobile;
  final bool loggedIn;
  final GlobalKey<ScaffoldState> drawerKey;

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                  fontSize: isMobile ? 18 : 20,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              tooltip: 'Menu',
              onPressed: () => drawerKey.currentState?.openDrawer(),
            ),
        ],
      ),
      actions: isMobile
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

// ─── Drawer ────────────────────────────────────────────────────────────────

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    required this.loggedIn,
    required this.drawerKey,
  });

  final bool loggedIn;
  final GlobalKey<ScaffoldState> drawerKey;

  void _close(BuildContext context, VoidCallback action) {
    drawerKey.currentState?.closeDrawer();
    Future.delayed(const Duration(milliseconds: 150), action);
  }

  @override
  Widget build(BuildContext context) {
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
                // ─── Header ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.35),
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: loggedIn
                            ? (user?.userMetadata?['full_name'] as String?)
                            : 'Guest',
                        imageUrl: user?.userMetadata?['avatar_url'] as String?,
                        radius: 26,
                        icon: Icons.person_rounded,
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

                // ─── Menu Items ──────────────────────────────
                _DrawerTile(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  isSelected: true,
                  onTap: () => _close(context, () {
                    if (context.mounted) context.go('/');
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Divider(height: 1),
                ),
                if (loggedIn) ...[
                  _DrawerTile(
                    icon: Icons.person_outlined,
                    title: 'Profile',
                    onTap: () => _close(context, () {
                      if (context.mounted) context.push('/profile');
                    }),
                  ),
                  _DrawerTile(
                    icon: Icons.edit_outlined,
                    title: 'New Post',
                    onTap: () => _close(context, () {
                      if (context.mounted) context.push('/post/new');
                    }),
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
                      drawerKey.currentState?.closeDrawer();
                      await auth.signOut();
                      if (context.mounted) context.go('/');
                    },
                  ),
                ] else ...[
                  _DrawerTile(
                    icon: Icons.login_outlined,
                    title: 'Sign In',
                    onTap: () => _close(context, () {
                      if (context.mounted) context.push('/login');
                    }),
                  ),
                  _DrawerTile(
                    icon: Icons.person_add_outlined,
                    title: 'Sign Up',
                    onTap: () => _close(context, () {
                      if (context.mounted) context.push('/register');
                    }),
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

// ─── Drawer Tile ───────────────────────────────────────────────────────────

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
