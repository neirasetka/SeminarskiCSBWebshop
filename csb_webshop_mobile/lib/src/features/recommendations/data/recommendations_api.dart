import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/recommended_product.dart';

/// Pozivi backend preporuka (`/api/Recommendation/*`), JWT iz [ApiClient].
class RecommendationsApi {
  RecommendationsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _path = '/api/Recommendation';

  Future<List<RecommendedProduct>> getRecommendedBags({int take = 8}) async {
    final http.Response response =
        await _apiClient.get('$_path/GetRecommendedBags?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <RecommendedProduct>[];
    }
    throw Exception('Preporuke torbi: ${response.statusCode}');
  }

  Future<List<RecommendedProduct>> getRecommendedBelts({int take = 8}) async {
    final http.Response response =
        await _apiClient.get('$_path/GetRecommendedBelts?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <RecommendedProduct>[];
    }
    throw Exception('Preporuke kaiševa: ${response.statusCode}');
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
