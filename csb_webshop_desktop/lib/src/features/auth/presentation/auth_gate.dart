import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../domain/auth_session.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({
    super.key,
    required this.child,
    this.requiredRoles = const <String>[],
  });

  final Widget child;
  final List<String> requiredRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AuthSession?> authState = ref.watch(authControllerProvider);
    return authState.when(
      data: (AuthSession? session) {
        if (session == null || session.isExpired) {
          return const LoginScreen(embedded: true);
        }
        if (requiredRoles.isNotEmpty && !session.hasAnyRole(requiredRoles)) {
          return _UnauthorizedView(requiredRoles: requiredRoles);
        }
        return child;
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object err, StackTrace _) => _AuthErrorView(
        message: err.toString(),
      ),
    );
  }
}

class _UnauthorizedView extends StatelessWidget {
  const _UnauthorizedView({required this.requiredRoles});

  final List<String> requiredRoles;

  @override
  Widget build(BuildContext context) {
    final String rolesText = requiredRoles.join(', ');
    return Scaffold(
      appBar: AppBar(title: const Text('Pristup odbijen')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Za ovaj ekran potrebna je uloga: $rolesText',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthErrorView extends StatelessWidget {
  const _AuthErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Greška')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Dogodila se greška pri provjeri prijave:\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

