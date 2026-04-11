import 'package:cloud_firestore/cloud_firestore.dart';

/// A time slot representing availability (e.g. 09:00 – 17:00).
class TimeSlot {
  const TimeSlot({required this.startTime, required this.endTime});

  final String startTime; // HH:mm
  final String endTime; // HH:mm

  factory TimeSlot.fromMap(Map<String, dynamic> data) {
    return TimeSlot(
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'startTime': startTime, 'endTime': endTime};

  TimeSlot copyWith({String? startTime, String? endTime}) {
    return TimeSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// Verification status for a doctor profile.
enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  static VerificationStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }
}

/// Doctor profile stored at `users/{uid}/doctor_profile/profile`.
class DoctorProfile {
  const DoctorProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.profilePhotoUrl,
    this.gender,
    this.dateOfBirth,
    this.languagesSpoken = const [],
    this.specialization,
    this.qualifications = const [],
    this.medicalLicenseNumber,
    this.yearsOfExperience,
    this.clinicName,
    this.clinicAddress,
    this.city,
    this.country,
    this.availableDays = const [],
    this.timeSlots = const [],
    this.isOnlineConsultationAvailable = false,
    this.phoneNumber,
    this.emergencyContact,
    this.inPersonFee,
    this.onlineFee,
    this.paymentMethods = const [],
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalPatientsTreated = 0,
    this.bio,
    this.services = const [],
    this.certificateUrls = const [],
    this.idProofUrl,
    this.verificationStatus = VerificationStatus.pending,
    this.rejectionReason,
    this.isAppointmentEnabled = true,
    this.isChatEnabled = true,
    this.isPrescriptionAccessEnabled = true,
    this.isProfileComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  // Basic Information
  final String uid;
  final String fullName;
  final String email;
  final String? profilePhotoUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final List<String> languagesSpoken;

  // Professional Details
  final String? specialization;
  final List<String> qualifications;
  final String? medicalLicenseNumber;
  final int? yearsOfExperience;
  final String? clinicName;

  // Location & Availability
  final String? clinicAddress;
  final String? city;
  final String? country;
  final List<String> availableDays;
  final List<TimeSlot> timeSlots;
  final bool isOnlineConsultationAvailable;

  // Contact Information
  final String? phoneNumber;
  final String? emergencyContact;

  // Consultation Details
  final double? inPersonFee;
  final double? onlineFee;
  final List<String> paymentMethods;

  // Ratings & Reviews (computed, read-only from client perspective)
  final double averageRating;
  final int totalReviews;
  final int totalPatientsTreated;

  // About
  final String? bio;

  // Services Offered
  final List<String> services;

  // Documents & Verification
  final List<String> certificateUrls;
  final String? idProofUrl;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;

  // App Features
  final bool isAppointmentEnabled;
  final bool isChatEnabled;
  final bool isPrescriptionAccessEnabled;

  // Meta
  final bool isProfileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DoctorProfile.fromMap(String uid, Map<String, dynamic> data) {
    return DoctorProfile(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      gender: data['gender'] as String?,
      dateOfBirth: _parseDateTime(data['dateOfBirth']),
      languagesSpoken: _toStringList(data['languagesSpoken']),
      specialization: data['specialization'] as String?,
      qualifications: _toStringList(data['qualifications']),
      medicalLicenseNumber: data['medicalLicenseNumber'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int?,
      clinicName: data['clinicName'] as String?,
      clinicAddress: data['clinicAddress'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String?,
      availableDays: _toStringList(data['availableDays']),
      timeSlots: (data['timeSlots'] as List<dynamic>?)
              ?.map(
                (e) => TimeSlot.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
      isOnlineConsultationAvailable:
          data['isOnlineConsultationAvailable'] as bool? ?? false,
      phoneNumber: data['phoneNumber'] as String?,
      emergencyContact: data['emergencyContact'] as String?,
      inPersonFee: (data['inPersonFee'] as num?)?.toDouble(),
      onlineFee: (data['onlineFee'] as num?)?.toDouble(),
      paymentMethods: _toStringList(data['paymentMethods']),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      totalPatientsTreated: data['totalPatientsTreated'] as int? ?? 0,
      bio: data['bio'] as String?,
      services: _toStringList(data['services']),
      certificateUrls: _toStringList(data['certificateUrls']),
      idProofUrl: data['idProofUrl'] as String?,
      verificationStatus:
          VerificationStatus.fromString(data['verificationStatus'] as String?),
      rejectionReason: data['rejectionReason'] as String?,
      isAppointmentEnabled: data['isAppointmentEnabled'] as bool? ?? true,
      isChatEnabled: data['isChatEnabled'] as bool? ?? true,
      isPrescriptionAccessEnabled:
          data['isPrescriptionAccessEnabled'] as bool? ?? true,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null)
        'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      'languagesSpoken': languagesSpoken,
      if (specialization != null) 'specialization': specialization,
      'qualifications': qualifications,
      if (medicalLicenseNumber != null)
        'medicalLicenseNumber': medicalLicenseNumber,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (clinicName != null) 'clinicName': clinicName,
      if (clinicAddress != null) 'clinicAddress': clinicAddress,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      'availableDays': availableDays,
      'timeSlots': timeSlots.map((t) => t.toMap()).toList(),
      'isOnlineConsultationAvailable': isOnlineConsultationAvailable,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (inPersonFee != null) 'inPersonFee': inPersonFee,
      if (onlineFee != null) 'onlineFee': onlineFee,
      'paymentMethods': paymentMethods,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalPatientsTreated': totalPatientsTreated,
      if (bio != null) 'bio': bio,
      'services': services,
      'certificateUrls': certificateUrls,
      if (idProofUrl != null) 'idProofUrl': idProofUrl,
      'verificationStatus': verificationStatus.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'isAppointmentEnabled': isAppointmentEnabled,
      'isChatEnabled': isChatEnabled,
      'isPrescriptionAccessEnabled': isPrescriptionAccessEnabled,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DoctorProfile copyWith({
    String? fullName,
    String? email,
    String? profilePhotoUrl,
    String? gender,
    DateTime? dateOfBirth,
    List<String>? languagesSpoken,
    String? specialization,
    List<String>? qualifications,
    String? medicalLicenseNumber,
    int? yearsOfExperience,
    String? clinicName,
    String? clinicAddress,
    String? city,
    String? country,
    List<String>? availableDays,
    List<TimeSlot>? timeSlots,
    bool? isOnlineConsultationAvailable,
    String? phoneNumber,
    String? emergencyContact,
    double? inPersonFee,
    double? onlineFee,
    List<String>? paymentMethods,
    double? averageRating,
    int? totalReviews,
    int? totalPatientsTreated,
    String? bio,
    List<String>? services,
    List<String>? certificateUrls,
    String? idProofUrl,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    bool? isAppointmentEnabled,
    bool? isChatEnabled,
    bool? isPrescriptionAccessEnabled,
    bool? isProfileComplete,
  }) {
    return DoctorProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      specialization: specialization ?? this.specialization,
      qualifications: qualifications ?? this.qualifications,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      city: city ?? this.city,
      country: country ?? this.country,
      availableDays: availableDays ?? this.availableDays,
      timeSlots: timeSlots ?? this.timeSlots,
      isOnlineConsultationAvailable:
          isOnlineConsultationAvailable ?? this.isOnlineConsultationAvailable,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      inPersonFee: inPersonFee ?? this.inPersonFee,
      onlineFee: onlineFee ?? this.onlineFee,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalPatientsTreated: totalPatientsTreated ?? this.totalPatientsTreated,
      bio: bio ?? this.bio,
      services: services ?? this.services,
      certificateUrls: certificateUrls ?? this.certificateUrls,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isAppointmentEnabled: isAppointmentEnabled ?? this.isAppointmentEnabled,
      isChatEnabled: isChatEnabled ?? this.isChatEnabled,
      isPrescriptionAccessEnabled:
          isPrescriptionAccessEnabled ?? this.isPrescriptionAccessEnabled,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static List<String> _toStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
