import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'token_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final DateTime? expiresAtUtc;
  final List<String> roles;

  const AuthState({
    required this.isAuthenticated,
    this.accessToken,
    this.expiresAtUtc,
    this.roles = const [],
  });

  factory AuthState.unauthenticated() => const AuthState(isAuthenticated: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated());

  Future<void> loadFromStorage() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }
    try {
      final decoded = JwtDecoder.decode(token);
      final expMs = (decoded['exp'] is int) ? decoded['exp'] as int : null;
      final expiresAt = expMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expMs * 1000, isUtc: true)
          : null;
      if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt)) {
        await TokenStorage.clear();
        state = AuthState.unauthenticated();
        return;
      }
      final rolesDynamic = decoded['role'];
      final roles = rolesDynamic is List
          ? rolesDynamic.map((e) => e.toString()).toList()
          : rolesDynamic is String
              ? <String>[rolesDynamic]
              : <String>[];
      state = AuthState(
        isAuthenticated: true,
        accessToken: token,
        expiresAtUtc: expiresAt,
        roles: roles,
      );
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> setTokens({required String accessToken, String? refreshToken}) async {
    await TokenStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await loadFromStorage();
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier();
  notifier.loadFromStorage();
  return notifier;
});

