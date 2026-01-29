import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/favorites_api.dart';
import '../data/local_favorites_storage.dart';

final Provider<LocalFavoritesStorage> localFavoritesStorageProvider =
    Provider<LocalFavoritesStorage>((Ref ref) => LocalFavoritesStorage());

final Provider<FavoritesApi> favoritesApiProvider =
    Provider<FavoritesApi>((Ref ref) => FavoritesApi());

// Bag favorites provider - syncs with backend when user is logged in
class FavoritesNotifier extends AsyncNotifier<Set<int>> {
  late final LocalFavoritesStorage _storage;
  late final FavoritesApi _api;

  int? get _userId => ref.read(authControllerProvider).value?.userId;

  @override
  Future<Set<int>> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    _api = ref.read(favoritesApiProvider);

    // Watch auth state to reload favorites when user logs in/out
    ref.watch(authControllerProvider);

    final int? userId = _userId;
    if (userId != null && userId > 0) {
      // User is logged in - fetch from backend
      try {
        final Set<int> backendFavorites = await _api.getFavoriteBagIds(userId);
        // Also update local storage for offline access
        await _storage.saveFavoriteBagIds(backendFavorites);
        return backendFavorites;
      } catch (_) {
        // Fall back to local storage if backend fails
        return _storage.getFavoriteBagIds();
      }
    }
    // User not logged in - use local storage only
    return _storage.getFavoriteBagIds();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Set<int>>();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> toggleBag(int bagId) async {
    final int? userId = _userId;
    if (userId != null && userId > 0) {
      // User is logged in - sync with backend
      try {
        final Set<int> updated = await _api.toggleBagFavorite(userId, bagId);
        await _storage.saveFavoriteBagIds(updated);
        state = AsyncData<Set<int>>(updated);
        return;
      } catch (_) {
        // Fall back to local storage if backend fails
      }
    }
    // User not logged in or backend failed - use local storage
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

// Belt favorites provider - syncs with backend when user is logged in
class BeltFavoritesNotifier extends AsyncNotifier<Set<int>> {
  late final LocalFavoritesStorage _storage;
  late final FavoritesApi _api;

  int? get _userId => ref.read(authControllerProvider).value?.userId;

  @override
  Future<Set<int>> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    _api = ref.read(favoritesApiProvider);

    // Watch auth state to reload favorites when user logs in/out
    ref.watch(authControllerProvider);

    final int? userId = _userId;
    if (userId != null && userId > 0) {
      // User is logged in - fetch from backend
      try {
        final Set<int> backendFavorites = await _api.getFavoriteBeltIds(userId);
        // Also update local storage for offline access
        await _storage.saveFavoriteBeltIds(backendFavorites);
        return backendFavorites;
      } catch (_) {
        // Fall back to local storage if backend fails
        return _storage.getFavoriteBeltIds();
      }
    }
    // User not logged in - use local storage only
    return _storage.getFavoriteBeltIds();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Set<int>>();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> toggleBelt(int beltId) async {
    final int? userId = _userId;
    if (userId != null && userId > 0) {
      // User is logged in - sync with backend
      try {
        final Set<int> updated = await _api.toggleBeltFavorite(userId, beltId);
        await _storage.saveFavoriteBeltIds(updated);
        state = AsyncData<Set<int>>(updated);
        return;
      } catch (_) {
        // Fall back to local storage if backend fails
      }
    }
    // User not logged in or backend failed - use local storage
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

