import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/api_error_reader.dart';
import '../../../core/paged_result.dart';
import '../domain/product_feedback.dart';

class ReviewsApi {
  ReviewsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _basePath = '/api/Reviews';

  Future<List<ProductReview>> getReviewsForProduct({
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

    return PagedResult.collectAllPages<ProductReview>(
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
            (Map<String, dynamic> e) => ProductReview.fromJson(e),
          );
        }
        throw Exception('Failed to load reviews: ${response.statusCode}');
      },
    );
  }

  Future<ProductReview> submitReview({
    required String comment,
    int? bagId,
    int? beltId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'Comment': comment,
      'Date': DateTime.now().toUtc().toIso8601String(),
      if (bagId != null) 'BagID': bagId,
      if (beltId != null) 'BeltID': beltId,
    };
    final http.Response response =
        await _apiClient.post(_basePath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map =
          json.decode(response.body) as Map<String, dynamic>;
      return ProductReview.fromJson(map);
    }
    throw Exception(
      ApiErrorReader.readDetail(response.body, fallback: 'Slanje recenzije nije uspjelo.'),
    );
  }

  /// Admin: recenzije po statusu (Pending=0, Approved=1, Rejected=2).
  Future<List<ProductReview>> getReviewsByStatus({
    required String statusKey,
    int pageSize = 100,
  }) async {
    final int status = reviewStatusToQueryValue(statusKey);
    return PagedResult.collectAllPages<ProductReview>(
      pageSize: pageSize,
      fetchPage: (int page, int psz) async {
        final http.Response response = await _apiClient.get(
          '$_basePath?Status=$status&page=$page&pageSize=$psz',
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final Map<String, dynamic> map =
              json.decode(response.body) as Map<String, dynamic>;
          return PagedResult.fromJson(
            map,
            (Map<String, dynamic> e) => ProductReview.fromJson(e),
          );
        }
        throw Exception('Failed to load reviews: ${response.statusCode}');
      },
    );
  }

  Future<ProductReview> approveReview(int reviewId) async {
    final http.Response response = await _apiClient.post('$_basePath/$reviewId/approve');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map =
          json.decode(response.body) as Map<String, dynamic>;
      return ProductReview.fromJson(map);
    }
    throw Exception(
      ApiErrorReader.readDetail(response.body, fallback: 'Odobravanje recenzije nije uspjelo.'),
    );
  }

  Future<ProductReview> rejectReview(int reviewId) async {
    final http.Response response = await _apiClient.post('$_basePath/$reviewId/reject');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map =
          json.decode(response.body) as Map<String, dynamic>;
      return ProductReview.fromJson(map);
    }
    throw Exception(
      ApiErrorReader.readDetail(response.body, fallback: 'Odbijanje recenzije nije uspjelo.'),
    );
  }
}
