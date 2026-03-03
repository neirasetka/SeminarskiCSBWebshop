import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/report_models.dart';

/// Mobile reports use mock data only. Reports with real API are admin-only on desktop.
final Provider<List<TopSellingBagEntry>> topSellingBagsWithQuantitiesProvider =
    Provider<List<TopSellingBagEntry>>((Ref ref) => _mockTopBags);

final Provider<List<OrderStatusCountEntry>> orderStatusCountsProvider =
    Provider<List<OrderStatusCountEntry>>((Ref ref) => _mockOrderStatuses);

const List<double> _mockMonthlySales = <double>[
  1200, 1500, 1800, 1300, 2200, 2700, 3000, 2800, 2600, 2400, 2000, 1900,
];

final Provider<List<double>> monthlySalesProvider =
    Provider<List<double>>((Ref ref) => _mockMonthlySales);

const List<TopSellingBagEntry> _mockTopBags = <TopSellingBagEntry>[
  TopSellingBagEntry(bagName: 'LEA', quantitySold: 45),
  TopSellingBagEntry(bagName: 'MIA', quantitySold: 32),
  TopSellingBagEntry(bagName: 'SOFIA', quantitySold: 28),
  TopSellingBagEntry(bagName: 'EVA', quantitySold: 22),
  TopSellingBagEntry(bagName: 'NORA', quantitySold: 18),
];

const List<OrderStatusCountEntry> _mockOrderStatuses = <OrderStatusCountEntry>[
  OrderStatusCountEntry(statusName: 'Isporučeno', count: 12),
  OrderStatusCountEntry(statusName: 'U obradi', count: 5),
  OrderStatusCountEntry(statusName: 'Poslano', count: 3),
];
