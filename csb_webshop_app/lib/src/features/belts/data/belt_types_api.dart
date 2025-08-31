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
}

