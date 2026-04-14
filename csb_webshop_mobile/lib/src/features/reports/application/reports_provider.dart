import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_api.dart';
import '../domain/report_models.dart';

final Provider<ReportsApi> reportsApiProvider = Provider<ReportsApi>((Ref ref) => ReportsApi());

/// Revenue summed by calendar month (12 values, Jan–Dec) for the current UTC year.
final FutureProvider<List<double>> monthlySalesProvider = FutureProvider<List<double>>((Ref ref) async {
  final ReportsApi api = ref.read(reportsApiProvider);
  final DateTime nowUtc = DateTime.now().toUtc();
  final DateTime from = DateTime.utc(nowUtc.year, 1, 1);
  final DateTime to = DateTime.utc(nowUtc.year, 12, 31, 23, 59, 59);
  final List<RevenueByDayPoint> days = await api.getRevenueByDay(fromDateUtc: from, toDateUtc: to);
  final List<double> months = List<double>.filled(12, 0);
  for (final RevenueByDayPoint p in days) {
    final DateTime d = p.dayUtc.toUtc();
    if (d.year == nowUtc.year && d.month >= 1 && d.month <= 12) {
      months[d.month - 1] += p.revenue;
    }
  }
  return months;
});

final FutureProvider<List<TopSellingBagEntry>> topSellingBagsWithQuantitiesProvider =
    FutureProvider<List<TopSellingBagEntry>>((Ref ref) async {
  final ReportsApi api = ref.read(reportsApiProvider);
  return api.getTopSellingBagsWithQuantities(take: 6);
});

final FutureProvider<List<OrderStatusCountEntry>> orderStatusCountsProvider =
    FutureProvider<List<OrderStatusCountEntry>>((Ref ref) async {
  final ReportsApi api = ref.read(reportsApiProvider);
  return api.getOrderStatusCounts();
});
