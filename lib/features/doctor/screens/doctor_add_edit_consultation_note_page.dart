import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/consultation_note.dart';
import 'package:dia_plus/services/consultation_note_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Doctor: add or edit a consultation note and diagnosis for a patient.
class DoctorAddEditConsultationNotePage extends StatefulWidget {
  const DoctorAddEditConsultationNotePage({
    super.key,
    required this.patient,
    this.note,
  });

  final AppUser patient;
  final ConsultationNote? note;

  @override
  State<DoctorAddEditConsultationNotePage> createState() => _DoctorAddEditConsultationNotePageState();
}

class _DoctorAddEditConsultationNotePageState extends State<DoctorAddEditConsultationNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final ConsultationNoteService _service = ConsultationNoteService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    if (n != null) {
      _noteController.text = n.note;
      _diagnosisController.text = n.diagnosis;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.note;
      if (existing != null) {
        final updated = ConsultationNote(
          id: existing.id,
          patientId: existing.patientId,
          doctorId: existing.doctorId,
          note: _noteController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await _service.updateNote(updated);
      } else {
        final note = ConsultationNote(
          id: '${widget.patient.uid}_note_${DateTime.now().millisecondsSinceEpoch}',
          patientId: widget.patient.uid,
          doctorId: doctor.uid,
          note: _noteController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _service.addNote(note);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null ? 'Note updated' : 'Note saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;
    final df = DateFormat('MMM d, yyyy');
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit consultation note' : 'Add consultation note'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Patient: ${widget.patient.displayName.isEmpty ? "—" : widget.patient.displayName}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              if (widget.note != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Created ${df.format(widget.note!.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Consultation notes',
                  hintText: 'Visit notes, observations, follow-up...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter notes' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis',
                  hintText: 'Diagnosis or assessment...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter diagnosis' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
