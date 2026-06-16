import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/api_exception.dart';
import '../../../core/paged_result.dart';
import '../domain/belt.dart';

class BeltsApi {
  BeltsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _beltsPath = '/api/Belts';

  Future<PagedResult<Belt>> getBelts({
    int? beltTypeId,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, String> params = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      if (beltTypeId != null) 'BeltTypeID': beltTypeId.toString(),
      if (query != null && query.isNotEmpty) 'BeltName': query,
    };
    final String pathWithQuery = '$_beltsPath?${Uri(queryParameters: params).query}';
    final http.Response response = await _apiClient.get(pathWithQuery);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return PagedResult.fromJson(map, Belt.fromJson);
    }
    throw Exception('Failed to load belts: ${response.statusCode}');
  }

  Future<List<Belt>> getAllBelts({int? beltTypeId, String? query}) async {
    const int pageSize = 100;
    final List<Belt> all = <Belt>[];
    var page = 1;
    while (true) {
      final PagedResult<Belt> result = await getBelts(
        beltTypeId: beltTypeId,
        query: query,
        page: page,
        pageSize: pageSize,
      );
      all.addAll(result.items);
      if (!result.hasMore) break;
      page++;
    }
    return all;
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
      'BeltTypeID': beltTypeId ?? 0,
      'Image': imageBase64 ?? '',
      'UserID': userId ?? 0,
    };
    final http.Response response = await _apiClient.post(_beltsPath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Belt.fromJson(map);
    }
    throw ApiException.fromBody(
      statusCode: response.statusCode,
      body: response.body,
      fallback: 'Kreiranje kaiša nije uspjelo',
    );
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
    throw ApiException.fromBody(
      statusCode: response.statusCode,
      body: response.body,
      fallback: 'Ažuriranje kaiša nije uspjelo',
    );
  }

  Future<void> deleteBelt(int id) async {
    final http.Response response = await _apiClient.delete('$_beltsPath/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw ApiException.fromBody(
      statusCode: response.statusCode,
      body: response.body,
      fallback: 'Brisanje kaiša nije uspjelo',
    );
  }
}
