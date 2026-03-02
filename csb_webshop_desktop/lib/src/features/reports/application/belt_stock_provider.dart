import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../belts/application/belts_provider.dart';
import '../../belts/domain/belt.dart';

class BeltStockEntry {
  const BeltStockEntry({required this.label, required this.count});

  final String label;
  final int count;
}

final FutureProvider<List<BeltStockEntry>> beltStockProvider =
    FutureProvider<List<BeltStockEntry>>((Ref ref) async {
  final beltsApi = ref.watch(beltsApiProvider);
  final List<Belt> belts = await beltsApi.getBelts();
  final Map<String, int> counts = <String, int>{};

  for (final Belt belt in belts) {
    final String label =
        belt.name.trim().isEmpty ? 'Nepoznati kaiš' : belt.name.trim();
    counts[label] = (counts[label] ?? 0) + 1;
  }

  final List<BeltStockEntry> sorted = counts.entries
      .map((MapEntry<String, int> e) => BeltStockEntry(label: e.key, count: e.value))
      .toList()
    ..sort((BeltStockEntry a, BeltStockEntry b) => b.count.compareTo(a.count));

  const int maxBars = 8;
  if (sorted.length <= maxBars) {
    return sorted;
  }

  final List<BeltStockEntry> trimmed = sorted.take(maxBars - 1).toList();
  final int othersCount = sorted
      .skip(maxBars - 1)
      .fold<int>(0, (int sum, BeltStockEntry entry) => sum + entry.count);
  return <BeltStockEntry>[
    ...trimmed,
    BeltStockEntry(label: 'Ostali', count: othersCount),
  ];
});
