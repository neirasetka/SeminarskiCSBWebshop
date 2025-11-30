import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/secure_storage_service.dart';
import '../../profile/application/user_profile_provider.dart';
import '../data/auth_api.dart';
import '../domain/auth_session.dart';
import 'admin_role_provider.dart';

final Provider<AuthApi> authApiProvider = Provider<AuthApi>((Ref ref) {
  return AuthApi();
});

class AuthController extends AsyncNotifier<AuthSession?> implements Listenable {
  AuthController() : _listeners = <VoidCallback>{};

  late final AuthApi _api;
  late final SecureStorageService _storage;
  final Set<VoidCallback> _listeners;

  @override
  Future<AuthSession?> build() async {
    _api = ref.read(authApiProvider);
    _storage = SecureStorageService();
    return _loadSession();
  }

  Future<AuthSession?> _loadSession() async {
    final String? token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;
    return AuthSession.fromStoredToken(token);
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncLoading<AuthSession?>();
    try {
      final AuthSession session = await _api.login(username: username, password: password);
      await _storage.saveToken(session.token);
      state = AsyncData<AuthSession?>(session);
      ref.invalidate(userProfileProvider);
      ref.invalidate(adminRoleProvider);
    } catch (e, st) {
      state = AsyncError<AuthSession?>(e, st);
    } finally {
      _notify();
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading<AuthSession?>();
    await _storage.clearToken();
    state = const AsyncData<AuthSession?>(null);
    ref.invalidate(userProfileProvider);
    ref.invalidate(adminRoleProvider);
    _notify();
  }

  void _notify() {
    for (final VoidCallback listener in _listeners) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

final AsyncNotifierProvider<AuthController, AuthSession?> authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

