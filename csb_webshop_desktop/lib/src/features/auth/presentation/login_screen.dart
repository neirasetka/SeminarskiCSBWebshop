import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import '../domain/auth_session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.embedded = false,
    this.redirectPath = '/',
  });

  final bool embedded;
  final String redirectPath;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late final ProviderSubscription<AsyncValue<AuthSession?>> _authListener;

  @override
  void initState() {
    super.initState();
    _authListener = ref.listenManual<AsyncValue<AuthSession?>>(
      authControllerProvider,
      (AsyncValue<AuthSession?>? previous, AsyncValue<AuthSession?> next) {
        if (next.hasError) {
          final String message = next.error?.toString() ?? 'Nepoznata greška';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } else if (next.hasValue && next.value != null && !widget.embedded) {
          context.go(widget.redirectPath);
        }
      },
    );
  }

  @override
  void dispose() {
    _authListener.close();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AuthSession?> authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Prijava')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Dobrodošli na CocoSunBags Webshop',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Korisničko ime'),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Unesite korisničko ime';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Lozinka',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Unesite lozinku';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _submit(ref),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Prijavi se'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Nemate račun?'),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Registrirajte se'),
                        ),
                      ],
                    ),
                    if (!widget.embedded)
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Natrag na početnu'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }
}

