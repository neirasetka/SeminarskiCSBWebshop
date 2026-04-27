import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';
import '../data/recommendations_api.dart';

final Provider<RecommendationsApi> recommendationsApiProvider =
    Provider<RecommendationsApi>((Ref ref) => RecommendationsApi());

/// Kombinirane preporuke s API-ja (na serveru, prema omiljenim tipovima i ocjenama).
class Recommendations {
  const Recommendations({required this.bags, required this.belts});

  final List<Bag> bags;
  final List<Belt> belts;

  bool get isEmpty => bags.isEmpty && belts.isEmpty;
}

class RecommendationsNotifier extends AutoDisposeAsyncNotifier<Recommendations> {
  Future<Recommendations> _load() async {
    final RecommendationsApi api = ref.read(recommendationsApiProvider);
    final List<Object> results = await Future.wait(<Future<Object>>[
      api.getRecommendedBags(take: 8),
      api.getRecommendedBelts(take: 8),
    ]);
    return Recommendations(
      bags: results[0] as List<Bag>,
      belts: results[1] as List<Belt>,
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
