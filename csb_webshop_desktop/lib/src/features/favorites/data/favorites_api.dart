import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';

/// Favorite torbe/kaiševi preko JWT (`/api/Users/me/Liked*`).
class FavoritesApi {
  FavoritesApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _usersPath = '/api/Users';

  Future<Set<int>> getFavoriteBagIds() async {
    final http.Response response = await _apiClient.get('$_usersPath/me/LikedBags');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBagIds(response.body);
    }
    throw Exception('Failed to load bag favorites: ${response.statusCode}');
  }

  Future<Set<int>> getFavoriteBeltIds() async {
    final http.Response response = await _apiClient.get('$_usersPath/me/LikedBelts');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBeltIds(response.body);
    }
    throw Exception('Failed to load belt favorites: ${response.statusCode}');
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

  static Set<int> _parseBagIds(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <int>{};
      return decoded
          .map((dynamic e) => e is Map<String, dynamic> ? Bag.fromJson(e).id : null)
          .whereType<int>()
          .where((int id) => id > 0)
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }

  static Set<int> _parseBeltIds(String body) {
    try {
      final Object? decoded = json.decode(body);
      if (decoded is! List<dynamic>) return <int>{};
      return decoded
          .map((dynamic e) => e is Map<String, dynamic> ? Belt.fromJson(e).id : null)
          .whereType<int>()
          .where((int id) => id > 0)
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }
}
