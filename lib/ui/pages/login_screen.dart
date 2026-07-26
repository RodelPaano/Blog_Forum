import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../widgets/loading_button.dart';
import '../widgets/mobile_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      context.go('/');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () => context.go('/'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('Home'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MobilePage(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.forum_rounded, size: 64, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to your account',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 24),
              LoadingFilledButton(
                label: 'Sign In',
                isLoading: auth.isBusy,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text("Don't have an account? Sign up"),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Continue as Guest / Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
