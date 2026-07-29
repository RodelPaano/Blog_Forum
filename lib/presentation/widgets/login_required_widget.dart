import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginRequiredWidget extends StatelessWidget {
  const LoginRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline_rounded, size: 52, color: cs.primary),

          const SizedBox(height: 16),

          Text('Login Required', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 8),

          Text(
            'Sign in or create an account to view comments and join the discussion.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Sign In'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => context.push('/register'),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
