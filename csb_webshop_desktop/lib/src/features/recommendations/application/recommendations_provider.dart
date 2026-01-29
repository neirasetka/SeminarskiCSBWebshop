import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';
import '../../favorites/application/favorites_provider.dart';
import '../data/recommendations_api.dart';

/// Provider for the recommendations API.
final Provider<RecommendationsApi> recommendationsApiProvider =
    Provider<RecommendationsApi>((Ref ref) => RecommendationsApi());

/// Combined recommendations model containing both bags and belts.
class Recommendations {
  const Recommendations({
    required this.bags,
    required this.belts,
  });

  final List<Bag> bags;
  final List<Belt> belts;

  bool get isEmpty => bags.isEmpty && belts.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Provider for fetching personalized recommendations.
/// Watches auth state and favorites to auto-refresh when they change.
class RecommendationsNotifier extends AsyncNotifier<Recommendations> {
  late final RecommendationsApi _api;

  @override
  Future<Recommendations> build() async {
    _api = ref.read(recommendationsApiProvider);

    // Watch auth state - recommendations depend on user being logged in
    final authState = ref.watch(authControllerProvider);
    final userId = authState.value?.userId;

    if (userId == null || userId <= 0) {
      // User not logged in - no recommendations
      return const Recommendations(bags: <Bag>[], belts: <Belt>[]);
    }

    // Watch favorites - when favorites change, recommendations should update
    ref.watch(favoritesProvider);
    ref.watch(beltFavoritesProvider);

    // Fetch recommendations in parallel
    final results = await Future.wait(<Future<Object>>[
      _api.getRecommendedBags(take: 6),
      _api.getRecommendedBelts(take: 6),
    ]);

    return Recommendations(
      bags: results[0] as List<Bag>,
      belts: results[1] as List<Belt>,
    );
  }

  /// Manually refresh recommendations.
  Future<void> refresh() async {
    state = const AsyncLoading<Recommendations>();
    state = await AsyncValue.guard(() => build());
  }
}

/// Main provider for recommendations.
final AsyncNotifierProvider<RecommendationsNotifier, Recommendations> recommendationsProvider =
    AsyncNotifierProvider<RecommendationsNotifier, Recommendations>(RecommendationsNotifier.new);

/// Provider for recommended bags only.
final FutureProvider<List<Bag>> recommendedBagsProvider = FutureProvider<List<Bag>>((Ref ref) async {
  final recommendations = await ref.watch(recommendationsProvider.future);
  return recommendations.bags;
});

/// Provider for recommended belts only.
final FutureProvider<List<Belt>> recommendedBeltsProvider = FutureProvider<List<Belt>>((Ref ref) async {
  final recommendations = await ref.watch(recommendationsProvider.future);
  return recommendations.belts;
});
