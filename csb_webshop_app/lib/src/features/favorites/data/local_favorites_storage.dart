import 'package:shared_preferences/shared_preferences.dart';

class LocalFavoritesStorage {
  LocalFavoritesStorage({SharedPreferences? sharedPreferences})
      : _sharedPreferencesInstance = sharedPreferences;

  static const String _bagFavoritesKey = 'favorite_bag_ids';

  SharedPreferences? _sharedPreferencesInstance;

  Future<SharedPreferences> get _prefs async {
    return _sharedPreferencesInstance ??= await SharedPreferences.getInstance();
  }

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
}

