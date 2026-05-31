import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class PasswordResetApi {
  PasswordResetApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _basePath = '/api/PasswordReset';

  Future<void> requestReset(String email) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'email': email,
    };
    final http.Response response =
        await _apiClient.post('$_basePath/request', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(_parseErrorMessage(response, 'Slanje reset linka nije uspjelo'));
  }

  String _parseErrorMessage(http.Response response, String fallback) {
    String errorMessage = '$fallback: ${response.statusCode}';
    try {
      final Map<String, dynamic>? data =
          json.decode(response.body) as Map<String, dynamic>?;
      if (data != null) {
        final Object? err = data['error'] ?? data['message'] ?? data['title'] ?? data['detail'];
        if (err != null) errorMessage = err.toString();
      }
    } catch (_) {}
    return errorMessage;
  }

  Future<void> resetPassword(String token, String newPassword, String confirmPassword) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'token': token,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
    final http.Response response =
        await _apiClient.post('$_basePath/reset', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(_parseErrorMessage(response, 'Promjena lozinke nije uspjela'));
  }
}
