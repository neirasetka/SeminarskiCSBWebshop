import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';

class RecommendationsApi {
  RecommendationsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _recommendationPath = '/api/Recommendation';

  /// Fetches recommended bags for the authenticated user.
  /// Uses Content-Based Filtering based on user's favorites.
  Future<List<Bag>> getRecommendedBags({int take = 6}) async {
    final String path = '$_recommendationPath/GetRecommendedBags?take=$take';
    final http.Response response = await _apiClient.get(path);
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

  /// Fetches recommended belts for the authenticated user.
  /// Uses Content-Based Filtering based on user's favorites.
  Future<List<Belt>> getRecommendedBelts({int take = 6}) async {
    final String path = '$_recommendationPath/GetRecommendedBelts?take=$take';
    final http.Response response = await _apiClient.get(path);
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
