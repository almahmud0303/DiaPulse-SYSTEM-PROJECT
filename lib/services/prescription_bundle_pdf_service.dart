import 'dart:typed_data';

import 'package:dia_plus/models/prescription_bundle.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrescriptionBundlePdfService {
  Future<Uint8List> generatePdf({
    required PrescriptionBundle bundle,
    required String patientName,
  }) async {
    final doc = pw.Document();
    final df = DateFormat('MMM d, yyyy');

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value)),
          ],
        ),
      );
    }

    final issuedBy = (bundle.issuedByName ?? '').trim().isNotEmpty
        ? bundle.issuedByName!.trim()
        : (bundle.issuedByUid ?? '').trim().isNotEmpty
            ? bundle.issuedByUid!.trim()
            : '—';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            'Prescription',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 14),
          row('Patient', patientName),
          row('Issued on', df.format(bundle.issuedAt)),
          row('Issued by', issuedBy),
          pw.Divider(height: 28),
          pw.Text(
            'Medicines',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...bundle.medicines.map((m) {
            final freq = m.frequency.replaceAll('_', ' ');
            final lines = <pw.Widget>[
              pw.Text(m.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('${m.dosage} • ${m.time} • $freq', style: const pw.TextStyle(color: PdfColors.grey700)),
            ];
            if (m.isInsulin && (m.insulinType ?? '').isNotEmpty) {
              lines.add(pw.Text('Insulin: ${m.insulinType}', style: const pw.TextStyle(color: PdfColors.grey700)));
            }
            if (m.adjustmentInstructions != null && m.adjustmentInstructions!.trim().isNotEmpty) {
              lines.add(pw.SizedBox(height: 4));
              lines.add(
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text('Instructions: ${m.adjustmentInstructions!.trim()}'),
                ),
              );
            }
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  ...lines,
                ],
              ),
            );
          }),
          pw.SizedBox(height: 20),
          pw.Text(
            'Note: This PDF is generated from the prescription saved in the app. Always follow your doctor’s advice.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }
}

