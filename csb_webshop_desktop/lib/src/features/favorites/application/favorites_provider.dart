import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_favorites_storage.dart';

final Provider<LocalFavoritesStorage> localFavoritesStorageProvider =
    Provider<LocalFavoritesStorage>((Ref ref) => LocalFavoritesStorage());

// Bag favorites provider
class FavoritesNotifier extends AsyncNotifier<Set<int>> {
  late final LocalFavoritesStorage _storage;

  @override
  Future<Set<int>> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    return _storage.getFavoriteBagIds();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Set<int>>();
    state = await AsyncValue.guard(() => _storage.getFavoriteBagIds());
  }

  Future<void> toggleBag(int bagId) async {
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

// Belt favorites provider
class BeltFavoritesNotifier extends AsyncNotifier<Set<int>> {
  late final LocalFavoritesStorage _storage;

  @override
  Future<Set<int>> build() async {
    _storage = ref.read(localFavoritesStorageProvider);
    return _storage.getFavoriteBeltIds();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Set<int>>();
    state = await AsyncValue.guard(() => _storage.getFavoriteBeltIds());
  }

  Future<void> toggleBelt(int beltId) async {
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

