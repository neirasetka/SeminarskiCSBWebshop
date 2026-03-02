import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_provider.dart';
import '../domain/report_models.dart';

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
          _SectionTitle('Prodaja po mjesecu'),
          _SalesByMonthChart(),
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

class _SalesByMonthChart extends StatelessWidget {
  const _SalesByMonthChart();

  List<BarChartGroupData> _buildBarGroups() {
    // Mock data: month index (1-12) -> total sales amount
    const List<double> monthlySales = <double>[1200, 1500, 1800, 1300, 2200, 2700, 3000, 2800, 2600, 2400, 2000, 1900];
    return List<BarChartGroupData>.generate(monthlySales.length, (int i) {
      final double value = monthlySales[i];
      return BarChartGroupData(x: i + 1, barRods: <BarChartRodData>[
        BarChartRodData(toY: value, borderRadius: BorderRadius.circular(4), width: 14,
          gradient: const LinearGradient(colors: <Color>[Color(0xFF7C4DFF), Color(0xFF536DFE)]),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int month = value.toInt();
                  const List<String> labels = <String>['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  if (month >= 1 && month <= 12) {
                    return Padding(padding: const EdgeInsets.only(top: 6), child: Text(labels[month - 1]));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }
}

class _TopBagsPieChart extends ConsumerWidget {
  const _TopBagsPieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TopSellingBagEntry>> asyncData = ref.watch(topSellingBagsWithQuantitiesProvider);

    return _Card(
      child: asyncData.when(
        data: (List<TopSellingBagEntry> entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Nema podataka o prodaji torbi.'));
          }
          final List<Color> colors = <Color>[
            const Color(0xFF7E57C2),
            const Color(0xFF42A5F5),
            const Color(0xFF26A69A),
            const Color(0xFFFFCA28),
          ];
          final TextStyle labelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              );
          final List<PieChartSectionData> sections = List<PieChartSectionData>.generate(
            entries.length,
            (int i) {
              final TopSellingBagEntry e = entries[i];
              final Color color = colors[i % colors.length];
              return PieChartSectionData(
                color: color,
                value: e.quantitySold.toDouble(),
                title: e.bagName,
                radius: 70,
                titlePositionPercentageOffset: 1.3,
                badgeWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${e.bagName} (${e.quantitySold})', style: labelStyle),
                ),
                badgePositionPercentageOffset: 1.15,
              );
            },
          );
          return PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace _) => Center(
          child: Text(
            'Greška: ${err.toString()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusPieChart extends ConsumerWidget {
  const _OrderStatusPieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<OrderStatusCountEntry>> asyncData = ref.watch(orderStatusCountsProvider);

    return _Card(
      child: asyncData.when(
        data: (List<OrderStatusCountEntry> entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Nema narudžbi.'));
          }
          final List<Color> colors = <Color>[
            const Color(0xFF66BB6A),
            const Color(0xFF42A5F5),
            const Color(0xFFFFA726),
            const Color(0xFFEF5350),
            const Color(0xFFAB47BC),
            const Color(0xFF26A69A),
          ];
          final List<PieChartSectionData> sections = List<PieChartSectionData>.generate(
            entries.length,
            (int i) {
              final OrderStatusCountEntry e = entries[i];
              return PieChartSectionData(
                color: colors[i % colors.length],
                value: e.count.toDouble(),
                title: '${e.statusName}\n${e.count}',
                radius: 65,
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          );
          return PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: sections,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace _) => Center(
          child: Text(
            'Greška: ${err.toString()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

