import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:csb_webshop_mobile/src/features/favorites/data/local_favorites_storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('getFavoriteBagIds returns empty set initially', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();
    final Set<int> ids = await storage.getFavoriteBagIds();
    expect(ids, isEmpty);
  });

  test('toggleBagFavorite adds then removes an id', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();

    final Set<int> afterAdd = await storage.toggleBagFavorite(42);
    expect(afterAdd.contains(42), isTrue);

    final Set<int> afterRemove = await storage.toggleBagFavorite(42);
    expect(afterRemove.contains(42), isFalse);

    final Set<int> persisted = await storage.getFavoriteBagIds();
    expect(persisted.contains(42), isFalse);
  });

  test('isBagFavorite reflects saved state', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();

    expect(await storage.isBagFavorite(7), isFalse);
    await storage.toggleBagFavorite(7);
    expect(await storage.isBagFavorite(7), isTrue);
  });

  test('getFavoriteBeltIds returns empty set initially', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();
    expect(await storage.getFavoriteBeltIds(), isEmpty);
  });

  test('toggleBeltFavorite is independent from bags', () async {
    final LocalFavoritesStorage storage = LocalFavoritesStorage();

    await storage.toggleBagFavorite(1);
    await storage.toggleBeltFavorite(99);

    expect(await storage.getFavoriteBagIds(), contains(1));
    expect(await storage.getFavoriteBeltIds(), contains(99));
    expect(await storage.getFavoriteBagIds(), isNot(contains(99)));

    await storage.toggleBeltFavorite(99);
    expect(await storage.getFavoriteBeltIds(), isEmpty);
    expect(await storage.getFavoriteBagIds(), contains(1));
  });
}
