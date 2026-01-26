import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/outfit_idea.dart';

/// Local storage for outfit ideas using SharedPreferences.
class LocalOutfitIdeasStorage {
  LocalOutfitIdeasStorage({SharedPreferences? sharedPreferences})
      : _sharedPreferencesInstance = sharedPreferences;

  static const String _storageKey = 'outfit_ideas_v1';

  SharedPreferences? _sharedPreferencesInstance;

  Future<SharedPreferences> get _prefs async {
    return _sharedPreferencesInstance ??= await SharedPreferences.getInstance();
  }

  /// Gets all outfit ideas as a map keyed by bag ID.
  Future<Map<int, OutfitIdea>> getAll() async {
    final SharedPreferences prefs = await _prefs;
    final String jsonStr = prefs.getString(_storageKey) ?? '{}';
    final Map<String, dynamic> decoded =
        json.decode(jsonStr) as Map<String, dynamic>;
    final Map<int, OutfitIdea> result = <int, OutfitIdea>{};
    for (final MapEntry<String, dynamic> entry in decoded.entries) {
      final int? bagId = int.tryParse(entry.key);
      if (bagId != null && entry.value is Map<String, dynamic>) {
        result[bagId] =
            OutfitIdea.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    return result;
  }

  /// Gets the outfit idea for a specific bag.
  Future<OutfitIdea?> getForBag(int bagId) async {
    final Map<int, OutfitIdea> all = await getAll();
    return all[bagId];
  }

  /// Saves all outfit ideas.
  Future<void> saveAll(Map<int, OutfitIdea> ideas) async {
    final SharedPreferences prefs = await _prefs;
    final Map<String, dynamic> serializable = <String, dynamic>{
      for (final MapEntry<int, OutfitIdea> e in ideas.entries)
        e.key.toString(): e.value.toJson(),
    };
    await prefs.setString(_storageKey, json.encode(serializable));
  }

  /// Saves an outfit idea for a specific bag.
  Future<Map<int, OutfitIdea>> saveForBag(OutfitIdea idea) async {
    final Map<int, OutfitIdea> data = await getAll();
    data[idea.bagId] = idea;
    await saveAll(data);
    return data;
  }

  /// Adds images to an existing outfit idea for a bag.
  Future<Map<int, OutfitIdea>> addImages({
    required int bagId,
    required List<String> imagePaths,
  }) async {
    final Map<int, OutfitIdea> data = await getAll();
    final OutfitIdea existing =
        data[bagId] ?? OutfitIdea(bagId: bagId, imagePaths: <String>[]);
    final List<String> newPaths = <String>[
      ...existing.imagePaths,
      ...imagePaths,
    ];
    data[bagId] = existing.copyWith(imagePaths: newPaths);
    await saveAll(data);
    return data;
  }

  /// Removes an image from an outfit idea.
  Future<Map<int, OutfitIdea>> removeImage({
    required int bagId,
    required String imagePath,
  }) async {
    final Map<int, OutfitIdea> data = await getAll();
    final OutfitIdea? existing = data[bagId];
    if (existing == null) return data;

    final List<String> newPaths = existing.imagePaths
        .where((String p) => p != imagePath)
        .toList();
    
    if (newPaths.isEmpty) {
      data.remove(bagId);
    } else {
      data[bagId] = existing.copyWith(imagePaths: newPaths);
    }
    await saveAll(data);
    return data;
  }

  /// Removes all images for a specific bag.
  Future<Map<int, OutfitIdea>> removeForBag(int bagId) async {
    final Map<int, OutfitIdea> data = await getAll();
    data.remove(bagId);
    await saveAll(data);
    return data;
  }
}
