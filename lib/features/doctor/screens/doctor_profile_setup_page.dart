import 'dart:convert';
import 'dart:io';

import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/doctor_profile.dart';
import 'package:dia_plus/services/doctor_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Multi-step doctor profile setup / edit page.
/// Sections: Basic Info, Professional, Location & Availability,
/// Contact, Consultation, About & Services, Documents.
class DoctorProfileSetupPage extends StatefulWidget {
  const DoctorProfileSetupPage({super.key, this.isInitialSetup = false});

  /// When true, shows "Complete Profile" title and navigates home on save.
  final bool isInitialSetup;

  @override
  State<DoctorProfileSetupPage> createState() => _DoctorProfileSetupPageState();
}

class _DoctorProfileSetupPageState extends State<DoctorProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = DoctorProfileService();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  int _currentStep = 0;

  // Basic Information
  final _fullNameController = TextEditingController();
  String? _gender;
  DateTime? _dateOfBirth;
  final List<String> _languagesSpoken = [];
  final _languageController = TextEditingController();
  File? _profilePhoto;
  String? _existingPhotoUrl;

  // Professional Details
  String? _specialization;
  final List<String> _qualifications = [];
  final _qualificationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _clinicNameController = TextEditingController();

  // Location & Availability
  final _clinicAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final List<String> _availableDays = [];
  final List<TimeSlot> _timeSlots = [];
  bool _isOnlineConsultationAvailable = false;

  // Contact
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  // Consultation Details
  final _inPersonFeeController = TextEditingController();
  final _onlineFeeController = TextEditingController();
  final List<String> _paymentMethods = [];

  // About & Services
  final _bioController = TextEditingController();
  final List<String> _services = [];
  final _serviceController = TextEditingController();

  // Documents
  final List<String> _certificateUrls = [];
  File? _idProofFile;
  String? _existingIdProofUrl;

  // App Features
  bool _isAppointmentEnabled = true;
  bool _isChatEnabled = true;
  bool _isPrescriptionAccessEnabled = true;

  static const List<String> _specializations = [
    'Diabetologist',
    'Endocrinologist',
    'General Physician',
    'Internal Medicine',
    'Cardiologist',
    'Nephrologist',
    'Ophthalmologist',
    'Podiatrist',
    'Nutritionist',
    'Other',
  ];

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _paymentOptions = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Insurance',
    'Mobile Payment',
    'Bank Transfer',
  ];

  static ImageProvider _imageFromString(String url) {
    if (url.startsWith('data:')) {
      return MemoryImage(base64Decode(url.split(',').last));
    }
    return NetworkImage(url);
  }

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profile = await _service.getProfile(uid);
      if (profile != null && mounted) {
        _fullNameController.text = profile.fullName;
        _gender = profile.gender;
        _dateOfBirth = profile.dateOfBirth;
        _languagesSpoken.addAll(profile.languagesSpoken);
        _existingPhotoUrl = profile.profilePhotoUrl;

        _specialization = profile.specialization;
        _qualifications.addAll(profile.qualifications);
        _licenseController.text = profile.medicalLicenseNumber ?? '';
        _experienceController.text =
            profile.yearsOfExperience?.toString() ?? '';
        _clinicNameController.text = profile.clinicName ?? '';

        _clinicAddressController.text = profile.clinicAddress ?? '';
        _cityController.text = profile.city ?? '';
        _countryController.text = profile.country ?? '';
        _availableDays.addAll(profile.availableDays);
        _timeSlots.addAll(profile.timeSlots);
        _isOnlineConsultationAvailable = profile.isOnlineConsultationAvailable;

        _phoneController.text = profile.phoneNumber ?? '';
        _emergencyContactController.text = profile.emergencyContact ?? '';

        _inPersonFeeController.text =
            profile.inPersonFee?.toStringAsFixed(0) ?? '';
        _onlineFeeController.text =
            profile.onlineFee?.toStringAsFixed(0) ?? '';
        _paymentMethods.addAll(profile.paymentMethods);

        _bioController.text = profile.bio ?? '';
        _services.addAll(profile.services);

        _certificateUrls.addAll(profile.certificateUrls);
        _existingIdProofUrl = profile.idProofUrl;

        _isAppointmentEnabled = profile.isAppointmentEnabled;
        _isChatEnabled = profile.isChatEnabled;
        _isPrescriptionAccessEnabled = profile.isPrescriptionAccessEnabled;
      } else if (mounted) {
        // Pre-fill name and email from auth
        final user = FirebaseAuth.instance.currentUser;
        _fullNameController.text = user?.displayName ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _languageController.dispose();
    _qualificationController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _inPersonFeeController.dispose();
    _onlineFeeController.dispose();
    _bioController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 50,
    );
    if (picked != null && mounted) {
      setState(() => _profilePhoto = File(picked.path));
    }
  }

  Future<void> _pickIdProof() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 60,
    );
    if (picked != null && mounted) {
      setState(() => _idProofFile = File(picked.path));
    }
  }

  Future<void> _pickCertificate() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 60,
    );
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final dataUri = await _service.fileToBase64DataUri(File(picked.path));
      if (mounted) {
        setState(() {
          _certificateUrls.add(dataUri);
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _addTimeSlot() {
    setState(() => _timeSlots.add(const TimeSlot(startTime: '09:00', endTime: '17:00')));
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final slot = _timeSlots[index];
    final parts = (isStart ? slot.startTime : slot.endTime).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _timeSlots[index] = isStart
            ? slot.copyWith(startTime: formatted)
            : slot.copyWith(endTime: formatted);
      });
    }
  }

  int _firstInvalidStep() {
    if (_fullNameController.text.trim().isEmpty) return 0;
    if (_specialization == null || _specialization!.isEmpty) return 1;
    if (_licenseController.text.trim().isEmpty) return 1;
    return 6;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() => _currentStep = _firstInvalidStep());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields before saving.'),
          ),
        );
      }
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      // Encode profile photo as Base64 if changed
      String? photoUrl = _existingPhotoUrl;
      if (_profilePhoto != null) {
        photoUrl = await _service.fileToBase64DataUri(_profilePhoto!);
      }

      // Encode ID proof as Base64 if changed
      String? idProofUrl = _existingIdProofUrl;
      if (_idProofFile != null) {
        idProofUrl = await _service.fileToBase64DataUri(_idProofFile!);
      }

      final profile = DoctorProfile(
        uid: user.uid,
        fullName: _fullNameController.text.trim(),
        email: user.email ?? '',
        profilePhotoUrl: photoUrl,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        languagesSpoken: _languagesSpoken,
        specialization: _specialization,
        qualifications: _qualifications,
        medicalLicenseNumber: _licenseController.text.trim().isNotEmpty
            ? _licenseController.text.trim()
            : null,
        yearsOfExperience:
            int.tryParse(_experienceController.text.trim()),
        clinicName: _clinicNameController.text.trim().isNotEmpty
            ? _clinicNameController.text.trim()
            : null,
        clinicAddress: _clinicAddressController.text.trim().isNotEmpty
            ? _clinicAddressController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
        availableDays: _availableDays,
        timeSlots: _timeSlots,
        isOnlineConsultationAvailable: _isOnlineConsultationAvailable,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        emergencyContact: _emergencyContactController.text.trim().isNotEmpty
            ? _emergencyContactController.text.trim()
            : null,
        inPersonFee:
            double.tryParse(_inPersonFeeController.text.trim()),
        onlineFee: double.tryParse(_onlineFeeController.text.trim()),
        paymentMethods: _paymentMethods,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        services: _services,
        certificateUrls: _certificateUrls,
        idProofUrl: idProofUrl,
        verificationStatus: VerificationStatus.pending,
        isAppointmentEnabled: _isAppointmentEnabled,
        isChatEnabled: _isChatEnabled,
        isPrescriptionAccessEnabled: _isPrescriptionAccessEnabled,
        isProfileComplete: true,
      );

      await _service.saveProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.isInitialSetup) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pop(true);
        }
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup ? 'Complete Your Profile' : 'Edit Profile',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 6) {
              setState(() => _currentStep++);
            } else {
              _save();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            final isLast = _currentStep == 6;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: _saving ? null : details.onStepContinue,
                    child: _saving && isLast
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isLast ? 'Save Profile' : 'Continue'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            _buildBasicInfoStep(),
            _buildProfessionalStep(),
            _buildLocationStep(),
            _buildContactStep(),
            _buildConsultationStep(),
            _buildAboutServicesStep(),
            _buildDocumentsStep(),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Basic Information ───────────────────────────────────────

  Step _buildBasicInfoStep() {
    return Step(
      title: const Text('Basic Information'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickProfilePhoto,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryMint,
                backgroundImage: _profilePhoto != null
                    ? FileImage(_profilePhoto!)
                    : (_existingPhotoUrl != null
                    ? _imageFromString(_existingPhotoUrl!)
                    : null),
                child: _profilePhoto == null && _existingPhotoUrl == null
                    ? const Icon(Icons.camera_alt, size: 32, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Tap to add photo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            items: ['Male', 'Female', 'Other']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_dateOfBirth != null
                ? 'Date of Birth: ${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                : 'Date of Birth (optional)'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDateOfBirth,
          ),
          const SizedBox(height: 8),
          _buildChipListEditor(
            label: 'Languages Spoken',
            items: _languagesSpoken,
            controller: _languageController,
            hintText: 'e.g. English',
          ),
        ],
      ),
    );
  }

  // ── Step 2: Professional Details ────────────────────────────────────

  Step _buildProfessionalStep() {
    return Step(
      title: const Text('Professional Details'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _specialization,
            decoration: const InputDecoration(
              labelText: 'Specialization *',
              border: OutlineInputBorder(),
            ),
            items: _specializations
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _specialization = v),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildChipListEditor(
            label: 'Qualifications',
            items: _qualifications,
            controller: _qualificationController,
            hintText: 'e.g. MBBS, MD',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licenseController,
            decoration: const InputDecoration(
              labelText: 'Medical License Number *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _experienceController,
            decoration: const InputDecoration(
              labelText: 'Years of Experience',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clinicNameController,
            decoration: const InputDecoration(
              labelText: 'Clinic / Hospital Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Location & Availability ────────────────────────────────

  Step _buildLocationStep() {
    return Step(
      title: const Text('Location & Availability'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _clinicAddressController,
            decoration: const InputDecoration(
              labelText: 'Clinic Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _countryController,
            decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text('Available Days', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) {
              final selected = _availableDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _availableDays.add(day);
                    } else {
                      _availableDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Time Slots', style: TextStyle(fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: _addTimeSlot,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Slot'),
              ),
            ],
          ),
          ..._timeSlots.asMap().entries.map((entry) {
            final i = entry.key;
            final slot = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(i, true),
                      child: Text(slot.startTime),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to'),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(i, false),
                      child: Text(slot.endTime),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _timeSlots.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Online Consultation Available'),
            value: _isOnlineConsultationAvailable,
            onChanged: (v) =>
                setState(() => _isOnlineConsultationAvailable = v),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Contact Information ────────────────────────────────────

  Step _buildContactStep() {
    return Step(
      title: const Text('Contact Information'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: false,
            initialValue: FirebaseAuth.instance.currentUser?.email ?? '',
            decoration: const InputDecoration(
              labelText: 'Email (from account)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyContactController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.emergency),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // ── Step 5: Consultation Details ───────────────────────────────────

  Step _buildConsultationStep() {
    return Step(
      title: const Text('Consultation Details'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _inPersonFeeController,
            decoration: const InputDecoration(
              labelText: 'In-Person Fee',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _onlineFeeController,
            decoration: const InputDecoration(
              labelText: 'Online Consultation Fee',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentOptions.map((method) {
              final selected = _paymentMethods.contains(method);
              return FilterChip(
                label: Text(method),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _paymentMethods.add(method);
                    } else {
                      _paymentMethods.remove(method);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Appointments'),
            value: _isAppointmentEnabled,
            onChanged: (v) => setState(() => _isAppointmentEnabled = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Chat'),
            value: _isChatEnabled,
            onChanged: (v) => setState(() => _isChatEnabled = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Prescription Access'),
            value: _isPrescriptionAccessEnabled,
            onChanged: (v) =>
                setState(() => _isPrescriptionAccessEnabled = v),
          ),
        ],
      ),
    );
  }

  // ── Step 6: About & Services ───────────────────────────────────────

  Step _buildAboutServicesStep() {
    return Step(
      title: const Text('About & Services'),
      isActive: _currentStep >= 5,
      state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio (max 500 chars)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          _buildChipListEditor(
            label: 'Services Offered',
            items: _services,
            controller: _serviceController,
            hintText: 'e.g. Insulin Management',
          ),
        ],
      ),
    );
  }

  // ── Step 7: Documents & Verification ───────────────────────────────

  Step _buildDocumentsStep() {
    return Step(
      title: const Text('Documents & Verification'),
      isActive: _currentStep >= 6,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Certificates', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_certificateUrls.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _certificateUrls.asMap().entries.map((entry) {
                return Chip(
                  label: Text('Certificate ${entry.key + 1}'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () =>
                      setState(() => _certificateUrls.removeAt(entry.key)),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickCertificate,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Certificate'),
          ),
          const SizedBox(height: 20),
          const Text('ID Proof', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_idProofFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_idProofFile!, height: 120, fit: BoxFit.cover),
            )
          else if (_existingIdProofUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: _imageFromString(_existingIdProofUrl!),
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickIdProof,
            icon: const Icon(Icons.badge),
            label: Text(_existingIdProofUrl != null || _idProofFile != null
                ? 'Change ID Proof'
                : 'Upload ID Proof'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your profile will be reviewed by an admin before it becomes visible to patients.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared chip list editor ────────────────────────────────────────

  Widget _buildChipListEditor({
    required String label,
    required List<String> items,
    required TextEditingController controller,
    String hintText = 'Add item',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => items.removeAt(entry.key)),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onFieldSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      items.add(v.trim());
                      controller.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryMint),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    items.add(controller.text.trim());
                    controller.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
