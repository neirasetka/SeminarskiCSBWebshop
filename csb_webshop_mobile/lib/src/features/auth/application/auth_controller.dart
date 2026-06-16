import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/secure_storage_service.dart';
import '../data/auth_api.dart';
import '../domain/auth_session.dart';

final Provider<AuthApi> authApiProvider = Provider<AuthApi>((Ref ref) {
  return AuthApi();
});

class AuthController extends AsyncNotifier<AuthSession?> {
  AuthApi get _api => ref.read(authApiProvider);
  final SecureStorageService _storage = SecureStorageService();

  @override
  Future<AuthSession?> build() async {
    return _loadSession();
  }

  Future<AuthSession?> _loadSession() async {
    final String? token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;
    return AuthSession.fromStoredToken(token);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    try {
      final AuthSession session = await _api.login(
        username: username,
        password: password,
      );
      await _storage.saveToken(session.token);
      state = AsyncData<AuthSession?>(session);
    } catch (e, st) {
      state = AsyncError<AuthSession?>(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading<AuthSession?>();
    //await ref.read(cartProvider.notifier).discardActiveCartOnLogout();
    await _storage.clearToken();
    state = const AsyncData<AuthSession?>(null);
  }
  
}

final AsyncNotifierProvider<AuthController, AuthSession?> authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);