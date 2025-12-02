import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/bag_stock_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Izvještaji'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          _SectionTitle('Dostupnost torbi'),
          _StockAvailabilityChart(),
          SizedBox(height: 24),
          _SectionTitle('Najprodavanije torbice'),
          _TopBagsPieChart(),
          SizedBox(height: 24),
          _SectionTitle('Status narudžbi'),
          _OrderStatusPieChart(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: 240, child: child),
      ),
    );
  }
}

class _StockAvailabilityChart extends ConsumerWidget {
  const _StockAvailabilityChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BagStockEntry>> stockAsync = ref.watch(bagStockProvider);

    return _Card(
      child: stockAsync.when(
        data: (List<BagStockEntry> entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Trenutno nema dostupnih torbi.'));
          }
          return _BagAvailabilityBarChart(entries: entries);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: Text(
            'Greška pri učitavanju: ${error.toString()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _BagAvailabilityBarChart extends StatelessWidget {
  const _BagAvailabilityBarChart({required this.entries});

  final List<BagStockEntry> entries;

  @override
  Widget build(BuildContext context) {
    final double baseMax =
        entries.fold<double>(0, (double maxValue, BagStockEntry e) => e.count > maxValue ? e.count.toDouble() : maxValue);
    final double maxY = baseMax == 0 ? 1 : baseMax * 1.2;
    final double interval = baseMax <= 4 ? 1 : (baseMax / 4).ceilToDouble();
    final TextStyle labelStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return BarChart(
      BarChartData(
        maxY: maxY,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: interval,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value < 0) return const SizedBox.shrink();
                return Text(value.toInt().toString(), style: labelStyle);
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 64,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                final BagStockEntry entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 68,
                    child: Text(
                      entry.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(entries.length, (int index) {
          final BagStockEntry entry = entries[index];
          return BarChartGroupData(
            x: index,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: entry.count.toDouble(),
                width: 18,
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(colors: <Color>[Color(0xFF7C4DFF), Color(0xFF536DFE)]),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TopBagsPieChart extends StatelessWidget {
  const _TopBagsPieChart();

  List<PieChartSectionData> _sections(BuildContext context) {
    // Mock data: bag model -> units sold
    const Map<String, double> data = <String, double>{
      'Model A': 35,
      'Model B': 28,
      'Model C': 22,
      'Model D': 15,
    };
    final List<Color> colors = <Color>[const Color(0xFF7E57C2), const Color(0xFF42A5F5), const Color(0xFF26A69A), const Color(0xFFFFCA28)];
    final TextStyle labelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    int i = 0;
    return data.entries.map((MapEntry<String, double> e) {
      final PieChartSectionData section = PieChartSectionData(
        color: colors[i % colors.length],
        value: e.value,
        title: e.key,
        radius: 70,
        titlePositionPercentageOffset: 1.3,
        badgeWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(8)),
          child: Text('${e.key} (${e.value.toInt()})', style: labelStyle),
        ),
        badgePositionPercentageOffset: 1.15,
      );
      i += 1;
      return section;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _sections(context),
        ),
      ),
    );
  }
}

class _OrderStatusPieChart extends StatelessWidget {
  const _OrderStatusPieChart();

  List<PieChartSectionData> _sections() {
    // Mock data: status -> count
    const Map<String, double> data = <String, double>{
      'Kreirano': 18,
      'Plaćeno': 42,
      'Poslano': 30,
      'Otkazano': 6,
    };
    final List<Color> colors = <Color>[const Color(0xFF66BB6A), const Color(0xFF42A5F5), const Color(0xFFFFA726), const Color(0xFFEF5350)];
    int i = 0;
    return data.entries.map((MapEntry<String, double> e) {
      final PieChartSectionData section = PieChartSectionData(
        color: colors[i % colors.length],
        value: e.value,
        title: '${e.key}\n${e.value.toInt()}',
        radius: 65,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      );
      i += 1;
      return section;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 32,
          sections: _sections(),
        ),
      ),
    );
  }
}

