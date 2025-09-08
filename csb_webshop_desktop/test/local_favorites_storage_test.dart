import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:csb_webshop_desktop/src/features/favorites/data/local_favorites_storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object?>{});
  });

  test('getFavoriteBagIds returns empty set initially', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();
    final Set<int> ids = await storage.getFavoriteBagIds();
    expect(ids, isEmpty);
  });

  test('toggleFavorite adds then removes an id', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();

    final Set<int> afterAdd = await storage.toggleFavorite(42);
    expect(afterAdd.contains(42), isTrue);

    final Set<int> afterRemove = await storage.toggleFavorite(42);
    expect(afterRemove.contains(42), isFalse);

    final Set<int> persisted = await storage.getFavoriteBagIds();
    expect(persisted.contains(42), isFalse);
  });

  test('isFavorite reflects saved state', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();

    expect(await storage.isFavorite(7), isFalse);
    await storage.toggleFavorite(7);
    expect(await storage.isFavorite(7), isTrue);
  });
}

