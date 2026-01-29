import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';
import '../data/recommendations_api.dart';

final Provider<RecommendationsApi> recommendationsApiProvider = Provider<RecommendationsApi>((Ref ref) {
  return RecommendationsApi();
});

/// State class to hold both recommended bags and belts
class RecommendationsState {
  const RecommendationsState({
    required this.bags,
    required this.belts,
  });

  final List<Bag> bags;
  final List<Belt> belts;

  bool get isEmpty => bags.isEmpty && belts.isEmpty;
  bool get hasRecommendations => bags.isNotEmpty || belts.isNotEmpty;
}

/// Provider for the "For You" recommendation system.
/// Uses Content-Based Filtering based on user's favorites.
class RecommendationsNotifier extends AsyncNotifier<RecommendationsState> {
  late final RecommendationsApi _api;

  @override
  Future<RecommendationsState> build() async {
    _api = ref.read(recommendationsApiProvider);
    return _load();
  }

  Future<RecommendationsState> _load() async {
    try {
      // Fetch bags and belts in parallel
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        _api.getRecommendedBags(take: 6),
        _api.getRecommendedBelts(take: 6),
      ]);

      return RecommendationsState(
        bags: results[0] as List<Bag>,
        belts: results[1] as List<Belt>,
      );
    } catch (e) {
      // If there's an error (e.g., user not logged in), return empty state
      return const RecommendationsState(bags: <Bag>[], belts: <Belt>[]);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading<RecommendationsState>();
    state = await AsyncValue.guard(_load);
  }
}

final AsyncNotifierProvider<RecommendationsNotifier, RecommendationsState> recommendationsProvider =
    AsyncNotifierProvider<RecommendationsNotifier, RecommendationsState>(RecommendationsNotifier.new);
