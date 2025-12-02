import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/application/bags_provider.dart';
import '../../bags/domain/bag.dart';

class BagStockEntry {
  const BagStockEntry({required this.label, required this.count});

  final String label;
  final int count;
}

final FutureProvider<List<BagStockEntry>> bagStockProvider = FutureProvider<List<BagStockEntry>>((Ref ref) async {
  final bagsApi = ref.watch(bagsApiProvider);
  final List<Bag> bags = await bagsApi.getBags();
  final Map<String, int> counts = <String, int>{};

  for (final Bag bag in bags) {
    final String label = bag.name.trim().isEmpty ? 'Nepoznata torba' : bag.name.trim();
    counts[label] = (counts[label] ?? 0) + 1;
  }

  final List<BagStockEntry> sorted = counts.entries
      .map((MapEntry<String, int> e) => BagStockEntry(label: e.key, count: e.value))
      .toList()
    ..sort((BagStockEntry a, BagStockEntry b) => b.count.compareTo(a.count));

  const int maxBars = 8;
  if (sorted.length <= maxBars) {
    return sorted;
  }

  final List<BagStockEntry> trimmed = sorted.take(maxBars - 1).toList();
  final int othersCount = sorted.skip(maxBars - 1).fold<int>(0, (int sum, BagStockEntry entry) => sum + entry.count);
  return <BagStockEntry>[
    ...trimmed,
    BagStockEntry(label: 'Ostale', count: othersCount),
  ];
});

