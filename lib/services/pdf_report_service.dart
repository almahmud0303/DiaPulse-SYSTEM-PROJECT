import 'dart:typed_data';

import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/glucose_report_data.dart';
import 'package:dia_plus/models/glucose_report_stats.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a professional-grade PDF from a [GlucoseReportData] DTO.
///
/// Returns raw [Uint8List] bytes suitable for preview, sharing, or printing
/// via the `printing` package.
class PdfReportService {
  static const String _appName = 'DiaPulse';
  static const String _reportTitle = 'Diabetes Glucose Report';

  // ── Colour palette ─────────────────────────────────────────────────────────
  static const _teal = PdfColors.teal;
  static const _tealLight = PdfColors.teal50;
  static const _green = PdfColors.green;
  static const _orange = PdfColors.orange;
  static const _red = PdfColors.red;
  static const _blue = PdfColors.blue;
  static const _veryRed = PdfColors.red900;
  static const _grey50 = PdfColors.grey50;
  static const _grey200 = PdfColors.grey200;
  static const _grey600 = PdfColors.grey600;
  static const _grey900 = PdfColors.grey900;

  Future<Uint8List> generateReportPdf(GlucoseReportData data) async {
    final doc = pw.Document(title: _reportTitle, author: _appName);

    final boldFont = pw.Font.helveticaBold();
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: boldFont,
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );

    final dateFmt = DateFormat('d MMM yyyy');
    final timeFmt = DateFormat('HH:mm');
    final genFmt = DateFormat('d MMM yyyy, HH:mm');

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _buildHeader(boldFont, data, genFmt),
          pw.SizedBox(height: 20),
          if (_hasPatientInfo(data)) ...[
            _sectionTitle('Patient Information', boldFont),
            pw.SizedBox(height: 8),
            _buildPatientInfo(data, boldFont),
            pw.SizedBox(height: 16),
          ],
          _sectionTitle('Report Period', boldFont),
          pw.SizedBox(height: 8),
          _buildPeriodRow(data, dateFmt, boldFont),
          pw.SizedBox(height: 16),
          _sectionTitle('Summary Statistics', boldFont),
          pw.SizedBox(height: 8),
          if (!data.stats.hasData)
            _emptyNote('No readings available for the selected period.')
          else ...[
            _buildStatsRow(data.stats, boldFont),
            pw.SizedBox(height: 10),
            _buildStatusBreakdown(data.stats, boldFont),
          ],
          pw.SizedBox(height: 16),
          _sectionTitle('Trend Summary', boldFont),
          pw.SizedBox(height: 8),
          _buildTrendBox(data.trendSummary, boldFont),
          pw.SizedBox(height: 16),
          _sectionTitle('Readings Detail', boldFont),
          pw.SizedBox(height: 8),
          if (data.readings.isEmpty)
            _emptyNote('No readings available for the selected period.')
          else
            _buildTable(data.readings, dateFmt, timeFmt, boldFont),
        ],
      ),
    );

    return doc.save();
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(
    pw.Font boldFont,
    GlucoseReportData data,
    DateFormat genFmt,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _teal,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _appName,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 22,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _reportTitle,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated on',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                genFmt.format(data.generatedAt),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  pw.Widget _sectionTitle(String title, pw.Font boldFont) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: const pw.BoxDecoration(
            color: _teal,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(font: boldFont, fontSize: 13, color: _grey900),
        ),
      ],
    );
  }

  // ── Patient info ────────────────────────────────────────────────────────────

  bool _hasPatientInfo(GlucoseReportData data) =>
      data.patientName != null ||
      data.patientAge != null ||
      data.patientWeight != null ||
      data.patientHeight != null ||
      data.diabetesType != null;

  pw.Widget _buildPatientInfo(GlucoseReportData data, pw.Font boldFont) {
    final items = <_KV>[
      _KV('Name', data.patientName ?? '—'),
      if (data.patientAge != null) _KV('Age', '${data.patientAge} yrs'),
      if (data.patientWeight != null)
        _KV('Weight', '${data.patientWeight!.toStringAsFixed(1)} kg'),
      if (data.patientHeight != null)
        _KV('Height', '${data.patientHeight!.toStringAsFixed(0)} cm'),
      if (data.diabetesType != null) _KV('Diabetes Type', data.diabetesType!),
    ];

    final rows = <pw.Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final a = items[i];
      final b = (i + 1 < items.length) ? items[i + 1] : null;
      rows.add(
        pw.Row(
          children: [
            pw.Expanded(child: _infoCell(a, boldFont)),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: b != null ? _infoCell(b, boldFont) : pw.SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < items.length) rows.add(pw.SizedBox(height: 6));
    }

    return pw.Column(children: rows);
  }

  pw.Widget _infoCell(_KV kv, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _grey50,
        border: pw.Border.all(color: _grey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            kv.key,
            style: const pw.TextStyle(fontSize: 8, color: _grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            kv.value,
            style: pw.TextStyle(font: boldFont, fontSize: 10, color: _grey900),
          ),
        ],
      ),
    );
  }

  // ── Period row ─────────────────────────────────────────────────────────────

  pw.Widget _buildPeriodRow(
    GlucoseReportData data,
    DateFormat dateFmt,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _grey50,
        border: pw.Border.all(color: _grey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _periodCell('Period', data.rangeLabel, boldFont),
          _periodCell('From', dateFmt.format(data.rangeStart), boldFont),
          _periodCell('To', dateFmt.format(data.rangeEnd), boldFont),
          _periodCell('Readings', '${data.stats.totalReadings}', boldFont),
        ],
      ),
    );
  }

  pw.Widget _periodCell(String label, String value, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grey600)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(font: boldFont, fontSize: 10, color: _grey900),
        ),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  pw.Widget _buildStatsRow(GlucoseReportStats stats, pw.Font boldFont) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _statCard(
            'Average',
            '${stats.averageGlucose.toStringAsFixed(1)} mg/dL',
            _teal,
            boldFont,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _statCard(
            'Highest',
            '${stats.highestGlucose.toStringAsFixed(0)} mg/dL',
            _red,
            boldFont,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _statCard(
            'Lowest',
            '${stats.lowestGlucose.toStringAsFixed(0)} mg/dL',
            _blue,
            boldFont,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _statCard(
            'Total',
            '${stats.totalReadings}',
            PdfColors.grey700,
            boldFont,
          ),
        ),
      ],
    );
  }

  pw.Widget _statCard(
    String label,
    String value,
    PdfColor accent,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _grey50,
        border: pw.Border(bottom: pw.BorderSide(color: accent, width: 3)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: _grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 10, color: accent),
          ),
        ],
      ),
    );
  }

  // ── Status breakdown ───────────────────────────────────────────────────────

  pw.Widget _buildStatusBreakdown(GlucoseReportStats stats, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _grey50,
        border: pw.Border.all(color: _grey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _breakdownItem('Low', stats.lowCount, _blue, boldFont),
          _breakdownItem('Normal', stats.normalCount, _green, boldFont),
          _breakdownItem('High', stats.highCount, _orange, boldFont),
          _breakdownItem('Very High', stats.veryHighCount, _veryRed, boldFont),
        ],
      ),
    );
  }

  pw.Widget _breakdownItem(
    String label,
    int count,
    PdfColor color,
    pw.Font boldFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          '$count',
          style: pw.TextStyle(font: boldFont, fontSize: 18, color: color),
        ),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _grey600)),
      ],
    );
  }

  // ── Trend summary ──────────────────────────────────────────────────────────

  pw.Widget _buildTrendBox(String summary, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _tealLight,
        border: pw.Border.all(color: _teal),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        summary,
        style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
      ),
    );
  }

  // ── Readings table ─────────────────────────────────────────────────────────

  pw.Widget _buildTable(
    List<GlucoseReading> readings,
    DateFormat dateFmt,
    DateFormat timeFmt,
    pw.Font boldFont,
  ) {
    const headers = [
      'Date',
      'Time',
      'Meal Time',
      'Glucose\n(mg/dL)',
      'Status',
      'Notes',
    ];

    final rows = readings.map((r) {
      final notes = r.notes.isEmpty
          ? '–'
          : (r.notes.length > 42 ? '${r.notes.substring(0, 40)}…' : r.notes);
      return [
        dateFmt.format(r.date),
        timeFmt.format(r.date),
        r.mealTime.isEmpty ? '–' : r.mealTime,
        r.glucoseLevel.toStringAsFixed(0),
        r.getStatus(),
        notes,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(0.9),
        5: const pw.FlexColumnWidth(1.7),
      },
      headerDecoration: const pw.BoxDecoration(color: _teal),
      headerStyle: pw.TextStyle(
        font: boldFont,
        fontSize: 8,
        color: PdfColors.white,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerLeft,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _grey50),
      cellHeight: 20,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  pw.Widget _emptyNote(String message) {
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 16),
        child: pw.Text(
          message,
          style: const pw.TextStyle(fontSize: 10, color: _grey600),
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$_appName – Confidential Patient Report',
            style: const pw.TextStyle(fontSize: 7, color: _grey600),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _grey600),
          ),
        ],
      ),
    );
  }
}

class _KV {
  const _KV(this.key, this.value);
  final String key;
  final String value;
}
