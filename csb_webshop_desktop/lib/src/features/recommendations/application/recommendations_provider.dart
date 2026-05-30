import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../favorites/application/favorites_provider.dart';
import '../data/recommendations_api.dart';
import '../domain/recommended_product.dart';

/// Provider for the recommendations API.
final Provider<RecommendationsApi> recommendationsApiProvider =
    Provider<RecommendationsApi>((Ref ref) => RecommendationsApi());

/// Combined recommendations model containing both bags and belts.
class Recommendations {
  const Recommendations({
    required this.bags,
    required this.belts,
  });

  final List<RecommendedProduct> bags;
  final List<RecommendedProduct> belts;

  bool get isEmpty => bags.isEmpty && belts.isEmpty;
  bool get isNotEmpty => !isEmpty;

  bool get hasPersonalizedItems =>
      bags.any((RecommendedProduct p) => p.isPersonalized) ||
      belts.any((RecommendedProduct p) => p.isPersonalized);
}

/// Provider for fetching personalized recommendations.
/// Watches auth state and favorites to auto-refresh when they change.
class RecommendationsNotifier extends AsyncNotifier<Recommendations> {
  @override
  Future<Recommendations> build() async {
    final api = ref.read(recommendationsApiProvider);

    final authState = ref.watch(authControllerProvider);
    final userId = authState.value?.userId;

    if (userId == null || userId <= 0) {
      return const Recommendations(bags: <RecommendedProduct>[], belts: <RecommendedProduct>[]);
    }

    ref.watch(favoritesProvider);
    ref.watch(beltFavoritesProvider);

    final results = await Future.wait(<Future<Object>>[
      api.getRecommendedBags(take: 6),
      api.getRecommendedBelts(take: 6),
    ]);

    return Recommendations(
      bags: results[0] as List<RecommendedProduct>,
      belts: results[1] as List<RecommendedProduct>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Recommendations>();
    state = await AsyncValue.guard(() => build());
  }
}

final AsyncNotifierProvider<RecommendationsNotifier, Recommendations> recommendationsProvider =
    AsyncNotifierProvider<RecommendationsNotifier, Recommendations>(RecommendationsNotifier.new);

final FutureProvider<List<RecommendedProduct>> recommendedBagsProvider =
    FutureProvider<List<RecommendedProduct>>((Ref ref) async {
  final recommendations = await ref.watch(recommendationsProvider.future);
  return recommendations.bags;
});

final FutureProvider<List<RecommendedProduct>> recommendedBeltsProvider =
    FutureProvider<List<RecommendedProduct>>((Ref ref) async {
  final recommendations = await ref.watch(recommendationsProvider.future);
  return recommendations.belts;
});
