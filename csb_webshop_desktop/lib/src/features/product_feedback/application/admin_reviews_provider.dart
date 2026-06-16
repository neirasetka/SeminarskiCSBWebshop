import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reviews_api.dart';
import '../domain/product_feedback.dart';
import '../presentation/product_feedback_section.dart';

class AdminReviewsNotifier extends AsyncNotifier<List<ProductReview>> {
  String _statusFilter = 'Pending';

  String get statusFilter => _statusFilter;

  ReviewsApi get _api => ref.read(reviewsApiProvider);

  @override
  Future<List<ProductReview>> build() async {
    return _api.getReviewsByStatus(statusKey: _statusFilter);
  }

  Future<void> refresh({String? statusKey}) async {
    if (statusKey != null) _statusFilter = statusKey;
    state = const AsyncLoading<List<ProductReview>>();
    state = await AsyncValue.guard(
      () => _api.getReviewsByStatus(statusKey: _statusFilter),
    );
  }

  Future<void> approve(int reviewId) async {
    await _api.approveReview(reviewId);
    await refresh();
  }

  Future<void> reject(int reviewId) async {
    await _api.rejectReview(reviewId);
    await refresh();
  }
}

final AsyncNotifierProvider<AdminReviewsNotifier, List<ProductReview>> adminReviewsProvider =
    AsyncNotifierProvider<AdminReviewsNotifier, List<ProductReview>>(AdminReviewsNotifier.new);
