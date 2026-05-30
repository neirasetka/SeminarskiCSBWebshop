import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/recommended_product.dart';

/// API client for fetching product recommendations.
class RecommendationsApi {
  RecommendationsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _recommendationsPath = '/api/Recommendation';

  Future<List<RecommendedProduct>> getRecommendedBags({int take = 6}) async {
    final http.Response response =
        await _apiClient.get('$_recommendationsPath/GetRecommendedBags?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <RecommendedProduct>[];
    }
    throw Exception('Failed to load recommended bags: ${response.statusCode}');
  }

  Future<List<RecommendedProduct>> getRecommendedBelts({int take = 6}) async {
    final http.Response response =
        await _apiClient.get('$_recommendationsPath/GetRecommendedBelts?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <RecommendedProduct>[];
    }
    throw Exception('Failed to load recommended belts: ${response.statusCode}');
  }

  static List<RecommendedProduct> _parseList(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <RecommendedProduct>[];
      return decoded
          .map((dynamic e) =>
              e is Map<String, dynamic> ? RecommendedProduct.fromJson(e) : null)
          .whereType<RecommendedProduct>()
          .toList();
    } catch (_) {
      return <RecommendedProduct>[];
    }
  }
}
