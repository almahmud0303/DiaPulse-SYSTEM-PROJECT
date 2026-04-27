import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/mlkit_ocr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PatientOcrPage extends StatefulWidget {
  const PatientOcrPage({super.key});

  @override
  State<PatientOcrPage> createState() => _PatientOcrPageState();
}

class _PatientOcrPageState extends State<PatientOcrPage> {
  final ImagePicker _picker = ImagePicker();
  final MlKitOcrService _ocrService = MlKitOcrService();

  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  String? _selectedImageName;
  String _resultText = '';
  List<PrescriptionOcrMedicine> _prescriptionMedicines = const [];
  bool _extracting = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 95,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = picked.path;
        _selectedImageName = picked.name;
        _resultText = '';
        _prescriptionMedicines = const [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _runOcr() async {
    final imagePath = _selectedImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an image first.')));
      return;
    }

    setState(() => _extracting = true);
    try {
      final result = await _ocrService.extractPrescriptionFromFilePath(
        imagePath,
      );
      if (!mounted) return;
      setState(() {
        _resultText = result.rawText;
        _prescriptionMedicines = result.medicines;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _copyResult() async {
    final text = _formattedResultText();
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription scan copied to clipboard.')),
    );
  }

  String _formattedResultText() {
    return PrescriptionOcrResult(
      rawText: _resultText,
      medicines: _prescriptionMedicines,
    ).formattedText;
  }

  Future<void> _generatePdf() async {
    final hasText = _resultText.trim().isNotEmpty;
    final imageBytes = _selectedImageBytes;

    if (!hasText && imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No OCR content available to export.')),
      );
      return;
    }

    try {
      final doc = pw.Document();
      final capturedAt = DateTime.now();

      final imageProvider = imageBytes != null
          ? pw.MemoryImage(imageBytes)
          : null;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'Prescription OCR Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Generated: ${capturedAt.toLocal()}'),
            if (_selectedImageName != null) ...[
              pw.SizedBox(height: 2),
              pw.Text('Source image: ${_selectedImageName!}'),
            ],
            pw.SizedBox(height: 16),
            if (imageProvider != null) ...[
              pw.Text(
                'Captured Image',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 220,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(imageProvider, fit: pw.BoxFit.cover),
                ),
              ),
              pw.SizedBox(height: 16),
            ],
            if (_prescriptionMedicines.isNotEmpty) ...[
              pw.Text(
                'Extracted Prescription Details',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: const ['Medicine', 'Dosage', 'Timing'],
                data: _prescriptionMedicines
                    .map(
                      (m) => [
                        m.name.isEmpty ? '-' : m.name,
                        m.dosage.isEmpty ? '-' : m.dosage,
                        m.timing.isEmpty ? '-' : m.timing,
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),
            ],
            pw.Text(
              'Raw OCR Text',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                hasText ? _resultText : 'No text was extracted.',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name:
            'prescription_ocr_report_${capturedAt.millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF generation failed: $e')));
    }
  }

  @override
  void dispose() {
    _ocrService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(title: const Text('Prescription Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSelectorCard(),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _extracting ? null : _runOcr,
              icon: _extracting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner),
              label: Text(_extracting ? 'Extracting...' : 'Scan Prescription'),
            ),
            const SizedBox(height: 14),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Image',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (_selectedImageBytes == null)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAltColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('No image selected')),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _selectedImageBytes!,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 10),
            if (_selectedImageName != null)
              Text(
                _selectedImageName!,
                style: TextStyle(color: AppTheme.textSecondaryColor(context)),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _extracting
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _extracting
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final hasText = _resultText.trim().isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Prescription Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Generate PDF',
                  onPressed: hasText || _selectedImageBytes != null
                      ? _generatePdf
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
                IconButton(
                  tooltip: 'Copy scan result',
                  onPressed: hasText ? _copyResult : null,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_prescriptionMedicines.isNotEmpty) ...[
              _buildPrescriptionMedicineList(),
              const SizedBox(height: 12),
            ] else if (hasText) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAltColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No medicine rows were detected. Check the raw OCR text below.',
                  style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAltColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                hasText
                    ? _resultText
                    : 'Medicine names, dosage, and timing will appear here.',
                style: TextStyle(color: AppTheme.textPrimaryColor(context)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Review OCR results before following or saving any prescription instructions.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionMedicineList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _prescriptionMedicines.length; i++) ...[
          _buildMedicineResultTile(_prescriptionMedicines[i], i + 1),
          if (i != _prescriptionMedicines.length - 1)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildMedicineResultTile(PrescriptionOcrMedicine medicine, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAltColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  medicine.name.isEmpty
                      ? 'Medicine name not detected'
                      : medicine.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _medicineFieldRow(
            icon: Icons.medication_liquid_outlined,
            label: 'Dosage',
            value: medicine.dosage,
          ),
          const SizedBox(height: 8),
          _medicineFieldRow(
            icon: Icons.schedule_outlined,
            label: 'Timing',
            value: medicine.timing,
          ),
        ],
      ),
    );
  }

  Widget _medicineFieldRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final displayValue = value.trim().isEmpty ? 'Not detected' : value.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondaryColor(context)),
        const SizedBox(width: 8),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(color: AppTheme.textPrimaryColor(context)),
          ),
        ),
      ],
    );
  }
}
