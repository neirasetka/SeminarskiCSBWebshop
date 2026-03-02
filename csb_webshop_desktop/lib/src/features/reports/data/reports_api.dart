import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../bags/domain/bag.dart';
import '../domain/report_models.dart';

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

  /// Gets top-selling bags with quantities (for reports pie chart).
  Future<List<TopSellingBagEntry>> getTopSellingBagsWithQuantities({int take = 6}) async {
    final http.Response response = await _apiClient.get('$_reportsPath/TopSellingBagsWithQuantities?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseTopSellingBagList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <TopSellingBagEntry>[];
    }
    throw Exception('Failed to load top selling bags: ${response.statusCode}');
  }

  /// Gets top-selling belts with quantities (for reports pie chart).
  Future<List<TopSellingBeltEntry>> getTopSellingBeltsWithQuantities({int take = 6}) async {
    final http.Response response = await _apiClient.get('$_reportsPath/TopSellingBeltsWithQuantities?take=$take');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseTopSellingBeltList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <TopSellingBeltEntry>[];
    }
    throw Exception('Failed to load top selling belts: ${response.statusCode}');
  }

  /// Gets order status counts (for reports pie chart).
  Future<List<OrderStatusCountEntry>> getOrderStatusCounts({DateTime? fromDateUtc, DateTime? toDateUtc}) async {
    final List<String> query = <String>[];
    if (fromDateUtc != null) query.add('FromDateUtc=${Uri.encodeComponent(fromDateUtc.toUtc().toIso8601String())}');
    if (toDateUtc != null) query.add('ToDateUtc=${Uri.encodeComponent(toDateUtc.toUtc().toIso8601String())}');
    final String qs = query.isEmpty ? '' : '?${query.join('&')}';
    final http.Response response = await _apiClient.get('$_reportsPath/OrderStatusCounts$qs');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseOrderStatusCountList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <OrderStatusCountEntry>[];
    }
    throw Exception('Failed to load order status counts: ${response.statusCode}');
  }

  static List<TopSellingBagEntry> _parseTopSellingBagList(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <TopSellingBagEntry>[];
      return decoded
          .map((dynamic e) => e is Map<String, dynamic> ? TopSellingBagEntry.fromJson(e) : null)
          .whereType<TopSellingBagEntry>()
          .toList();
    } catch (_) {
      return <TopSellingBagEntry>[];
    }
  }

  static List<TopSellingBeltEntry> _parseTopSellingBeltList(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <TopSellingBeltEntry>[];
      return decoded
          .map((dynamic e) => e is Map<String, dynamic> ? TopSellingBeltEntry.fromJson(e) : null)
          .whereType<TopSellingBeltEntry>()
          .toList();
    } catch (_) {
      return <TopSellingBeltEntry>[];
    }
  }

  static List<OrderStatusCountEntry> _parseOrderStatusCountList(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <OrderStatusCountEntry>[];
      return decoded
          .map((dynamic e) => e is Map<String, dynamic> ? OrderStatusCountEntry.fromJson(e) : null)
          .whereType<OrderStatusCountEntry>()
          .toList();
    } catch (_) {
      return <OrderStatusCountEntry>[];
    }
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
