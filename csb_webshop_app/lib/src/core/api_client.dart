import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../environment.dart';
import 'secure_storage_service.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, SecureStorageService? secureStorageService})
      : _httpClient = httpClient ?? http.Client(),
        _secureStorageService = secureStorageService ?? SecureStorageService();

  final http.Client _httpClient;
  final SecureStorageService _secureStorageService;

  String get _baseUrl => EnvironmentConfig.apiBaseUrl;

  Future<Map<String, String>> _defaultHeaders() async {
    final String? token = await _secureStorageService.getToken();
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path) {
    if (path.startsWith('http')) {
      return Uri.parse(path);
    }
    return Uri.parse('$_baseUrl$path');
  }

  Future<http.Response> get(String path) async {
    final Uri url = _uri(path);
    final Map<String, String> headers = await _defaultHeaders();
    if (EnvironmentConfig.enableLogging) {
      debugPrint('GET $url');
    }
    final http.Response response = await _httpClient.get(url, headers: headers);
    _logResponse(response);
    return response;
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final Uri url = _uri(path);
    final Map<String, String> headers = await _defaultHeaders();
    if (EnvironmentConfig.enableLogging) {
      debugPrint('PUT $url');
      debugPrint('Body: ${_formatBodyForLog(body)}');
    }
    final http.Response response = await _httpClient.put(url, headers: headers, body: body);
    _logResponse(response);
    return response;
  }

  Future<http.Response> putWithUserId(String pathTemplate, {required int userId, Object? body}) async {
    final String path = pathTemplate.replaceAll('{ID}', userId.toString());
    return put(path, body: body);
  }

  String _formatBodyForLog(Object? body) {
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  void _logResponse(http.Response response) {
    if (!EnvironmentConfig.enableLogging) return;
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Response: ${response.body}');
  }
}

