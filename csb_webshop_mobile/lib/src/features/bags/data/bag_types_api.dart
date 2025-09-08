import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/bag_type.dart';

class BagTypesApi {
  BagTypesApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _path = '/api/BagTypes';

  Future<List<BagType>> getBagTypes() async {
    final http.Response response = await _apiClient.get(_path);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => BagType.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load bag types: ${response.statusCode}');
  }

  Future<BagType> createBagType({required String name}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BagName': name,
    };
    final http.Response response = await _apiClient.post(_path, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return BagType.fromJson(map);
    }
    throw Exception('Failed to create bag type: ${response.statusCode}');
  }

  Future<BagType> updateBagType({required int id, required String name}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BagName': name,
    };
    final http.Response response = await _apiClient.put('$_path/$id', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return BagType.fromJson(map);
    }
    throw Exception('Failed to update bag type: ${response.statusCode}');
  }

  Future<void> deleteBagType(int id) async {
    final http.Response response = await _apiClient.delete('$_path/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Failed to delete bag type: ${response.statusCode}');
  }
}

