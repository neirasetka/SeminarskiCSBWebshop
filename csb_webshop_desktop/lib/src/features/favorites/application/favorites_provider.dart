import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/favorites_api.dart';
import '../data/local_favorites_storage.dart';

final Provider<LocalFavoritesStorage> localFavoritesStorageProvider =
    Provider<LocalFavoritesStorage>((Ref ref) => LocalFavoritesStorage());

final Provider<FavoritesApi> favoritesApiProvider =
    Provider<FavoritesApi>((Ref ref) => FavoritesApi());

bool _isLoggedIn(Ref ref) {
  final int? userId = ref.read(authControllerProvider).value?.userId;
  return userId != null && userId > 0;
}

// Bag favorites provider - syncs with backend when user is logged in
class FavoritesNotifier extends AsyncNotifier<Set<int>> {
  late final LocalFavoritesStorage _storage;
  late final FavoritesApi _api;

  @override
  Future<Set<int>> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    _api = ref.read(favoritesApiProvider);

    ref.watch(authControllerProvider);

    if (_isLoggedIn(ref)) {
      try {
        final Set<int> backendFavorites = await _api.getFavoriteBagIds();
        await _storage.saveFavoriteBagIds(backendFavorites);
        return backendFavorites;
      } catch (_) {
        return _storage.getFavoriteBagIds();
      }
    }
    return _storage.getFavoriteBagIds();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Set<int>>();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> toggleBag(int bagId) async {
    if (_isLoggedIn(ref)) {
      try {
        final Set<int> updated = await _api.toggleBagFavorite(bagId);
        await _storage.saveFavoriteBagIds(updated);
        state = AsyncData<Set<int>>(updated);
        return;
      } catch (_) {
        // Fall back to local storage if backend fails
      }
    }
    final Set<int> updated = await _storage.toggleFavorite(bagId);
    state = AsyncData<Set<int>>(updated);
  }

  bool isFavoriteSync(int bagId) {
    final Set<int>? current = state.value;
    if (current == null) return false;
    return current.contains(bagId);
  }
}

final AsyncNotifierProvider<FavoritesNotifier, Set<int>> favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);

class BeltFavoritesNotifier extends AsyncNotifier<Set<int>> {
  late final LocalFavoritesStorage _storage;
  late final FavoritesApi _api;

  @override
  Future<Set<int>> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    _api = ref.read(favoritesApiProvider);

    ref.watch(authControllerProvider);

    if (_isLoggedIn(ref)) {
      try {
        final Set<int> backendFavorites = await _api.getFavoriteBeltIds();
        await _storage.saveFavoriteBeltIds(backendFavorites);
        return backendFavorites;
      } catch (_) {
        return _storage.getFavoriteBeltIds();
      }
    }
    return _storage.getFavoriteBeltIds();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Set<int>>();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> toggleBelt(int beltId) async {
    if (_isLoggedIn(ref)) {
      try {
        final Set<int> updated = await _api.toggleBeltFavorite(beltId);
        await _storage.saveFavoriteBeltIds(updated);
        state = AsyncData<Set<int>>(updated);
        return;
      } catch (_) {
        // Fall back to local storage if backend fails
      }
    }
    final Set<int> updated = await _storage.toggleBeltFavorite(beltId);
    state = AsyncData<Set<int>>(updated);
  }

  bool isFavoriteSync(int beltId) {
    final Set<int>? current = state.value;
    if (current == null) return false;
    return current.contains(beltId);
  }
}

final AsyncNotifierProvider<BeltFavoritesNotifier, Set<int>> beltFavoritesProvider =
    AsyncNotifierProvider<BeltFavoritesNotifier, Set<int>>(BeltFavoritesNotifier.new);
