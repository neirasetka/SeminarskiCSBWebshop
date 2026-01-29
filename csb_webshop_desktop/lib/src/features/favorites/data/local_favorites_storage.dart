import 'package:shared_preferences/shared_preferences.dart';

class LocalFavoritesStorage {
  LocalFavoritesStorage({SharedPreferences? sharedPreferences})
      : _sharedPreferencesInstance = sharedPreferences;

  static const String _bagFavoritesKey = 'favorite_bag_ids';
  static const String _beltFavoritesKey = 'favorite_belt_ids';

  SharedPreferences? _sharedPreferencesInstance;

  Future<SharedPreferences> get _prefs async {
    return _sharedPreferencesInstance ??= await SharedPreferences.getInstance();
  }

  // Bag favorites
  Future<Set<int>> getFavoriteBagIds() async {
    final SharedPreferences prefs = await _prefs;
    final List<String> ids = prefs.getStringList(_bagFavoritesKey) ?? <String>[];
    return ids.map((String s) => int.tryParse(s)).whereType<int>().toSet();
  }

  Future<void> saveFavoriteBagIds(Set<int> bagIds) async {
    final SharedPreferences prefs = await _prefs;
    final List<String> asStrings = bagIds.map((int id) => id.toString()).toList();
    await prefs.setStringList(_bagFavoritesKey, asStrings);
  }

  Future<bool> isFavorite(int bagId) async {
    final Set<int> ids = await getFavoriteBagIds();
    return ids.contains(bagId);
  }

  Future<Set<int>> toggleFavorite(int bagId) async {
    final Set<int> ids = await getFavoriteBagIds();
    if (ids.contains(bagId)) {
      ids.remove(bagId);
    } else {
      ids.add(bagId);
    }
    await saveFavoriteBagIds(ids);
    return ids;
  }

  // Belt favorites
  Future<Set<int>> getFavoriteBeltIds() async {
    final SharedPreferences prefs = await _prefs;
    final List<String> ids = prefs.getStringList(_beltFavoritesKey) ?? <String>[];
    return ids.map((String s) => int.tryParse(s)).whereType<int>().toSet();
  }

  Future<void> saveFavoriteBeltIds(Set<int> beltIds) async {
    final SharedPreferences prefs = await _prefs;
    final List<String> asStrings = beltIds.map((int id) => id.toString()).toList();
    await prefs.setStringList(_beltFavoritesKey, asStrings);
  }

  Future<bool> isBeltFavorite(int beltId) async {
    final Set<int> ids = await getFavoriteBeltIds();
    return ids.contains(beltId);
  }

  Future<Set<int>> toggleBeltFavorite(int beltId) async {
    final Set<int> ids = await getFavoriteBeltIds();
    if (ids.contains(beltId)) {
      ids.remove(beltId);
    } else {
      ids.add(beltId);
    }
    await saveFavoriteBeltIds(ids);
    return ids;
  }
}

