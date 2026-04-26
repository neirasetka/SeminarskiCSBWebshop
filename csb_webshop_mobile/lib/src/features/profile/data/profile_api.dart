import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      final Map<String, dynamic> jsonMap =
          json.decode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    }
    final String detail = _readApiErrorDetail(response.body);
    if (kDebugMode) {
      debugPrint(
        'GET $_usersPath/$userId failed ${response.statusCode}: ${response.body}',
      );
    }
    throw Exception(
      'Failed to load profile (${response.statusCode}): $detail',
    );
  }

  Future<UserProfile> updateMe({
    required String firstName,
    required String lastName,
    required String email,
    required String userName,
    String? phone,
    String? imageBase64,
  }) async {
    final int? userId = await _getUserIdFromToken();
    if (userId == null) {
      throw Exception('No valid token');
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'Name': firstName,
      'Surname': lastName,
      'Email': email,
      'UserName': userName,
      'Phone': phone ?? '',
    };
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      body['Image'] = _stripDataUrlIfPresent(imageBase64);
    }
    // PUT /api/Users/profile — vlastiti profil; /api/Users/{id} je Admin-only i šalje UserUpsertRequest.
    final http.Response response = await _apiClient.put(
      '$_usersPath/profile',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> jsonMap =
            json.decode(response.body) as Map<String, dynamic>;
        return UserProfile.fromJson(jsonMap);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('updateMe: JSON parse / map failed: $e\n$st');
          debugPrint('Response body: ${response.body}');
        }
        rethrow;
      }
    }
    final String detail = _readApiErrorDetail(response.body);
    if (kDebugMode) {
      debugPrint(
        'PUT $_usersPath/profile failed ${response.statusCode}: ${response.body}',
      );
    }
    throw Exception(
      'Failed to update profile (${response.statusCode}): $detail',
    );
  }

  /// Čita poruku iz ASP.NET odgovora: `{"error":"..."}`, ValidationProblemDetails `errors`, ili `title`/`detail`.
  static String _readApiErrorDetail(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return '(prazan odgovor)';
    }
    try {
      final Object? decoded = json.decode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final Object? simple = decoded['error'];
        if (simple != null && simple.toString().isNotEmpty) {
          return simple.toString();
        }
        final Object? errors = decoded['errors'];
        if (errors is Map<String, dynamic>) {
          final List<String> parts = <String>[];
          for (final MapEntry<String, dynamic> e in errors.entries) {
            final Object? v = e.value;
            if (v is List) {
              for (final Object x in v) {
                parts.add('${e.key}: $x');
              }
            } else if (v != null) {
              parts.add('${e.key}: $v');
            }
          }
          if (parts.isNotEmpty) {
            return parts.join('; ');
          }
        }
        final Object? detail = decoded['detail'];
        if (detail != null && detail.toString().isNotEmpty) {
          return detail.toString();
        }
        final Object? title = decoded['title'];
        if (title != null && title.toString().isNotEmpty) {
          return title.toString();
        }
      }
    } catch (_) {
      /* nije JSON */
    }
    const int maxLen = 500;
    if (trimmed.length > maxLen) {
      return '${trimmed.substring(0, maxLen)}…';
    }
    return trimmed;
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
    addRoleValue(
      decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'],
    );
    addRoleValue(
      decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role'],
    );
    return roles;
  }

  /// API očekuje čisti base64 u JSON-u za byte[] (ne data:image/...;base64,...).
  static String _stripDataUrlIfPresent(String raw) {
    final int comma = raw.indexOf(',');
    if (comma != -1 && raw.toLowerCase().contains('base64')) {
      return raw.substring(comma + 1).trim();
    }
    return raw.trim();
  }

  Future<int?> _getUserIdFromToken() async {
    final String? token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) return null;
    final Map<String, dynamic> decoded = JwtDecoder.decode(token);
    final Object? sub =
        decoded['nameid'] ??
        decoded['sub'] ??
        decoded['NameIdentifier'] ??
        decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    if (sub == null) return null;
    return int.tryParse(sub.toString());
  }
}
