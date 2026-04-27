import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';

/// Pozivi backend preporuka (`/api/Recommendation/*`), JWT iz [ApiClient].
class RecommendationsApi {
  RecommendationsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _path = '/api/Recommendation';

  Future<List<Bag>> getRecommendedBags({int take = 8}) async {
    final http.Response response =
        await _apiClient.get('$_path/GetRecommendedBags?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBagList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <Bag>[];
    }
    throw Exception('Preporuke torbi: ${response.statusCode}');
  }

  Future<List<Belt>> getRecommendedBelts({int take = 8}) async {
    final http.Response response =
        await _apiClient.get('$_path/GetRecommendedBelts?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBeltList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <Belt>[];
    }
    throw Exception('Preporuke kaiševa: ${response.statusCode}');
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
