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
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => Bag.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (response.statusCode == 401) {
      // User not authenticated - return empty list
      return <Bag>[];
    }
    throw Exception('Failed to load recommended bags: ${response.statusCode}');
  }

  /// Gets recommended belts for the currently logged-in user.
  /// The recommendations are based on Content-Based Filtering (CBF) using
  /// the user's favorite belts and their types.
  Future<List<Belt>> getRecommendedBelts({int take = 6}) async {
    final http.Response response = await _apiClient.get('$_recommendationsPath/GetRecommendedBelts?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => Belt.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (response.statusCode == 401) {
      // User not authenticated - return empty list
      return <Belt>[];
    }
    throw Exception('Failed to load recommended belts: ${response.statusCode}');
  }
}
