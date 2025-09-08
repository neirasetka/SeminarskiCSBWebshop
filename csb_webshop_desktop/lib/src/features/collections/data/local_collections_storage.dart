import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalCollectionsStorage {
  LocalCollectionsStorage({SharedPreferences? sharedPreferences})
      : _sharedPreferencesInstance = sharedPreferences;

  static const String _collectionsKey = 'bag_collections_v1';

  SharedPreferences? _sharedPreferencesInstance;

  Future<SharedPreferences> get _prefs async {
    return _sharedPreferencesInstance ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, Set<int>>> getCollections() async {
    final SharedPreferences prefs = await _prefs;
    final String jsonStr = prefs.getString(_collectionsKey) ?? '{}';
    final Map<String, dynamic> decoded = json.decode(jsonStr) as Map<String, dynamic>;
    final Map<String, Set<int>> result = <String, Set<int>>{};
    for (final MapEntry<String, dynamic> entry in decoded.entries) {
      final List<dynamic> list = (entry.value as List<dynamic>);
      result[entry.key] = list.map((dynamic e) => int.tryParse(e.toString())).whereType<int>().toSet();
    }
    return result;
  }

  Future<void> saveCollections(Map<String, Set<int>> collections) async {
    final SharedPreferences prefs = await _prefs;
    final Map<String, List<int>> serializable = <String, List<int>>{
      for (final MapEntry<String, Set<int>> e in collections.entries) e.key: e.value.toList(),
    };
    await prefs.setString(_collectionsKey, json.encode(serializable));
  }

  Future<Map<String, Set<int>>> addBagToCollection({required String collectionName, required int bagId}) async {
    final Map<String, Set<int>> data = await getCollections();
    final String key = collectionName.trim();
    final Set<int> set = data[key] ?? <int>{};
    set.add(bagId);
    data[key] = set;
    await saveCollections(data);
    return data;
  }

  Future<Map<String, Set<int>>> removeBagFromCollection({required String collectionName, required int bagId}) async {
    final Map<String, Set<int>> data = await getCollections();
    final String key = collectionName.trim();
    final Set<int> set = data[key] ?? <int>{};
    set.remove(bagId);
    if (set.isEmpty) {
      data.remove(key);
    } else {
      data[key] = set;
    }
    await saveCollections(data);
    return data;
  }

  Future<Map<String, Set<int>>> renameCollection({required String oldName, required String newName}) async {
    final Map<String, Set<int>> data = await getCollections();
    if (!data.containsKey(oldName)) return data;
    final Set<int> current = data.remove(oldName)!;
    data[newName.trim()] = current;
    await saveCollections(data);
    return data;
  }

  Future<Map<String, Set<int>>> removeCollection(String name) async {
    final Map<String, Set<int>> data = await getCollections();
    data.remove(name);
    await saveCollections(data);
    return data;
  }
}

