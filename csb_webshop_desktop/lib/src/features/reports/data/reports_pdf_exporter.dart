import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Maps common Bosnian/Croatian/Serbian letters to ASCII so built-in PDF fonts
/// (Helvetica / WinAnsi) render reliably without bundling a TTF.
String foldPdfText(String input) {
  if (input.isEmpty) return input;
  const Map<String, String> map = <String, String>{
    'č': 'c',
    'ć': 'c',
    'Č': 'C',
    'Ć': 'C',
    'đ': 'dj',
    'Đ': 'Dj',
    'š': 's',
    'Š': 'S',
    'ž': 'z',
    'Ž': 'Z',
    'ä': 'a',
    'ö': 'o',
    'ü': 'u',
    'Ä': 'A',
    'Ö': 'O',
    'Ü': 'U',
    'ß': 'ss',
  };
  final StringBuffer out = StringBuffer();
  for (final String ch in input.split('')) {
    out.write(map[ch] ?? ch);
  }
  return out.toString();
}

/// Builds a simple tabular PDF (A4) for admin reports.
abstract final class ReportsPdfExporter {
  static Future<Uint8List> buildTableReport({
    required String title,
    required List<String> columnHeaders,
    required List<List<String>> bodyRows,
  }) async {
    final pw.Document doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );

    final List<dynamic> headers = columnHeaders.map(foldPdfText).toList();
    final List<List<dynamic>> data = bodyRows
        .map((List<String> row) => List<dynamic>.from(row.map(foldPdfText)))
        .toList();

    final String generated = _formatGeneratedTimestamp();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => <pw.Widget>[
          pw.Header(
            level: 0,
            child: pw.Text(
              foldPdfText(title),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            foldPdfText('Coco Sun Bags - administracija'),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 22,
            cellAlignments: <int, pw.AlignmentGeometry>{
              for (int i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            foldPdfText('Generisano: $generated'),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _formatGeneratedTimestamp() {
    final DateTime n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(n.day)}.${two(n.month)}.${n.year} ${two(n.hour)}:${two(n.minute)}';
  }
}
