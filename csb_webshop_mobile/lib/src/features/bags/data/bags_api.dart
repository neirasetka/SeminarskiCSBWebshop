import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/paged_result.dart';
import '../domain/bag.dart';

class BagsApi {
  BagsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _bagsPath = '/api/Bags';

  Future<PagedResult<Bag>> getBags({
    int? bagTypeId,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, String> params = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      if (bagTypeId != null) 'BagTypeID': bagTypeId.toString(),
      if (query != null && query.isNotEmpty) 'BagName': query,
    };
    final String pathWithQuery = '$_bagsPath?${Uri(queryParameters: params).query}';
    final http.Response response = await _apiClient.get(pathWithQuery);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBagsResponse(response.body, page: page, pageSize: pageSize);
    }
    throw Exception('Failed to load bags: ${response.statusCode}');
  }

  Future<List<Bag>> getAllBags({int? bagTypeId, String? query}) async {
    const int pageSize = 100;
    final List<Bag> all = <Bag>[];
    var page = 1;
    while (true) {
      final PagedResult<Bag> result = await getBags(
        bagTypeId: bagTypeId,
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

  Future<Bag> getBagById(int id) async {
    final http.Response response = await _apiClient.get('$_bagsPath/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Bag.fromJson(map);
    }
    throw Exception('Failed to load bag $id: ${response.statusCode}');
  }

  Future<Bag> createBag({
    required String name,
    required String code,
    required double price,
    String description = '',
    int? bagTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BagName': name,
      'Code': code,
      'Price': price,
      'Description': description,
      'BagTypeID': bagTypeId ?? 0,
      'Image': imageBase64 ?? '',
      'UserID': userId ?? 0,
    };
    final http.Response response = await _apiClient.post(_bagsPath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Bag.fromJson(map);
    }
    throw Exception('Failed to create bag: ${response.statusCode}');
  }

  Future<Bag> updateBag({
    required int id,
    required String name,
    required String code,
    required double price,
    String description = '',
    int? bagTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BagName': name,
      'Code': code,
      'Price': price,
      'Description': description,
      'BagTypeID': bagTypeId ?? 0,
      'Image': imageBase64 ?? '',
      'UserID': userId ?? 0,
    };
    final http.Response response = await _apiClient.put('$_bagsPath/$id', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Bag.fromJson(map);
    }
    throw Exception('Failed to update bag $id: ${response.statusCode}');
  }

  PagedResult<Bag> _parseBagsResponse(String body, {required int page, required int pageSize}) {
    final dynamic decoded = json.decode(body);
    if (decoded is List<dynamic>) {
      final List<Bag> items = decoded
          .map((dynamic e) => Bag.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResult<Bag>(
        items: items,
        totalCount: items.length,
        page: page,
        pageSize: pageSize,
      );
    }
    if (decoded is Map<String, dynamic>) {
      return PagedResult.fromJson(decoded, Bag.fromJson);
    }
    return PagedResult<Bag>(items: <Bag>[], totalCount: 0, page: page, pageSize: pageSize);
  }

  Future<void> deleteBag(int id) async {
    final http.Response response = await _apiClient.delete('$_bagsPath/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Failed to delete bag $id: ${response.statusCode}');
  }
}
