import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AuthGuard {
  AuthGuard._();

  static String? redirect(BuildContext context, GoRouterState state) {
    final auth = context.read<AuthProvider>();
    final loggedIn = auth.isLoggedIn;
    final goingToAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (auth.status == AuthStatus.unknown) return null;
    if (!loggedIn && !goingToAuth) return '/login';
    if (loggedIn && goingToAuth) return '/';
    return null;
  }
}
