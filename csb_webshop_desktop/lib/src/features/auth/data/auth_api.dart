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
      if (errorData is Map) {
        if (errorData.containsKey('error')) {
          errorMessage = errorData['error'].toString();
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        } else if (errorData.containsKey('errors') && errorData['errors'] is Map) {
          // ASP.NET Core validation: { "errors": { "Email": ["Invalid email"], "Password": [...] } }
          final Map<String, dynamic> errors =
              errorData['errors'] as Map<String, dynamic>;
          final List<String> messages = <String>[];
          for (final MapEntry<String, dynamic> e in errors.entries) {
            if (e.value is List) {
              for (final dynamic msg in e.value as List<dynamic>) {
                if (msg != null) messages.add(msg.toString());
              }
            } else if (e.value != null) {
              messages.add(e.value.toString());
            }
          }
          if (messages.isNotEmpty) {
            errorMessage = messages.join('\n');
          } else {
            errorMessage =
                errorData['title']?.toString() ?? errorMessage;
          }
        } else if (errorData.containsKey('title')) {
          errorMessage = errorData['title'].toString();
        }
      } else if (errorData is String) {
        errorMessage = errorData;
      }
    } catch (_) {
      errorMessage = 'Registracija nije uspjela (${response.statusCode})';
    }
    throw Exception(errorMessage);
  }
}

