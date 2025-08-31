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
}

