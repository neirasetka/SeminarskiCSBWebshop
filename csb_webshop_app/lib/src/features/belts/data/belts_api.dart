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
    throw Exception('Failed to load belts: ${response.statusCode}');
  }
}

