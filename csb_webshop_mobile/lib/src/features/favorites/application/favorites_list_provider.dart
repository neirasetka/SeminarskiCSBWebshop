import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/application/bags_provider.dart';
import '../../bags/data/bags_api.dart';
import '../../bags/domain/bag.dart';
import '../../belts/application/belts_provider.dart';
import '../../belts/data/belts_api.dart';
import '../../belts/domain/belt.dart';
import 'favorites_provider.dart';
import '../domain/favorites_collections.dart';

/// Učitani favoriti (puni Bag/Belt objekti, ne samo ID-evi).
class FavoritesListResult {
  const FavoritesListResult({
    required this.bags,
    required this.belts,
  });

  final List<Bag> bags;
  final List<Belt> belts;

  bool get isEmpty => bags.isEmpty && belts.isEmpty;
}

/// Dohvaća torbe i kaiševe za trenutno spremljene favorite (po ID-u).
final AsyncNotifierProvider<FavoritesListNotifier, FavoritesListResult>
    favoritesListProvider =
    AsyncNotifierProvider<FavoritesListNotifier, FavoritesListResult>(
  FavoritesListNotifier.new,
);

class FavoritesListNotifier extends AsyncNotifier<FavoritesListResult> {
  @override
  Future<FavoritesListResult> build() async {
    ref.watch(favoritesProvider);
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<FavoritesListResult>();
    state = await AsyncValue.guard(_load);
  }

  Future<FavoritesListResult> _load() async {
    final FavoritesCollections collections =
        ref.read(favoritesProvider).valueOrNull ??
            await ref.read(favoritesProvider.future);

    if (collections.isEmpty) {
      return const FavoritesListResult(bags: <Bag>[], belts: <Belt>[]);
    }

    final BagsApi bagsApi = ref.read(bagsApiProvider);
    final BeltsApi beltsApi = ref.read(beltsApiProvider);

    final List<Bag> bags = <Bag>[];
    for (final int id in collections.bagIds) {
      try {
        bags.add(await bagsApi.getBagById(id));
      } catch (_) {
        // Preskoči ako artikal više ne postoji.
      }
    }

    final List<Belt> belts = <Belt>[];
    for (final int id in collections.beltIds) {
      try {
        belts.add(await beltsApi.getBeltById(id));
      } catch (_) {
        // Preskoči ako artikal više ne postoji.
      }
    }

    return FavoritesListResult(bags: bags, belts: belts);
  }
}
