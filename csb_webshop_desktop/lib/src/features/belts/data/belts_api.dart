import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/belt.dart';

class BeltsApi {
  BeltsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _beltsPath = '/api/Belts';

  Future<List<Belt>> getBelts({int? beltTypeId, String? query}) async {
    final Map<String, String> params = <String, String>{
      if (beltTypeId != null) 'BeltTypeID': beltTypeId.toString(),
      if (query != null && query.isNotEmpty) 'BeltName': query,
    };
    final String queryString = Uri(queryParameters: params).query;
    final String pathWithQuery = params.isEmpty ? _beltsPath : '$_beltsPath?$queryString';
    final http.Response response = await _apiClient.get(pathWithQuery);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => Belt.fromJson(e as Map<String, dynamic>)).toList();
    }
    final String body = response.body.isNotEmpty ? response.body : 'no body';
    throw Exception('Failed to load belts: ${response.statusCode} — $body');
  }

  Future<Belt> getBeltById(int id) async {
    final http.Response response = await _apiClient.get('$_beltsPath/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Belt.fromJson(map);
    }
    throw Exception('Failed to load belt $id: ${response.statusCode}');
  }

  Future<Belt> createBelt({
    required String name,
    required String code,
    required double price,
    String description = '',
    int? beltTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BeltName': name,
      'Code': code,
      'Price': price,
      'Description': description,
      if (beltTypeId != null) 'BeltTypeID': beltTypeId,
      if (imageBase64 != null && imageBase64.isNotEmpty) 'Image': imageBase64,
      if (userId != null) 'UserID': userId,
    };
    final http.Response response = await _apiClient.post(_beltsPath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Belt.fromJson(map);
    }
    throw Exception('Failed to create belt: ${response.statusCode}');
  }

  Future<Belt> updateBelt({
    required int id,
    required String name,
    required String code,
    required double price,
    String description = '',
    int? beltTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BeltName': name,
      'Code': code,
      'Price': price,
      'Description': description,
      'BeltTypeID': beltTypeId ?? 0,
      'Image': imageBase64 ?? '',
      'UserID': userId ?? 0,
    };
    final http.Response response = await _apiClient.put('$_beltsPath/$id', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Belt.fromJson(map);
    }
    throw Exception('Failed to update belt $id: ${response.statusCode}');
  }

  Future<void> deleteBelt(int id) async {
    final http.Response response = await _apiClient.delete('$_beltsPath/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Failed to delete belt $id: ${response.statusCode}');
  }
}

