import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error_reader.dart';
import '../../../core/paged_result.dart';
import '../../../core/secure_storage_service.dart';
import '../domain/user_profile.dart';

class ProfileApi {
  ProfileApi({ApiClient? apiClient, SecureStorageService? secureStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  static const String _usersPath = '/api/Users';
  static const String _newsletterPath = '/api/Newsletter';

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
    final String detail = _readApiErrorDetail(response.body);
    if (kDebugMode) {
      debugPrint('GET $_usersPath/$userId failed ${response.statusCode}: ${response.body}');
    }
    throw Exception('Failed to load profile (${response.statusCode}): $detail');
  }

  Future<bool> getNewCollectionSubscription(String email) async {
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return false;
    final String query = Uri(queryParameters: <String, String>{'email': trimmedEmail}).query;
    final http.Response response = await _apiClient.get('$_newsletterPath/subscription-status?$query');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return (jsonMap['isSubscribedToNewCollections'] as bool?) ?? false;
    }
    final String detail = _readApiErrorDetail(response.body);
    throw Exception('Failed to load newsletter status (${response.statusCode}): $detail');
  }

  Future<void> setNewCollectionSubscription({
    required String email,
    required bool subscribed,
  }) async {
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw Exception('Email je obavezan za newsletter pretplatu.');
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'email': trimmedEmail,
      'isSubscribedToNewCollections': subscribed,
    };
    final http.Response response = await _apiClient.post(
      '$_newsletterPath/subscribe',
      body: json.encode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String detail = _readApiErrorDetail(response.body);
      throw Exception('Failed to update newsletter status (${response.statusCode}): $detail');
    }
  }

  Future<List<NewsletterSubscriber>> getNewsletterSubscribers({
    int pageSize = 100,
  }) async {
    return PagedResult.collectAllPages<NewsletterSubscriber>(
      pageSize: pageSize,
      fetchPage: (int page, int psz) async {
        final http.Response response = await _apiClient.get(
          '$_newsletterPath/subscribers?page=$page&pageSize=$psz',
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
          return PagedResult.fromJson(
            map,
            (Map<String, dynamic> e) => NewsletterSubscriber.fromJson(e),
          );
        }
        final String detail = _readApiErrorDetail(response.body);
        throw Exception('Failed to load subscribers (${response.statusCode}): $detail');
      },
    );
  }

  /// Vlastiti profil (Buyer/Admin) — isti endpoint kao mobile aplikacija.
  Future<UserProfile> updateMe({
    required String firstName,
    required String lastName,
    required String email,
    required String userName,
    String? phone,
  }) async {
    if (await _getUserIdFromToken() == null) {
      throw Exception('No valid token');
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'Name': firstName,
      'Surname': lastName,
      'Email': email,
      'UserName': userName,
      'Phone': phone ?? '',
    };
    final http.Response response = await _apiClient.put(
      '$_usersPath/profile',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    }
    final String detail = _readApiErrorDetail(response.body);
    if (kDebugMode) {
      debugPrint('PUT $_usersPath/profile failed ${response.statusCode}: ${response.body}');
    }
    throw Exception('Failed to update profile (${response.statusCode}): $detail');
  }

  static String _readApiErrorDetail(String body) => ApiErrorReader.readDetail(body);

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
    final Object? sub = decoded['nameid'] ??
        decoded['sub'] ??
        decoded['NameIdentifier'] ??
        decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    if (sub == null) return null;
    return int.tryParse(sub.toString());
  }
}

class NewsletterSubscriber {
  const NewsletterSubscriber({
    required this.id,
    required this.email,
    required this.isSubscribedToGiveaway,
    required this.isSubscribedToNewCollections,
  });

  final int id;
  final String email;
  final bool isSubscribedToGiveaway;
  final bool isSubscribedToNewCollections;

  factory NewsletterSubscriber.fromJson(Map<String, dynamic> json) {
    return NewsletterSubscriber(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] as String?) ?? '',
      isSubscribedToGiveaway: (json['isSubscribedToGiveaway'] as bool?) ?? false,
      isSubscribedToNewCollections: (json['isSubscribedToNewCollections'] as bool?) ?? false,
    );
  }
}
