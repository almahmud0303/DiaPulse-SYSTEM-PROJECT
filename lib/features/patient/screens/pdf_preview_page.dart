import 'dart:typed_data';

import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/glucose_report_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Full-screen PDF preview with built-in share and print actions.
///
/// Uses [PdfPreview] from the `printing` package which renders the PDF
/// natively and provides platform-appropriate share / print buttons.
class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.reportData,
  });

  final Uint8List pdfBytes;
  final GlucoseReportData reportData;

  String get _fileName {
    final safeName = (reportData.patientName ?? 'Report').replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '_',
    );
    final date = DateFormat('yyyyMMdd').format(reportData.generatedAt);
    return 'DiaPulse_Report_${safeName}_$date.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Report Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor(context),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () => _sharePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print PDF',
            onPressed: () => _printPdf(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: _fileName,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 52, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Could not render PDF preview.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: _fileName);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: _fileName);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to print PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
