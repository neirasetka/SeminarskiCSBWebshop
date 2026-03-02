import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_api.dart';
import '../domain/report_models.dart';

final Provider<ReportsApi> reportsApiProvider = Provider<ReportsApi>((Ref ref) => ReportsApi());

final FutureProvider<List<TopSellingBagEntry>> topSellingBagsWithQuantitiesProvider =
    FutureProvider<List<TopSellingBagEntry>>((Ref ref) async {
  final api = ref.read(reportsApiProvider);
  return api.getTopSellingBagsWithQuantities(take: 6);
});

final FutureProvider<List<OrderStatusCountEntry>> orderStatusCountsProvider =
    FutureProvider<List<OrderStatusCountEntry>>((Ref ref) async {
  final api = ref.read(reportsApiProvider);
  return api.getOrderStatusCounts();
});
