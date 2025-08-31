import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/bag.dart';

class BagsApi {
  BagsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _bagsPath = '/api/Bags';

  Future<List<Bag>> getBags({int? bagTypeId, String? query}) async {
    final Map<String, String> params = <String, String>{
      if (bagTypeId != null) 'BagTypeID': bagTypeId.toString(),
      if (query != null && query.isNotEmpty) 'BagName': query,
    };
    final String queryString = Uri(queryParameters: params).query;
    final String pathWithQuery = params.isEmpty ? _bagsPath : '$_bagsPath?$queryString';
    final http.Response response = await _apiClient.get(pathWithQuery);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => Bag.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load bags: ${response.statusCode}');
  }

  Future<Bag> getBagById(int id) async {
    final http.Response response = await _apiClient.get('$_bagsPath/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Bag.fromJson(map);
    }
    throw Exception('Failed to load bag $id: ${response.statusCode}');
  }
}

