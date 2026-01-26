import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

