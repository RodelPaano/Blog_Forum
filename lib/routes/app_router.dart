import 'package:blog_forum_app/presentation/pages/home_screen.dart'
    show HomeScreen;
import 'package:blog_forum_app/presentation/pages/login_screen.dart'
    show LoginScreen;
import 'package:blog_forum_app/presentation/pages/post_create_screen.dart'
    show PostCreateScreen;
import 'package:blog_forum_app/presentation/pages/post_edit_screen.dart'
    show PostEditScreen;
import 'package:blog_forum_app/presentation/pages/post_view_screen.dart'
    show PostViewScreen;
import 'package:blog_forum_app/presentation/pages/profile_screen.dart'
    show ProfileScreen;
import 'package:blog_forum_app/presentation/pages/register_screen.dart'
    show RegisterScreen;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../middleware/auth_guard.dart';

class AppRouter {
  AppRouter._();

  static bool _isInitialLoad = true;

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (_isInitialLoad) {
        _isInitialLoad = false;
        if (state.matchedLocation != '/') return '/';
      }
      return AuthGuard.redirect(context, state);
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/post/new',
        builder: (_, __) => const PostCreateScreen(),
      ),
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
