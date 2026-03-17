import 'dart:typed_data';

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
    final safeName = reportData.patientName.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '_',
    );
    final date = DateFormat('yyyyMMdd').format(reportData.generatedAt);
    return 'DiaPulse_Report_${safeName}_$date.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Report Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey[800],
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () => _sharePdf(),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print PDF',
            onPressed: () => _printPdf(),
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
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf() async {
    await Printing.sharePdf(bytes: pdfBytes, filename: _fileName);
  }

  Future<void> _printPdf() async {
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: _fileName);
  }
}
