import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AuthGuard {
  AuthGuard._();

  static String? redirect(BuildContext context, GoRouterState state) {
    final auth = context.read<AuthProvider>();
    final loggedIn = auth.isLoggedIn;
    final location = state.matchedLocation;

    if (auth.status == AuthStatus.unknown) return null;

    final isAuthRoute = location == '/login' || location == '/register';
    final isProtectedRoute = location == '/post/new' ||
        location.endsWith('/edit') ||
        location == '/profile';

    if (!loggedIn && isProtectedRoute) return '/login';
    if (loggedIn && isAuthRoute) return '/';

    return null;
  }
}
