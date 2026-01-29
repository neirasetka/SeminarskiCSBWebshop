import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

/// Model representing a favorite item from the backend.
class FavoriteItem {
  const FavoriteItem({
    required this.favoriteId,
    required this.userId,
    this.bagId,
    this.beltId,
  });

  final int favoriteId;
  final int userId;
  final int? bagId;
  final int? beltId;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      favoriteId: _toInt(json['FavoriteID'] ?? json['favoriteID'] ?? json['favoriteId'] ?? 0),
      userId: _toInt(json['UserID'] ?? json['userID'] ?? json['userId'] ?? 0),
      bagId: _toNullableInt(json['BagID'] ?? json['bagID'] ?? json['bagId']),
      beltId: _toNullableInt(json['BeltID'] ?? json['beltID'] ?? json['beltId']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

/// API client for managing favorites on the backend.
class FavoritesApi {
  FavoritesApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _favoritesPath = '/api/Favorites';

  /// Gets all favorites for a specific user.
  Future<List<FavoriteItem>> getFavoritesByUser(int userId) async {
    final http.Response response = await _apiClient.get('$_favoritesPath?UserID=$userId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => FavoriteItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load favorites: ${response.statusCode}');
  }

  /// Gets favorite bag IDs for a user.
  Future<Set<int>> getFavoriteBagIds(int userId) async {
    final List<FavoriteItem> favorites = await getFavoritesByUser(userId);
    return favorites.where((FavoriteItem f) => f.bagId != null).map((FavoriteItem f) => f.bagId!).toSet();
  }

  /// Gets favorite belt IDs for a user.
  Future<Set<int>> getFavoriteBeltIds(int userId) async {
    final List<FavoriteItem> favorites = await getFavoritesByUser(userId);
    return favorites.where((FavoriteItem f) => f.beltId != null).map((FavoriteItem f) => f.beltId!).toSet();
  }

  /// Adds a bag to favorites.
  Future<FavoriteItem> addBagFavorite(int userId, int bagId) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'UserID': userId,
      'BagID': bagId,
    };
    final http.Response response = await _apiClient.post(_favoritesPath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return FavoriteItem.fromJson(map);
    }
    throw Exception('Failed to add bag favorite: ${response.statusCode}');
  }

  /// Adds a belt to favorites.
  Future<FavoriteItem> addBeltFavorite(int userId, int beltId) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'UserID': userId,
      'BeltID': beltId,
    };
    final http.Response response = await _apiClient.post(_favoritesPath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return FavoriteItem.fromJson(map);
    }
    throw Exception('Failed to add belt favorite: ${response.statusCode}');
  }

  /// Removes a favorite by its ID.
  Future<void> removeFavorite(int favoriteId) async {
    final http.Response response = await _apiClient.delete('$_favoritesPath/$favoriteId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Failed to remove favorite: ${response.statusCode}');
  }

  /// Finds a favorite by user and bag ID.
  Future<FavoriteItem?> findBagFavorite(int userId, int bagId) async {
    final http.Response response = await _apiClient.get('$_favoritesPath?UserID=$userId&BagID=$bagId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      return FavoriteItem.fromJson(list.first as Map<String, dynamic>);
    }
    return null;
  }

  /// Finds a favorite by user and belt ID.
  Future<FavoriteItem?> findBeltFavorite(int userId, int beltId) async {
    final http.Response response = await _apiClient.get('$_favoritesPath?UserID=$userId&BeltID=$beltId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      return FavoriteItem.fromJson(list.first as Map<String, dynamic>);
    }
    return null;
  }

  /// Toggles a bag favorite. Returns the updated set of favorite bag IDs.
  Future<Set<int>> toggleBagFavorite(int userId, int bagId) async {
    final FavoriteItem? existing = await findBagFavorite(userId, bagId);
    if (existing != null) {
      await removeFavorite(existing.favoriteId);
    } else {
      await addBagFavorite(userId, bagId);
    }
    return getFavoriteBagIds(userId);
  }

  /// Toggles a belt favorite. Returns the updated set of favorite belt IDs.
  Future<Set<int>> toggleBeltFavorite(int userId, int beltId) async {
    final FavoriteItem? existing = await findBeltFavorite(userId, beltId);
    if (existing != null) {
      await removeFavorite(existing.favoriteId);
    } else {
      await addBeltFavorite(userId, beltId);
    }
    return getFavoriteBeltIds(userId);
  }
}
