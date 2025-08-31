import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/api_client.dart';
import '../../../core/secure_storage_service.dart';
import '../domain/user_profile.dart';

class ProfileApi {
  ProfileApi({ApiClient? apiClient, SecureStorageService? secureStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  static const String _usersPath = '/api/Users';

  Future<UserProfile> getMe() async {
    final int? userId = await _getUserIdFromToken();
    if (userId == null) {
      throw Exception('No valid token');
    }
    final http.Response response = await _apiClient.get('$_usersPath/$userId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    }
    throw Exception('Failed to load profile: ${response.statusCode}');
  }

  Future<UserProfile> updateMe({required String firstName, required String lastName, String? avatarUrl}) async {
    final int? userId = await _getUserIdFromToken();
    if (userId == null) {
      throw Exception('No valid token');
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'Name': firstName,
      'Surname': lastName,
      // Email is required by DTO but we do not change it here; backend likely ignores nulls
    };
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Backend expects byte[] Image; if we only have URL, skip updating image
    }
    final http.Response response = await _apiClient.put(
      '$_usersPath/$userId',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    }
    throw Exception('Failed to update profile: ${response.statusCode}');
  }

  Future<bool> isAdmin() async {
    final String? token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) return false;
    try {
      final Map<String, dynamic> decoded = JwtDecoder.decode(token);
      final List<String> roles = _extractRoles(decoded);
      return roles.map((String r) => r.toLowerCase()).contains('admin');
    } catch (_) {
      return false;
    }
  }

  List<String> _extractRoles(Map<String, dynamic> decoded) {
    final List<String> roles = <String>[];
    void addRoleValue(Object? value) {
      if (value == null) return;
      if (value is List) {
        for (final Object e in value) {
          final String v = e.toString();
          if (v.isNotEmpty) roles.add(v);
        }
      } else {
        final String v = value.toString();
        if (v.isNotEmpty) roles.add(v);
      }
    }

    addRoleValue(decoded['role']);
    addRoleValue(decoded['roles']);
    addRoleValue(decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']);
    addRoleValue(decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role']);
    return roles;
  }
  Future<int?> _getUserIdFromToken() async {
    final String? token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) return null;
    final Map<String, dynamic> decoded = JwtDecoder.decode(token);
    final Object? sub = decoded['nameid'] ?? decoded['sub'] ?? decoded['NameIdentifier'];
    if (sub == null) return null;
    return int.tryParse(sub.toString());
  }
}

