import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/domain/bag.dart';
import '../data/reports_api.dart';

/// Provider for the reports API (admin-only).
final Provider<ReportsApi> reportsApiProvider = Provider<ReportsApi>((Ref ref) => ReportsApi());

/// Provider for top-selling bags (admin For You section).
final FutureProvider<List<Bag>> bestsellingBagsProvider = FutureProvider<List<Bag>>((Ref ref) async {
  final api = ref.read(reportsApiProvider);
  return api.getTopSellingBags(take: 6);
});
