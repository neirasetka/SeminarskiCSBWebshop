import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/favorites_api.dart';
import '../data/local_favorites_storage.dart';
import '../domain/favorites_collections.dart';

final Provider<LocalFavoritesStorage> localFavoritesStorageProvider =
    Provider<LocalFavoritesStorage>((Ref ref) => LocalFavoritesStorage());

final Provider<FavoritesApi> favoritesApiProvider =
    Provider<FavoritesApi>((Ref ref) => FavoritesApi());

bool _isLoggedIn(Ref ref) {
  final int? userId = ref.read(authControllerProvider).value?.userId;
  return userId != null && userId > 0;
}

class FavoritesNotifier extends AsyncNotifier<FavoritesCollections> {
  late final LocalFavoritesStorage _storage;
  late final FavoritesApi _api;

  Future<FavoritesCollections> _loadLocal() async {
    final Set<int> bags = await _storage.getFavoriteBagIds();
    final Set<int> belts = await _storage.getFavoriteBeltIds();
    return FavoritesCollections(bagIds: bags, beltIds: belts);
  }

  @override
  Future<FavoritesCollections> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    _api = ref.read(favoritesApiProvider);

    ref.watch(authControllerProvider);

    if (_isLoggedIn(ref)) {
      try {
        final Set<int> bagIds = await _api.getFavoriteBagIds();
        final Set<int> beltIds = await _api.getFavoriteBeltIds();
        await _storage.saveFavoriteBagIds(bagIds);
        await _storage.saveFavoriteBeltIds(beltIds);
        return FavoritesCollections(bagIds: bagIds, beltIds: beltIds);
      } catch (_) {
        return _loadLocal();
      }
    }
    return _loadLocal();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<FavoritesCollections>();
    state = await AsyncValue.guard(build);
  }

  Future<void> toggleBag(int bagId) async {
    if (_isLoggedIn(ref)) {
      try {
        final Set<int> updatedBags = await _api.toggleBagFavorite(bagId);
        final Set<int> beltIds =
            state.value?.beltIds ?? await _storage.getFavoriteBeltIds();
        await _storage.saveFavoriteBagIds(updatedBags);
        state = AsyncData<FavoritesCollections>(
          FavoritesCollections(bagIds: updatedBags, beltIds: beltIds),
        );
        return;
      } catch (_) {
        // Fall back to local storage if backend fails
      }
    }
    final Set<int> bags = await _storage.toggleBagFavorite(bagId);
    final Set<int> belts =
        state.value?.beltIds ?? await _storage.getFavoriteBeltIds();
    state = AsyncData<FavoritesCollections>(
      FavoritesCollections(bagIds: bags, beltIds: belts),
    );
  }

  Future<void> toggleBelt(int beltId) async {
    if (_isLoggedIn(ref)) {
      try {
        final Set<int> updatedBelts = await _api.toggleBeltFavorite(beltId);
        final Set<int> bagIds =
            state.value?.bagIds ?? await _storage.getFavoriteBagIds();
        await _storage.saveFavoriteBeltIds(updatedBelts);
        state = AsyncData<FavoritesCollections>(
          FavoritesCollections(bagIds: bagIds, beltIds: updatedBelts),
        );
        return;
      } catch (_) {
        // Fall back to local storage if backend fails
      }
    }
    final Set<int> belts = await _storage.toggleBeltFavorite(beltId);
    final Set<int> bagIds =
        state.value?.bagIds ?? await _storage.getFavoriteBagIds();
    state = AsyncData<FavoritesCollections>(
      FavoritesCollections(bagIds: bagIds, beltIds: belts),
    );
  }
}

final AsyncNotifierProvider<FavoritesNotifier, FavoritesCollections> favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, FavoritesCollections>(FavoritesNotifier.new);
