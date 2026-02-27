import 'dart:convert';
import 'dart:io';

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
    final Uri base = Uri.parse(_baseUrl);
    return base.resolve(path);
  }

  Future<http.Response> get(String path) async {
    return _send('GET', path);
  }

  Future<http.Response> put(String path, {Object? body}) async {
    return _send('PUT', path, body: body);
  }

  Future<http.Response> post(String path, {Object? body}) async {
    return _send('POST', path, body: body);
  }

  Future<http.Response> patch(String path, {Object? body}) async {
    return _send('PATCH', path, body: body);
  }

  Future<http.Response> delete(String path) async {
    return _send('DELETE', path);
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

  Future<http.Response> _send(String method, String path, {Object? body}) async {
    final Uri primaryUrl = _uri(path);
    final Map<String, String> headers = await _defaultHeaders();

    if (EnvironmentConfig.enableLogging) {
      debugPrint('$method $primaryUrl');
      if (body != null && (method == 'POST' || method == 'PUT' || method == 'PATCH')) {
        debugPrint('Body: ${_formatBodyForLog(body)}');
      }
    }

    try {
      final http.Response response = await _sendRequest(method, primaryUrl, headers, body: body);
      _logResponse(response);
      return response;
    } catch (error) {
      final Uri? fallbackUrl = _localhostFallbackUri(primaryUrl);
      if (fallbackUrl == null || !_isConnectionRefused(error)) {
        rethrow;
      }

      if (EnvironmentConfig.enableLogging) {
        debugPrint('Request failed on $primaryUrl ($error). Retrying on $fallbackUrl.');
      }

      final http.Response response = await _sendRequest(method, fallbackUrl, headers, body: body);
      _logResponse(response);
      return response;
    }
  }

  Future<http.Response> _sendRequest(
    String method,
    Uri url,
    Map<String, String> headers, {
    Object? body,
  }) {
    switch (method) {
      case 'GET':
        return _httpClient.get(url, headers: headers);
      case 'POST':
        return _httpClient.post(url, headers: headers, body: body);
      case 'PUT':
        return _httpClient.put(url, headers: headers, body: body);
      case 'PATCH':
        return _httpClient.patch(url, headers: headers, body: body);
      case 'DELETE':
        return _httpClient.delete(url, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  Uri? _localhostFallbackUri(Uri url) {
    if (url.host.toLowerCase() != 'localhost') {
      return null;
    }
    return url.replace(host: '127.0.0.1');
  }

  bool _isConnectionRefused(Object error) {
    if (error is SocketException) {
      return true;
    }
    if (error is http.ClientException) {
      final String message = error.message.toLowerCase();
      return message.contains('socketexception') ||
          message.contains('connection refused') ||
          message.contains('errno = 111') ||
          message.contains('errno = 1225');
    }
    return false;
  }

  void _logResponse(http.Response response) {
    if (!EnvironmentConfig.enableLogging) return;
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Response: ${response.body}');
  }
}

