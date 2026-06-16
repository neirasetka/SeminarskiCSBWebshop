import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/api_error_reader.dart';
import '../../../core/paged_result.dart';
import '../domain/product_feedback.dart';

class RatesApi {
  RatesApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _basePath = '/api/Rates';

  Future<List<ProductRate>> getRatesForProduct({
    int? bagId,
    int? beltId,
    int pageSize = 100,
  }) async {
    final String productQuery = bagId != null
        ? 'BagID=$bagId'
        : beltId != null
            ? 'BeltID=$beltId'
            : '';
    if (productQuery.isEmpty) {
      throw ArgumentError('Either bagId or beltId must be set.');
    }

    return PagedResult.collectAllPages<ProductRate>(
      pageSize: pageSize,
      fetchPage: (int page, int psz) async {
        final http.Response response = await _apiClient.get(
          '$_basePath?$productQuery&page=$page&pageSize=$psz',
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final Map<String, dynamic> map =
              json.decode(response.body) as Map<String, dynamic>;
          return PagedResult.fromJson(
            map,
            (Map<String, dynamic> e) => ProductRate.fromJson(e),
          );
        }
        throw Exception('Failed to load rates: ${response.statusCode}');
      },
    );
  }

  Future<ProductRate> submitRate({
    required int rating,
    int? bagId,
    int? beltId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'Rating': rating,
      if (bagId != null) 'BagID': bagId,
      if (beltId != null) 'BeltID': beltId,
    };
    final http.Response response =
        await _apiClient.post(_basePath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map =
          json.decode(response.body) as Map<String, dynamic>;
      return ProductRate.fromJson(map);
    }
    throw Exception(
      ApiErrorReader.readDetail(response.body, fallback: 'Ocjenjivanje nije uspjelo.'),
    );
  }

  Future<ProductRate> updateRate({
    required int rateId,
    required int rating,
    int? bagId,
    int? beltId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'Rating': rating,
      if (bagId != null) 'BagID': bagId,
      if (beltId != null) 'BeltID': beltId,
    };
    final http.Response response = await _apiClient.put(
      '$_basePath/$rateId',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map =
          json.decode(response.body) as Map<String, dynamic>;
      return ProductRate.fromJson(map);
    }
    throw Exception(
      ApiErrorReader.readDetail(response.body, fallback: 'Ažuriranje ocjene nije uspjelo.'),
    );
  }
}
