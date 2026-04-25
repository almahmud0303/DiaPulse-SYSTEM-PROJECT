// ignore_for_file: use_build_context_synchronously

import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/appointment_service.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_page.dart';

/// Patient-facing page: list doctors registered in the database.
/// Patients can message a doctor or book an appointment with them.
class DoctorConsultationPage extends StatefulWidget {
  const DoctorConsultationPage({super.key});

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  final AuthService _authService = AuthService();
  final DoctorPatientService _doctorService = DoctorPatientService();
  final AppointmentService _appointmentService = AppointmentService();

  List<AppUser> _doctors = [];
  AppUser? _currentUser;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.getAppUser();
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not signed in';
          _loading = false;
        });
        return;
      }
      final doctors = await _doctorService.getDoctors();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _doctors = doctors;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load doctors: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Doctor Consultation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _doctors.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            const Text(
                              'Registered doctors',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Message or book an appointment with a doctor from your care team.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._doctors.map((doctor) => _buildDoctorCard(doctor)),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor(context)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services_outlined,
                size: 64, color: AppTheme.textSecondaryColor(context)),
            const SizedBox(height: 16),
            Text(
              'No doctors registered yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Doctors will appear here once they are registered in the app.',
              style: TextStyle(color: AppTheme.textSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_services, color: Colors.white, size: 48),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expert Medical Advice',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Connect with doctors registered in your care team',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(AppUser doctor) {
    final name = doctor.displayName.isNotEmpty
        ? doctor.displayName
        : doctor.email;
    final color = Colors.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  doctor.initials,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.verified, color: color, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openDoctorProfile(doctor),
              icon: const Icon(Icons.person_outline),
              label: const Text('View profile'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(doctor),
                  icon: const Icon(Icons.chat, size: 20),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showBookingDialog(context, doctor),
                  icon: const Icon(Icons.calendar_today, size: 20),
                  label: const Text('Book appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDoctorProfile(AppUser doctor) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _DoctorProfilePage(doctor: doctor),
      ),
    );
  }

  void _openChat(AppUser doctor) {
    if (_currentUser == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChatPage(
          currentUser: _currentUser!,
          otherUser: doctor,
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, AppUser doctor) {
    final name = doctor.displayName.isNotEmpty
        ? doctor.displayName
        : doctor.email;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final noteController = TextEditingController();
    var selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    String? validationError;

    Future<void> pickDateTime(StateSetter setDialogState) async {
      final now = DateTime.now();
      final initialDate = selectedDateTime.isBefore(now) ? now : selectedDateTime;
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: now.add(const Duration(days: 120)),
      );
      if (pickedDate == null) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );
      if (pickedTime == null) return;
      setDialogState(() {
        selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        validationError = null;
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setDialogState) => AlertDialog(
          title: Text('Book appointment with $name'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your preferred consultation date and time. The doctor will accept or reject.',
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: const Text('Preferred consultation'),
                  subtitle: Text(
                    DateFormat('EEE, MMM d, y • HH:mm').format(selectedDateTime),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => pickDateTime(setDialogState),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Reason for consultation or preferred mode',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    validationError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDateTime.isBefore(DateTime.now())) {
                  setDialogState(() {
                    validationError = 'Please choose a future date and time.';
                  });
                  return;
                }
                if (_currentUser == null) return;
                try {
                  await _appointmentService.createRequest(
                    patientId: _currentUser!.uid,
                    doctorId: doctor.uid,
                    preferredConsultationAt: selectedDateTime,
                    patientName: _currentUser!.displayName.isNotEmpty
                        ? _currentUser!.displayName
                        : _currentUser!.email,
                    doctorName: name,
                    message: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appointment request sent to $name for ${DateFormat('MMM d, y • HH:mm').format(selectedDateTime)}.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text('Failed to send request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorProfilePage extends StatelessWidget {
  const _DoctorProfilePage({required this.doctor});

  final AppUser doctor;

  String _displayValue(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final name = doctor.displayName.isNotEmpty ? doctor.displayName : doctor.email;
    final speciality = _displayValue(doctor.extra['speciality'] ?? doctor.extra['specialty']);
    final clinic = _displayValue(doctor.extra['clinic'] ?? doctor.extra['department']);
    final joinedAt = doctor.createdAt == null
        ? 'Not available'
        : DateFormat('MMMM d, yyyy').format(doctor.createdAt!);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor(context),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.blue.withValues(alpha: 0.12),
                    child: Text(
                      doctor.initials,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Doctor',
                    style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Verified professional',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _infoCard(
              context: context,
              title: 'Contact',
              rows: [
                _InfoRow(label: 'Email', value: doctor.email),
                _InfoRow(label: 'Phone', value: _displayValue(doctor.phone)),
              ],
            ),
            const SizedBox(height: 14),
            _infoCard(
              context: context,
              title: 'Professional details',
              rows: [
                _InfoRow(label: 'Speciality', value: speciality),
                _InfoRow(label: 'Clinic/Department', value: clinic),
                _InfoRow(label: 'Joined', value: joinedAt),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required BuildContext context,
    required String title,
    required List<_InfoRow> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.label,
                      style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;
}
