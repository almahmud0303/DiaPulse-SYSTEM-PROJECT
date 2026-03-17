import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/consultation_note.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/services/consultation_note_service.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'doctor_add_edit_consultation_note_page.dart';
import 'doctor_add_edit_prescription_page.dart';

/// Doctor view of a single patient: profile, health history, glucose trends, meds.
class DoctorPatientProfilePage extends StatefulWidget {
  const DoctorPatientProfilePage({super.key, required this.patient});

  final AppUser patient;

  @override
  State<DoctorPatientProfilePage> createState() => _DoctorPatientProfilePageState();
}

class _DoctorPatientProfilePageState extends State<DoctorPatientProfilePage> {
  final GlucoseReadingService _glucoseService = GlucoseReadingService();
  final MedicineService _medicineService = MedicineService();
  final ConsultationNoteService _consultationNoteService = ConsultationNoteService();

  List<GlucoseReading> _recentReadings = [];
  List<Medicine> _medicines = [];
  List<ConsultationNote> _consultationNotes = [];
  bool _loading = true;
  String? _error;

  AppUser get patient => widget.patient;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _glucoseService.getUserReadings(patient.uid),
        _medicineService.getMedicines(patient.uid),
        _consultationNoteService.getNotesForPatient(patient.uid),
      ]);
      if (!mounted) return;
      setState(() {
        _recentReadings = (results[0] as List<GlucoseReading>).take(15).toList();
        _medicines = results[1] as List<Medicine>;
        _consultationNotes = results[2] as List<ConsultationNote>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = patient.extra['age'];
    final weight = patient.extra['weight'];
    final height = patient.extra['height'];
    final diabetesType = patient.extra['diabetesType'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Patient Profile'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 16),
                        FilledButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileCard(context),
                        const SizedBox(height: 20),
                        _buildContactCard(context),
                        const SizedBox(height: 20),
                        _buildBasicInfoCard(context, age: age, weight: weight, height: height, diabetesType: diabetesType),
                        const SizedBox(height: 20),
                        _buildGlucoseTrendCard(context),
                        const SizedBox(height: 20),
                        _buildRecentGlucoseCard(context),
                        const SizedBox(height: 20),
                        _buildMedicinesCard(context),
                        const SizedBox(height: 20),
                        _buildConsultationNotesCard(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddPrescription,
              icon: const Icon(Icons.add),
              label: const Text('Add prescription'),
              backgroundColor: Colors.blue,
            ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Text(patient.initials, style: TextStyle(fontSize: 24, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.displayName.isEmpty ? 'No name' : patient.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Patient', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _contactRow(context, Icons.email_outlined, 'Email', patient.email),
          if (patient.phone != null && patient.phone!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _contactRow(context, Icons.phone_outlined, 'Phone', patient.phone!),
          ],
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              SelectableText(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, {dynamic age, dynamic weight, dynamic height, dynamic diabetesType}) {
    final hasAny = age != null || weight != null || height != null || diabetesType != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (!hasAny)
            Text('No additional info provided yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14))
          else ...[
            if (age != null) _infoRow(context, 'Age', _formatValue(age)),
            if (weight != null) _infoRow(context, 'Weight', '${_formatValue(weight)} kg'),
            if (height != null) _infoRow(context, 'Height', '${_formatValue(height)} cm'),
            if (diabetesType != null) _infoRow(context, 'Diabetes type', _formatValue(diabetesType)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatValue(dynamic v) {
    if (v is num) return v.toString();
    return v.toString();
  }

  Widget _buildGlucoseTrendCard(BuildContext context) {
    if (_recentReadings.isEmpty) {
      return _sectionCard(
        context,
        title: 'Glucose trend',
        icon: Icons.show_chart,
        child: Text('No readings yet.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekReadings = _recentReadings.where((r) => r.date.isAfter(weekAgo)).toList();
    if (weekReadings.isEmpty) {
      return _sectionCard(
        context,
        title: 'Glucose trend (last 7 days)',
        icon: Icons.show_chart,
        child: Text('No readings in the last 7 days.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    final levels = weekReadings.map((r) => r.glucoseLevel).toList();
    final avg = levels.reduce((a, b) => a + b) / levels.length;
    final min = levels.reduce((a, b) => a < b ? a : b);
    final max = levels.reduce((a, b) => a > b ? a : b);
    return _sectionCard(
      context,
      title: 'Glucose trend (last 7 days)',
      icon: Icons.show_chart,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _trendChip('Average', avg.toStringAsFixed(0), Colors.teal),
          _trendChip('Low', min.toStringAsFixed(0), Colors.blue),
          _trendChip('High', max.toStringAsFixed(0), Colors.orange),
          _trendChip('Readings', '${weekReadings.length}', Colors.grey),
        ],
      ),
    );
  }

  Widget _trendChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRecentGlucoseCard(BuildContext context) {
    return _sectionCard(
      context,
      title: 'Recent glucose',
      icon: Icons.history,
      child: _recentReadings.isEmpty
          ? Text('No readings yet.', style: TextStyle(color: Colors.grey.shade600))
          : Column(
              children: _recentReadings.take(8).map((r) => _readingTile(r)).toList(),
            ),
    );
  }

  Widget _readingTile(GlucoseReading r) {
    final statusColor = r.glucoseLevel < 70
        ? Colors.blue
        : r.glucoseLevel <= 140
            ? Colors.green
            : r.glucoseLevel <= 200
                ? Colors.orange
                : Colors.red;
    final df = DateFormat('MMM d, HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.glucoseLevel.toStringAsFixed(0)} mg/dL', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(df.format(r.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (r.mealTime.isNotEmpty)
            Text(r.mealTime, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildMedicinesCard(BuildContext context) {
    return _sectionCard(
      context,
      title: 'Prescriptions / Medicines',
      icon: Icons.medication,
      trailing: TextButton.icon(
        onPressed: _openAddPrescription,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add'),
      ),
      child: _medicines.isEmpty
          ? Text('No prescriptions yet. Tap Add to prescribe.', style: TextStyle(color: Colors.grey.shade600))
          : Column(
              children: _medicines.map((m) => _medicineTile(context, m)).toList(),
            ),
    );
  }

  Widget _medicineTile(BuildContext context, Medicine m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.medication_outlined, color: Colors.blue.shade700),
        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${m.dosage} · ${m.time} · ${m.frequency.replaceAll('_', ' ')}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openEditPrescription(m),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _openAddPrescription() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => DoctorAddEditPrescriptionPage(patient: patient)),
    );
    if (result == true && mounted) _loadData();
  }

  void _openEditPrescription(Medicine medicine) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => DoctorAddEditPrescriptionPage(patient: patient, medicine: medicine)),
    );
    if (result == true && mounted) _loadData();
  }

  Widget _buildConsultationNotesCard(BuildContext context) {
    return _sectionCard(
      context,
      title: 'Consultation notes & diagnosis',
      icon: Icons.note_alt_outlined,
      trailing: TextButton.icon(
        onPressed: _openAddConsultationNote,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add note'),
      ),
      child: _consultationNotes.isEmpty
          ? Text(
              'No notes yet. Tap Add note to record consultation notes and diagnosis.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Column(
              children: _consultationNotes.map((n) => _consultationNoteTile(context, n)).toList(),
            ),
    );
  }

  Widget _consultationNoteTile(BuildContext context, ConsultationNote n) {
    final df = DateFormat('MMM d, yyyy');
    final hasDiagnosis = n.diagnosis.trim().isNotEmpty;
    final preview = n.note.trim().isEmpty ? (hasDiagnosis ? n.diagnosis : 'No content') : n.note.trim();
    final shortPreview = preview.length > 80 ? '${preview.substring(0, 80)}...' : preview;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.note_outlined, color: Colors.blue.shade700),
        title: Text(
          hasDiagnosis ? n.diagnosis.trim().split('\n').first : 'Consultation note',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(shortPreview, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(df.format(n.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openEditConsultationNote(n),
      ),
    );
  }

  void _openAddConsultationNote() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => DoctorAddEditConsultationNotePage(patient: patient)),
    );
    if (result == true && mounted) _loadData();
  }

  void _openEditConsultationNote(ConsultationNote note) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => DoctorAddEditConsultationNotePage(patient: patient, note: note)),
    );
    if (result == true && mounted) _loadData();
  }
}
