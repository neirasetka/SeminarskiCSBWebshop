import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/belt_type.dart';

class BeltTypesApi {
  BeltTypesApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _path = '/api/BeltTypes';

  Future<List<BeltType>> getBeltTypes() async {
    final http.Response response = await _apiClient.get(_path);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => BeltType.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load belt types: ${response.statusCode}');
  }

  Future<BeltType> createBeltType({required String name}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BeltName': name,
    };
    final http.Response response = await _apiClient.post(_path, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return BeltType.fromJson(map);
    }
    throw Exception('Failed to create belt type: ${response.statusCode}');
  }

  Future<BeltType> updateBeltType({required int id, required String name}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BeltName': name,
    };
    final http.Response response = await _apiClient.put('$_path/$id', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return BeltType.fromJson(map);
    }
    throw Exception('Failed to update belt type: ${response.statusCode}');
  }

  Future<void> deleteBeltType(int id) async {
    final http.Response response = await _apiClient.delete('$_path/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Failed to delete belt type: ${response.statusCode}');
  }
}

