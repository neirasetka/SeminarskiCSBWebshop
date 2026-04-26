import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_favorites_storage.dart';
import '../domain/favorites_collections.dart';

final Provider<LocalFavoritesStorage> localFavoritesStorageProvider =
    Provider<LocalFavoritesStorage>((Ref ref) => LocalFavoritesStorage());

class FavoritesNotifier extends AsyncNotifier<FavoritesCollections> {
  late final LocalFavoritesStorage _storage;

  Future<FavoritesCollections> _loadAll() async {
    final Set<int> bags = await _storage.getFavoriteBagIds();
    final Set<int> belts = await _storage.getFavoriteBeltIds();
    return FavoritesCollections(bagIds: bags, beltIds: belts);
  }

  @override
  Future<FavoritesCollections> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    return _loadAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<FavoritesCollections>();
    state = await AsyncValue.guard(_loadAll);
  }

  Future<void> toggleBag(int bagId) async {
    await _storage.toggleBagFavorite(bagId);
    state = AsyncData<FavoritesCollections>(await _loadAll());
  }

  Future<void> toggleBelt(int beltId) async {
    await _storage.toggleBeltFavorite(beltId);
    state = AsyncData<FavoritesCollections>(await _loadAll());
  }
}

final AsyncNotifierProvider<FavoritesNotifier, FavoritesCollections> favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, FavoritesCollections>(FavoritesNotifier.new);
