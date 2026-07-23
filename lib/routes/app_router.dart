import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../middleware/auth_guard.dart';
import '../ui/pages/home_screen.dart';
import '../ui/pages/login_screen.dart';
import '../ui/pages/post_create_screen.dart';
import '../ui/pages/post_edit_screen.dart';
import '../ui/pages/post_view_screen.dart';
import '../ui/pages/profile_screen.dart';
import '../ui/pages/register_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) => AuthGuard.redirect(context, state),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/post/new', builder: (_, __) => const PostCreateScreen()),
      GoRoute(
        path: '/post/:id',
        builder: (_, s) => PostViewScreen(postId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/:id/edit',
        builder: (_, s) => PostEditScreen(postId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(child: Text('No route: ${state.uri}')),
    ),
  );
}
