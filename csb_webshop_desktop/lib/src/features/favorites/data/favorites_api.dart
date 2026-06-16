import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/paged_result.dart';
import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';

/// Favorite torbe/kaiševi preko JWT (`/api/Users/me/Liked*`).
class FavoritesApi {
  FavoritesApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _usersPath = '/api/Users';

  Future<Set<int>> getFavoriteBagIds() async {
    final List<Bag> bags = await PagedResult.collectAllPages<Bag>(
      fetchPage: _fetchLikedBagsPage,
      pageSize: 100,
    );
    return bags.map((Bag b) => b.id).where((int id) => id > 0).toSet();
  }

  Future<Set<int>> getFavoriteBeltIds() async {
    final List<Belt> belts = await PagedResult.collectAllPages<Belt>(
      fetchPage: _fetchLikedBeltsPage,
      pageSize: 100,
    );
    return belts.map((Belt b) => b.id).where((int id) => id > 0).toSet();
  }

  Future<Set<int>> toggleBagFavorite(int bagId) async {
    final Set<int> current = await getFavoriteBagIds();
    if (current.contains(bagId)) {
      await _apiClient.delete('$_usersPath/me/LikedBags/$bagId');
    } else {
      await _apiClient.post('$_usersPath/me/LikedBags/$bagId');
    }
    return getFavoriteBagIds();
  }

  Future<Set<int>> toggleBeltFavorite(int beltId) async {
    final Set<int> current = await getFavoriteBeltIds();
    if (current.contains(beltId)) {
      await _apiClient.delete('$_usersPath/me/LikedBelts/$beltId');
    } else {
      await _apiClient.post('$_usersPath/me/LikedBelts/$beltId');
    }
    return getFavoriteBeltIds();
  }

  Future<PagedResult<Bag>> _fetchLikedBagsPage(int page, int pageSize) async {
    final http.Response response = await _apiClient.get(
      '$_usersPath/me/LikedBags?Page=$page&PageSize=$pageSize',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Object? decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return PagedResult.fromJson(decoded, Bag.fromJson);
      }
      if (decoded is List<dynamic>) {
        final List<Bag> bags = decoded
            .whereType<Map<String, dynamic>>()
            .map(Bag.fromJson)
            .toList();
        return PagedResult<Bag>(
          items: bags,
          totalCount: bags.length,
          page: page,
          pageSize: pageSize,
        );
      }
    }
    throw Exception('Failed to load bag favorites: ${response.statusCode}');
  }

  Future<PagedResult<Belt>> _fetchLikedBeltsPage(int page, int pageSize) async {
    final http.Response response = await _apiClient.get(
      '$_usersPath/me/LikedBelts?Page=$page&PageSize=$pageSize',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Object? decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return PagedResult.fromJson(decoded, Belt.fromJson);
      }
      if (decoded is List<dynamic>) {
        final List<Belt> belts = decoded
            .whereType<Map<String, dynamic>>()
            .map(Belt.fromJson)
            .toList();
        return PagedResult<Belt>(
          items: belts,
          totalCount: belts.length,
          page: page,
          pageSize: pageSize,
        );
      }
    }
    throw Exception('Failed to load belt favorites: ${response.statusCode}');
  }
}
