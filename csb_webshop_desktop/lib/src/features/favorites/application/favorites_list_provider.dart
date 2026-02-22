import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/application/bags_provider.dart';
import '../../bags/data/bags_api.dart';
import '../../bags/domain/bag.dart';
import '../../belts/application/belts_provider.dart';
import '../../belts/data/belts_api.dart';
import '../../belts/domain/belt.dart';
import 'favorites_provider.dart';

/// Result of loading favorite bags and belts by IDs.
class FavoritesListResult {
  const FavoritesListResult({
    required this.bags,
    required this.belts,
  });

  final List<Bag> bags;
  final List<Belt> belts;

  bool get isEmpty => bags.isEmpty && belts.isEmpty;
}

/// Loads full Bag and Belt objects for the current favorite IDs.
final favoritesListProvider =
    FutureProvider.autoDispose<FavoritesListResult>((Ref ref) async {
  final AsyncValue<Set<int>> bagIdsAsync = ref.watch(favoritesProvider);
  final AsyncValue<Set<int>> beltIdsAsync = ref.watch(beltFavoritesProvider);

  final Set<int> bagIds = bagIdsAsync.value ?? <int>{};
  final Set<int> beltIds = beltIdsAsync.value ?? <int>{};

  if (bagIds.isEmpty && beltIds.isEmpty) {
    return const FavoritesListResult(bags: <Bag>[], belts: <Belt>[]);
  }

  final BagsApi bagsApi = ref.read(bagsApiProvider);
  final BeltsApi beltsApi = ref.read(beltsApiProvider);

  final List<Bag> bags = <Bag>[];
  for (final int id in bagIds) {
    try {
      final Bag bag = await bagsApi.getBagById(id);
      bags.add(bag);
    } catch (_) {
      // Skip if bag was deleted or fetch failed
    }
  }

  final List<Belt> belts = <Belt>[];
  for (final int id in beltIds) {
    try {
      final Belt belt = await beltsApi.getBeltById(id);
      belts.add(belt);
    } catch (_) {
      // Skip if belt was deleted or fetch failed
    }
  }

  return FavoritesListResult(bags: bags, belts: belts);
});
