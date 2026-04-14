import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/report_models.dart';

/// API client for admin report endpoints (requires Admin JWT).
class ReportsApi {
  ReportsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _reportsPath = '/api/Reports';

  /// Daily revenue; aggregate client-side for monthly charts.
  Future<List<RevenueByDayPoint>> getRevenueByDay({DateTime? fromDateUtc, DateTime? toDateUtc}) async {
    final List<String> query = <String>[];
    if (fromDateUtc != null) query.add('FromDateUtc=${Uri.encodeComponent(fromDateUtc.toUtc().toIso8601String())}');
    if (toDateUtc != null) query.add('ToDateUtc=${Uri.encodeComponent(toDateUtc.toUtc().toIso8601String())}');
    final String qs = query.isEmpty ? '' : '?${query.join('&')}';
    final http.Response response = await _apiClient.get('$_reportsPath/RevenueByDay$qs');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseRevenueByDayList(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return <RevenueByDayPoint>[];
    }
    throw Exception('Failed to load revenue by day: ${response.statusCode}');
  }

  /// Gets top-selling bags with quantities. Admin-only on backend.
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

  /// Gets order status counts. Admin-only on backend.
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

  static List<RevenueByDayPoint> _parseRevenueByDayList(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <RevenueByDayPoint>[];
      return decoded
          .map((dynamic e) {
            if (e is! Map<String, dynamic>) return null;
            try {
              return RevenueByDayPoint.fromJson(e);
            } catch (_) {
              return null;
            }
          })
          .whereType<RevenueByDayPoint>()
          .toList();
    } catch (_) {
      return <RevenueByDayPoint>[];
    }
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
}
