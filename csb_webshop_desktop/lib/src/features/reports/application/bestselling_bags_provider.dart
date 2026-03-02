import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/domain/bag.dart';
import '../data/reports_api.dart';
import '../domain/report_models.dart';

/// Provider for the reports API (admin-only).
final Provider<ReportsApi> reportsApiProvider = Provider<ReportsApi>((Ref ref) => ReportsApi());

/// Provider for top-selling bags (admin For You section).
final FutureProvider<List<Bag>> bestsellingBagsProvider = FutureProvider<List<Bag>>((Ref ref) async {
  final api = ref.read(reportsApiProvider);
  return api.getTopSellingBags(take: 6);
});

/// Provider for top-selling bags with quantities (reports pie chart).
final FutureProvider<List<TopSellingBagEntry>> topSellingBagsWithQuantitiesProvider =
    FutureProvider<List<TopSellingBagEntry>>((Ref ref) async {
  final api = ref.read(reportsApiProvider);
  return api.getTopSellingBagsWithQuantities(take: 6);
});

/// Provider for top-selling belts with quantities (reports pie chart).
final FutureProvider<List<TopSellingBeltEntry>> topSellingBeltsWithQuantitiesProvider =
    FutureProvider<List<TopSellingBeltEntry>>((Ref ref) async {
  final api = ref.read(reportsApiProvider);
  return api.getTopSellingBeltsWithQuantities(take: 6);
});

/// Provider for order status counts (reports pie chart).
final FutureProvider<List<OrderStatusCountEntry>> orderStatusCountsProvider =
    FutureProvider<List<OrderStatusCountEntry>>((Ref ref) async {
  final api = ref.read(reportsApiProvider);
  return api.getOrderStatusCounts();
});
