import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../bags/domain/bag.dart';

/// API client for reports (admin-only endpoints).
class ReportsApi {
  ReportsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _reportsPath = '/api/Reports';

  /// Gets top-selling bags (admin only).
  /// Returns bags ordered by quantity sold.
  Future<List<Bag>> getTopSellingBags({int take = 6}) async {
    final http.Response response = await _apiClient.get('$_reportsPath/TopSellingBags?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBagList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <Bag>[];
    }
    throw Exception('Failed to load top selling bags: ${response.statusCode}');
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
}
