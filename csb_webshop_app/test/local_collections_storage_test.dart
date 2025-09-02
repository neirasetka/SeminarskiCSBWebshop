import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:csb_webshop_app/src/features/collections/data/local_collections_storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object?>{});
  });

  test('getCollections returns empty map initially', () async {
    final LocalCollectionsStorage storage = LocalCollectionsStorage();
    final Map<String, Set<int>> collections = await storage.getCollections();
    expect(collections, isEmpty);
  });

  test('add and remove bag in collection persists state', () async {
    final LocalCollectionsStorage storage = LocalCollectionsStorage();

    await storage.addBagToCollection(collectionName: 'Favorites', bagId: 10);
    Map<String, Set<int>> afterAdd = await storage.getCollections();
    expect(afterAdd['Favorites']?.contains(10), isTrue);

    await storage.removeBagFromCollection(collectionName: 'Favorites', bagId: 10);
    final Map<String, Set<int>> afterRemove = await storage.getCollections();
    expect(afterRemove['Favorites'] ?? <int>{}, isEmpty);
  });

  test('rename and remove collection', () async {
    final LocalCollectionsStorage storage = LocalCollectionsStorage();

    await storage.addBagToCollection(collectionName: 'Temp', bagId: 1);
    await storage.renameCollection(oldName: 'Temp', newName: 'Renamed');

    Map<String, Set<int>> afterRename = await storage.getCollections();
    expect(afterRename.containsKey('Temp'), isFalse);
    expect(afterRename.containsKey('Renamed'), isTrue);

    await storage.removeCollection('Renamed');
    afterRename = await storage.getCollections();
    expect(afterRename.containsKey('Renamed'), isFalse);
  });
}

