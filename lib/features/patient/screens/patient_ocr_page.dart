import 'dart:typed_data';

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
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _runOcr() async {
    final imagePath = _selectedImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an image first.')),
      );
      return;
    }

    setState(() => _extracting = true);
    try {
      final text = await _ocrService.extractTextFromFilePath(imagePath);
      if (!mounted) return;
      setState(() => _resultText = text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _copyResult() async {
    if (_resultText.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _resultText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OCR text copied to clipboard.')),
    );
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

      final imageProvider = imageBytes != null ? pw.MemoryImage(imageBytes) : null;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'OCR Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
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
            pw.Text(
              'Extracted Text',
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
        name: 'ocr_report_${capturedAt.millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generation failed: $e')),
      );
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
      appBar: AppBar(title: const Text('OCR Scanner')),
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
              label: Text(_extracting ? 'Extracting...' : 'Run OCR with ML Kit'),
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
                child: const Center(
                  child: Text('No image selected'),
                ),
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
                    onPressed: _extracting ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _extracting ? null : () => _pickImage(ImageSource.gallery),
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
                  'OCR Result',
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
                  tooltip: 'Copy text',
                  onPressed: hasText ? _copyResult : null,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAltColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                hasText ? _resultText : 'Extracted text will appear here.',
                style: TextStyle(color: AppTheme.textPrimaryColor(context)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'On-device OCR is powered by Google ML Kit.',
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
}
