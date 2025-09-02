import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_collections_storage.dart';

final Provider<LocalCollectionsStorage> localCollectionsStorageProvider =
    Provider<LocalCollectionsStorage>((Ref ref) => LocalCollectionsStorage());

class CollectionsNotifier extends AsyncNotifier<Map<String, Set<int>>> {
  late final LocalCollectionsStorage _storage;

  @override
  Future<Map<String, Set<int>>> build() async {
    _storage = ref.read(localCollectionsStorageProvider);
    return _storage.getCollections();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Map<String, Set<int>>>();
    state = await AsyncValue.guard(() => _storage.getCollections());
  }

  Future<void> addToCollection({required String collectionName, required int bagId}) async {
    final Map<String, Set<int>> updated = await _storage.addBagToCollection(collectionName: collectionName, bagId: bagId);
    state = AsyncData<Map<String, Set<int>>>(updated);
  }

  Future<void> removeFromCollection({required String collectionName, required int bagId}) async {
    final Map<String, Set<int>> updated = await _storage.removeBagFromCollection(collectionName: collectionName, bagId: bagId);
    state = AsyncData<Map<String, Set<int>>>(updated);
  }

  Future<void> removeCollection(String name) async {
    final Map<String, Set<int>> updated = await _storage.removeCollection(name);
    state = AsyncData<Map<String, Set<int>>>(updated);
  }

  Future<void> renameCollection({required String oldName, required String newName}) async {
    final Map<String, Set<int>> updated = await _storage.renameCollection(oldName: oldName, newName: newName);
    state = AsyncData<Map<String, Set<int>>>(updated);
  }
}

final AsyncNotifierProvider<CollectionsNotifier, Map<String, Set<int>>> collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, Map<String, Set<int>>>(CollectionsNotifier.new);

