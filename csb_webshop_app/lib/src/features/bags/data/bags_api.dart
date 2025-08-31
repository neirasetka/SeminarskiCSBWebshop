import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/bag.dart';

class BagsApi {
  BagsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _bagsPath = '/api/Bags';

  Future<List<Bag>> getBags({int page = 1, int pageSize = 20, String? query}) async {
    final Map<String, String> params = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      if (query != null && query.isNotEmpty) 'Name': query,
    };
    final String queryString = Uri(queryParameters: params).query;
    final String pathWithQuery = '$_bagsPath?$queryString';
    final http.Response response = await _apiClient.get(pathWithQuery);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => Bag.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load bags: ${response.statusCode}');
  }
}

