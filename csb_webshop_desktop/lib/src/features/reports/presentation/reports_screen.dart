import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/bag_stock_provider.dart';
import '../application/belt_stock_provider.dart';
import '../application/bestselling_bags_provider.dart';
import '../data/reports_pdf_exporter.dart';
import '../domain/report_models.dart';

/// Which report block to export to PDF (same sections as on screen).
enum ReportPdfExportKind {
  bagStock('Dostupnost torbi', 'dostupnost_torbi'),
  topBags('Najprodavanije torbice', 'najprodavanije_torbice'),
  beltStock('Dostupnost kaiseva', 'dostupnost_kaiseva'),
  topBelts('Najprodavaniji kaisevi', 'najprodavaniji_kaisevi'),
  orderStatus('Status narudžbi', 'status_narudzbi');

  const ReportPdfExportKind(this.label, this.fileSlug);
  final String label;
  final String fileSlug;

  String suggestedFileName() {
    final DateTime n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final String ts = '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}';
    return 'izvjestaj_${fileSlug}_$ts.pdf';
  }
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPdfExportKind _selectedExport = ReportPdfExportKind.bagStock;
  bool _exportingPdf = false;

  Future<void> _exportToPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      late final String title;
      late final List<String> headers;
      late final List<List<String>> rows;

      switch (_selectedExport) {
        case ReportPdfExportKind.bagStock:
          final List<BagStockEntry> list = await ref.read(bagStockProvider.future);
          if (list.isEmpty) {
            _showSnack('Nema podataka za dostupnost torbi.');
            return;
          }
          title = _selectedExport.label;
          headers = <String>['Naziv', 'Količina na stanju'];
          rows = list.map((BagStockEntry e) => <String>[e.label, e.count.toString()]).toList();
        case ReportPdfExportKind.topBags:
          final List<TopSellingBagEntry> list = await ref.read(topSellingBagsWithQuantitiesProvider.future);
          if (list.isEmpty) {
            _showSnack('Nema podataka o prodaji torbi.');
            return;
          }
          title = _selectedExport.label;
          headers = <String>['Torba', 'Prodano kom.'];
          rows = list.map((TopSellingBagEntry e) => <String>[e.bagName, e.quantitySold.toString()]).toList();
        case ReportPdfExportKind.beltStock:
          final List<BeltStockEntry> list = await ref.read(beltStockProvider.future);
          if (list.isEmpty) {
            _showSnack('Nema podataka za dostupnost kaiseva.');
            return;
          }
          title = _selectedExport.label;
          headers = <String>['Naziv', 'Količina na stanju'];
          rows = list.map((BeltStockEntry e) => <String>[e.label, e.count.toString()]).toList();
        case ReportPdfExportKind.topBelts:
          final List<TopSellingBeltEntry> list = await ref.read(topSellingBeltsWithQuantitiesProvider.future);
          if (list.isEmpty) {
            _showSnack('Nema podataka o prodaji kaiseva.');
            return;
          }
          title = _selectedExport.label;
          headers = <String>['Kaiš', 'Prodano kom.'];
          rows = list.map((TopSellingBeltEntry e) => <String>[e.beltName, e.quantitySold.toString()]).toList();
        case ReportPdfExportKind.orderStatus:
          final List<OrderStatusCountEntry> list = await ref.read(orderStatusCountsProvider.future);
          if (list.isEmpty) {
            _showSnack('Nema podataka o statusu narudžbi.');
            return;
          }
          title = _selectedExport.label;
          headers = <String>['Status', 'Broj narudžbi'];
          rows = list.map((OrderStatusCountEntry e) => <String>[e.statusName, e.count.toString()]).toList();
      }

      final Uint8List bytes = await ReportsPdfExporter.buildTableReport(
        title: title,
        columnHeaders: headers,
        bodyRows: rows,
      );

      if (!mounted) return;
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Spremi PDF izvještaj',
        fileName: _selectedExport.suggestedFileName(),
        type: FileType.custom,
        allowedExtensions: const <String>['pdf'],
      );
      if (path == null || !mounted) return;

      final String outPath = path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
      await File(outPath).writeAsBytes(bytes);
      if (!mounted) return;
      _showSnack('PDF je spremljen.');
    } catch (e) {
      if (mounted) {
        _showSnack('Greška pri izvozu: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    final Color? color = error ? Theme.of(context).colorScheme.error : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Nazad',
          onPressed: () => context.go('/'),
        ),
        title: const Text('Izvještaji'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _PdfExportToolbar(
            selected: _selectedExport,
            exporting: _exportingPdf,
            onKindChanged: (ReportPdfExportKind? v) {
              if (v != null) setState(() => _selectedExport = v);
            },
            onExportPdf: _exportToPdf,
          ),
          const SizedBox(height: 8),
          const _SectionTitle('Dostupnost torbi'),
          const _StockAvailabilityChart(),
          const SizedBox(height: 24),
          const _SectionTitle('Najprodavanije torbice'),
          const _TopBagsPieChart(),
          const SizedBox(height: 24),
          const _SectionTitle('Dostupnost kaiseva'),
          const _BeltStockAvailabilityChart(),
          const SizedBox(height: 24),
          const _SectionTitle('Najprodavaniji kaisevi'),
          const _TopBeltsPieChart(),
          const SizedBox(height: 24),
          const _SectionTitle('Status narudžbi'),
          const _OrderStatusPieChart(),
        ],
      ),
    );
  }
}

class _PdfExportToolbar extends StatelessWidget {
  const _PdfExportToolbar({
    required this.selected,
    required this.exporting,
    required this.onKindChanged,
    required this.onExportPdf,
  });

  final ReportPdfExportKind selected;
  final bool exporting;
  final ValueChanged<ReportPdfExportKind?> onKindChanged;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Izvještaj za PDF',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReportPdfExportKind>(
                    isExpanded: true,
                    value: selected,
                    borderRadius: BorderRadius.circular(8),
                    items: ReportPdfExportKind.values
                        .map(
                          (ReportPdfExportKind k) => DropdownMenuItem<ReportPdfExportKind>(
                            value: k,
                            child: Text(k.label, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: exporting ? null : onKindChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: exporting ? null : onExportPdf,
              icon: exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Spremi PDF'),
            ),
          ],
        ),
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
  const _Card({required this.child, this.chartHeight = 240});

  final Widget child;

  /// Fixed height for chart area (taller when bottom axis needs multiple label lines).
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: chartHeight, child: child),
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
      chartHeight: 268,
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double chartW = constraints.maxWidth.isFinite ? constraints.maxWidth : 320;
        final double slotW = entries.isEmpty ? chartW : chartW / entries.length;
        final double labelMaxW = (slotW - 8).clamp(56.0, 132.0);
        final double bottomReserved = labelMaxW >= 100 ? 96.0 : 84.0;

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
                  reservedSize: bottomReserved,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                    final BagStockEntry entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: labelMaxW,
                        child: Text(
                          entry.label,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: labelStyle.copyWith(fontSize: 11, height: 1.15),
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
      },
    );
  }
}

class _BeltStockAvailabilityChart extends ConsumerWidget {
  const _BeltStockAvailabilityChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BeltStockEntry>> stockAsync = ref.watch(beltStockProvider);

    return _Card(
      chartHeight: 268,
      child: stockAsync.when(
        data: (List<BeltStockEntry> entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Trenutno nema dostupnih kaiseva.'));
          }
          return _BeltAvailabilityBarChart(entries: entries);
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

class _BeltAvailabilityBarChart extends StatelessWidget {
  const _BeltAvailabilityBarChart({required this.entries});

  final List<BeltStockEntry> entries;

  @override
  Widget build(BuildContext context) {
    final double baseMax =
        entries.fold<double>(0, (double maxValue, BeltStockEntry e) => e.count > maxValue ? e.count.toDouble() : maxValue);
    final double maxY = baseMax == 0 ? 1 : baseMax * 1.2;
    final double interval = baseMax <= 4 ? 1 : (baseMax / 4).ceilToDouble();
    final TextStyle labelStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double chartW = constraints.maxWidth.isFinite ? constraints.maxWidth : 320;
        final double slotW = entries.isEmpty ? chartW : chartW / entries.length;
        final double labelMaxW = (slotW - 8).clamp(56.0, 132.0);
        final double bottomReserved = labelMaxW >= 100 ? 96.0 : 84.0;

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
                  reservedSize: bottomReserved,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                    final BeltStockEntry entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: labelMaxW,
                        child: Text(
                          entry.label,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: labelStyle.copyWith(fontSize: 11, height: 1.15),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List<BarChartGroupData>.generate(entries.length, (int index) {
              final BeltStockEntry entry = entries[index];
              return BarChartGroupData(
                x: index,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: entry.count.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(colors: <Color>[Color(0xFF26A69A), Color(0xFF00897B)]),
                  ),
                ],
              );
            }),
          ),
        );
      },
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
                showTitle: false,
                radius: 70,
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

class _TopBeltsPieChart extends ConsumerWidget {
  const _TopBeltsPieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TopSellingBeltEntry>> asyncData = ref.watch(topSellingBeltsWithQuantitiesProvider);

    return _Card(
      child: asyncData.when(
        data: (List<TopSellingBeltEntry> entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Nema podataka o prodaji kaiseva.'));
          }
          final List<Color> colors = <Color>[
            const Color(0xFF26A69A),
            const Color(0xFF00897B),
            const Color(0xFF5C6BC0),
            const Color(0xFF78909C),
          ];
          final TextStyle labelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              );
          final List<PieChartSectionData> sections = List<PieChartSectionData>.generate(
            entries.length,
            (int i) {
              final TopSellingBeltEntry e = entries[i];
              final Color color = colors[i % colors.length];
              return PieChartSectionData(
                color: color,
                value: e.quantitySold.toDouble(),
                showTitle: false,
                radius: 70,
                badgeWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${e.beltName} (${e.quantitySold})', style: labelStyle),
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

