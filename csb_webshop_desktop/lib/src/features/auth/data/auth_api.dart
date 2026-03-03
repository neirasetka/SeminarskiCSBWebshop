import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/auth_session.dart';

class AuthApi {
  AuthApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _tokenPath = '/api/Users/Token';
  static const String _registerPath = '/api/Users/Register';

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

  Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String email,
    String? phone,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'Name': name,
      'Surname': surname,
      'Email': email,
      'Phone': phone ?? '',
      'UserName': username,
      'Password': password,
      'PasswordConfirmation': passwordConfirmation,
      'Roles': <int>[2], // Default role: Kupac (Customer)
    };
    final http.Response response = await _apiClient.post(
      _registerPath,
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return jsonMap;
    }
    // Try to parse error message from response
    String errorMessage = 'Registracija nije uspjela';
    try {
      final dynamic errorData = json.decode(response.body);
      if (errorData is Map && errorData.containsKey('error')) {
        errorMessage = errorData['error'].toString();
      } else if (errorData is Map && errorData.containsKey('message')) {
        errorMessage = errorData['message'].toString();
      } else if (errorData is Map && errorData.containsKey('title')) {
        errorMessage = errorData['title'].toString();
      } else if (errorData is String) {
        errorMessage = errorData;
      }
    } catch (_) {
      errorMessage = 'Registracija nije uspjela (${response.statusCode})';
    }
    throw Exception(errorMessage);
  }
}

