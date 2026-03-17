import 'package:dia_plus/features/patient/history/models/history_date_range.dart';
import 'package:dia_plus/features/patient/screens/pdf_preview_page.dart';
import 'package:dia_plus/features/patient/widgets/export_report_button.dart';
import 'package:dia_plus/features/patient/widgets/report_range_selector.dart';
import 'package:dia_plus/features/patient/widgets/report_summary_card.dart';
import 'package:dia_plus/models/glucose_report_data.dart';
import 'package:dia_plus/services/pdf_report_service.dart';
import 'package:dia_plus/services/report_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Screen for configuring and generating a glucose PDF report.
///
/// Lets the patient pick a date range, previews a summary of the data,
/// and exports the generated PDF to [PdfPreviewPage].
class ExportReportPage extends StatefulWidget {
  const ExportReportPage({super.key});

  @override
  State<ExportReportPage> createState() => _ExportReportPageState();
}

class _ExportReportPageState extends State<ExportReportPage> {
  final _reportService = ReportService();
  final _pdfService = PdfReportService();

  HistoryDateRange _selectedRange = HistoryDateRange.last7Days();
  bool _loadingPreview = false;
  bool _generating = false;
  GlucoseReportData? _previewData;
  String? _errorMessage;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadPreviewData() async {
    final uid = _userId;
    if (uid == null) {
      setState(() => _errorMessage = 'Please log in to generate a report.');
      return;
    }

    setState(() {
      _loadingPreview = true;
      _errorMessage = null;
    });

    try {
      final data = await _reportService.buildReportData(uid, _selectedRange);
      if (mounted) {
        setState(() {
          _previewData = data;
          _loadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load report data. Please try again.';
          _loadingPreview = false;
        });
      }
    }
  }

  // ── Range selection ─────────────────────────────────────────────────────────

  Future<void> _onRangeSelected(HistoryDateRange range) async {
    _selectedRange = range;
    await _loadPreviewData();
  }

  Future<void> _onCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange.toDateTimeRange(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      await _onRangeSelected(HistoryDateRange.custom(picked));
    }
  }

  // ── PDF generation ─────────────────────────────────────────────────────────

  Future<void> _generateAndPreview() async {
    final data = _previewData;
    if (data == null) return;

    if (!data.stats.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No readings in the selected range. Please choose a different period.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _generating = true);

    try {
      final pdfBytes = await _pdfService.generateReportPdf(data);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(pdfBytes: pdfBytes, reportData: data),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Export Report'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey[800],
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 24),
              ReportRangeSelector(
                selectedRange: _selectedRange,
                onRangeSelected: _onRangeSelected,
                onCustomRangePressed: _onCustomRange,
              ),
              const SizedBox(height: 24),
              _buildPreviewSection(),
              const SizedBox(height: 32),
              ExportReportButton(
                onTap: _generating ? null : _generateAndPreview,
                isLoading: _generating,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.picture_as_pdf,
            color: Colors.teal.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glucose Report',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Generate & export your health data',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    if (_loadingPreview) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorCard();
    }

    final data = _previewData;
    if (data == null) return const SizedBox.shrink();

    return ReportSummaryCard(reportData: data);
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          TextButton(onPressed: _loadPreviewData, child: const Text('Retry')),
        ],
      ),
    );
  }
}
