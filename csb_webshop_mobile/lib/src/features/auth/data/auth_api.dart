import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/api_error_reader.dart';
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
    if (response.statusCode == 401) {
      throw Exception('Pogrešno korisničko ime ili lozinka.');
    }
    throw Exception('Prijava trenutno nije moguća. Pokušajte ponovo.');
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
    };
    final http.Response response = await _apiClient.post(
      _registerPath,
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return jsonMap;
    }
    final String errorMessage = ApiErrorReader.readDetail(
      response.body,
      fallback: 'Registracija nije uspjela (${response.statusCode})',
      errorsSeparator: '\n',
    );
    throw Exception(errorMessage);
  }
}

