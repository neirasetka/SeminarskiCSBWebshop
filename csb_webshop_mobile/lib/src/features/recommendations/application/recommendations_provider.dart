import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recommendations_api.dart';
import '../domain/recommended_product.dart';

final Provider<RecommendationsApi> recommendationsApiProvider =
    Provider<RecommendationsApi>((Ref ref) => RecommendationsApi());

/// Kombinirane preporuke s API-ja (content-based + popular fallback).
class Recommendations {
  const Recommendations({required this.bags, required this.belts});

  final List<RecommendedProduct> bags;
  final List<RecommendedProduct> belts;

  bool get isEmpty => bags.isEmpty && belts.isEmpty;

  bool get isFullyPersonalized =>
      bags.every((RecommendedProduct p) => p.isPersonalized) &&
      belts.every((RecommendedProduct p) => p.isPersonalized);
}

class RecommendationsNotifier extends AutoDisposeAsyncNotifier<Recommendations> {
  Future<Recommendations> _load() async {
    final RecommendationsApi api = ref.read(recommendationsApiProvider);
    final List<Object> results = await Future.wait(<Future<Object>>[
      api.getRecommendedBags(take: 8),
      api.getRecommendedBelts(take: 8),
    ]);
    return Recommendations(
      bags: results[0] as List<RecommendedProduct>,
      belts: results[1] as List<RecommendedProduct>,
    );
  }

  @override
  Future<Recommendations> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading<Recommendations>();
    state = await AsyncValue.guard(_load);
  }
}

final AutoDisposeAsyncNotifierProvider<RecommendationsNotifier, Recommendations>
    recommendationsProvider =
    AutoDisposeAsyncNotifierProvider<RecommendationsNotifier, Recommendations>(
  RecommendationsNotifier.new,
);
