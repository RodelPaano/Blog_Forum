import 'package:blog_forum_app/presentation/pages/home_page.dart' show HomePage;
import 'package:blog_forum_app/presentation/pages/login_page.dart'
    show LoginPage;
import 'package:blog_forum_app/presentation/pages/post_create_page.dart'
    show PostCreatePage;
import 'package:blog_forum_app/presentation/pages/post_edit_page.dart'
    show PostEditPage;
import 'package:blog_forum_app/presentation/pages/post_details_page.dart'
    show PostDetailsPage;
import 'package:blog_forum_app/presentation/pages/profile_page.dart'
    show ProfilePage;
import 'package:blog_forum_app/presentation/pages/register_page.dart'
    show RegisterPage;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_guard.dart';

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
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/post/new', builder: (_, __) => const PostCreatePage()),
      GoRoute(
        path: '/post/:id',
        builder: (_, s) => PostDetailsPage(postId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/:id/edit',
        builder: (_, s) => PostEditPage(postId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(child: Text('No route: ${state.uri}')),
    ),
  );
}
