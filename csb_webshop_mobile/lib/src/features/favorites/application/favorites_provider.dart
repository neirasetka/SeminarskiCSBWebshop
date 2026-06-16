import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_session.dart';
import '../data/favorites_api.dart';
import '../data/local_favorites_storage.dart';
import '../domain/favorites_collections.dart';

final Provider<LocalFavoritesStorage> localFavoritesStorageProvider =
    Provider<LocalFavoritesStorage>((Ref ref) => LocalFavoritesStorage());

final Provider<FavoritesApi> favoritesApiProvider =
    Provider<FavoritesApi>((Ref ref) => FavoritesApi());

class FavoritesNotifier extends AsyncNotifier<FavoritesCollections> {
  LocalFavoritesStorage get _storage => ref.read(localFavoritesStorageProvider);
  FavoritesApi get _api => ref.read(favoritesApiProvider);

  Future<FavoritesCollections> _loadLocal() async {
    final Set<int> bags = await _storage.getFavoriteBagIds();
    final Set<int> belts = await _storage.getFavoriteBeltIds();
    return FavoritesCollections(bagIds: bags, beltIds: belts);
  }

  Future<FavoritesCollections> _loadForSession(AuthSession? auth) async {
    if (auth == null) {
      return _loadLocal();
    }
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

  @override
  Future<FavoritesCollections> build() async {
    final AuthSession? auth = await ref.watch(authControllerProvider.future);
    return _loadForSession(auth);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<FavoritesCollections>();
    final AuthSession? auth = ref.read(authControllerProvider).valueOrNull;
    state = await AsyncValue.guard(() => _loadForSession(auth));
  }

  Future<void> toggleBag(int bagId) async {
    final AuthSession? auth = ref.read(authControllerProvider).valueOrNull;
    if (auth != null) {
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
    final AuthSession? auth = ref.read(authControllerProvider).valueOrNull;
    if (auth != null) {
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
