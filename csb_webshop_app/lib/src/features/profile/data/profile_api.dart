import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/user_profile.dart';

class ProfileApi {
  ProfileApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _mePath = '/api/Users/me';

  Future<UserProfile> getMe() async {
    final http.Response response = await _apiClient.get(_mePath);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    }
    throw Exception('Failed to load profile: ${response.statusCode}');
  }

  Future<UserProfile> updateMe({required String firstName, required String lastName, String? avatarUrl}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      if (avatarUrl != null) 'avatar': avatarUrl,
    };
    final http.Response response = await _apiClient.put(
      _mePath,
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    }
    throw Exception('Failed to update profile: ${response.statusCode}');
  }
}

