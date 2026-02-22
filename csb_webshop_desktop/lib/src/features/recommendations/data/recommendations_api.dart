import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';

/// API client for fetching product recommendations.
class RecommendationsApi {
  RecommendationsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _recommendationsPath = '/api/Recommendation';

  /// Gets recommended bags for the currently logged-in user.
  /// The recommendations are based on Content-Based Filtering (CBF) using
  /// the user's favorite bags and their types.
  Future<List<Bag>> getRecommendedBags({int take = 6}) async {
    final http.Response response = await _apiClient.get('$_recommendationsPath/GetRecommendedBags?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBagList(response.body);
    }
    // 401/403: not authenticated or not allowed (e.g. some admin policies) - return empty
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <Bag>[];
    }
    throw Exception('Failed to load recommended bags: ${response.statusCode}');
  }

  static List<Bag> _parseBagList(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <Bag>[];
      return decoded
          .map((dynamic e) => e is Map<String, dynamic> ? Bag.fromJson(e) : null)
          .whereType<Bag>()
          .toList();
    } catch (_) {
      return <Bag>[];
    }
  }

  /// Gets recommended belts for the currently logged-in user.
  /// The recommendations are based on Content-Based Filtering (CBF) using
  /// the user's favorite belts and their types.
  Future<List<Belt>> getRecommendedBelts({int take = 6}) async {
    final http.Response response = await _apiClient.get('$_recommendationsPath/GetRecommendedBelts?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBeltList(response.body);
    }
    // 401/403: not authenticated or not allowed - return empty
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <Belt>[];
    }
    throw Exception('Failed to load recommended belts: ${response.statusCode}');
  }

  static List<Belt> _parseBeltList(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <Belt>[];
      return decoded
          .map((dynamic e) => e is Map<String, dynamic> ? Belt.fromJson(e) : null)
          .whereType<Belt>()
          .toList();
    } catch (_) {
      return <Belt>[];
    }
  }
}
