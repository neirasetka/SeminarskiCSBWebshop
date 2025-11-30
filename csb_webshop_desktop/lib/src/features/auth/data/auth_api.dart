import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/auth_session.dart';

class AuthApi {
  AuthApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _tokenPath = '/api/Users/Token';

  Future<AuthSession> login({required String username, required String password}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'UserName': username,
      'Password': password,
    };
    final http.Response response = await _apiClient.post(
      _tokenPath,
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return AuthSession.fromTokenResponse(jsonMap);
    }
    throw Exception('Prijava nije uspjela (${response.statusCode}).');
  }
}

