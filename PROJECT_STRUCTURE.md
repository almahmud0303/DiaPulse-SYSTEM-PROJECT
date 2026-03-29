# Dia Plus – Project Structure

## Overview

Flutter diabetes app with **3 roles** (Patient, Doctor, Admin). Doctor/Admin request professional access (admin approves), then set a second password. Patients track glucose, medicines, meals, activities, reminders, and health scores; doctors manage **My Patients** (from accepted appointments), prescriptions (grouped), consultation notes, appointments, and alerts. Admins manage users, monitoring, audit logs, backups, and announcements. UI is responsive (phone/tablet/web) via `lib/ui/responsive.dart`.

## Folder Structure

```
dia_plus/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   ├── core/
│   │   ├── navigation/
│   │   │   └── app_router.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── theme_notifier.dart
│   │   └── utils/
│   │       └── page_transitions.dart
│   │
│   ├── ui/
│   │   └── responsive.dart              # ResponsiveCenter, breakpoints, page padding
│   │
│   ├── models/
│   │   ├── user_role.dart
│   │   ├── app_user.dart
│   │   ├── audit_log_entry.dart
│   │   ├── announcement.dart
│   │   ├── glucose_reading.dart
│   │   ├── glucose_report_data.dart
│   │   ├── glucose_report_stats.dart
│   │   ├── health_score.dart
│   │   ├── health_score_breakdown.dart
│   │   ├── meal.dart
│   │   ├── medicine.dart
│   │   ├── medicine_entry.dart
│   │   ├── prescription.dart
│   │   ├── activity.dart
│   │   ├── reminder.dart
│   │   ├── reminder_repeat_mode.dart
│   │   ├── reminder_settings.dart
│   │   ├── reminder_type.dart
│   │   ├── consultation_note.dart
│   │   ├── patient_risk.dart
│   │   ├── appointment.dart
│   │   ├── conversation.dart
│   │   ├── chat_message.dart
│   │   ├── doctor_alert.dart
│   │   ├── app_notification.dart
│   │   ├── invite_access_request.dart
│   │   ├── emergency_alert.dart
│   │   ├── emergency_alert_type.dart
│   │   ├── emergency_settings.dart
│   │   └── (other domain models)
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── role_service.dart
│   │   ├── invite_access_request_service.dart
│   │   ├── audit_log_service.dart
│   │   ├── admin_user_service.dart
│   │   ├── admin_backup_service.dart
│   │   ├── admin_restore_service.dart
│   │   ├── backup_file_saver.dart          # Conditional import wrapper (web/io)
│   │   ├── backup_file_saver_io.dart       # Desktop: write JSON file
│   │   ├── backup_file_saver_web.dart      # Web: trigger browser download
│   │   ├── admin_announcement_service.dart
│   │   ├── announcement_service.dart       # Client announcements + read receipts
│   │   ├── glucose_reading_service.dart
│   │   ├── medicine_service.dart
│   │   ├── meal_service.dart
│   │   ├── activity_service.dart
│   │   ├── profile_service.dart
│   │   ├── health_score_service.dart
│   │   ├── doctor_patient_service.dart
│   │   ├── consultation_note_service.dart
│   │   ├── appointment_service.dart
│   │   ├── reminder_service.dart
│   │   ├── reminder_storage_service.dart
│   │   ├── reminder_notification_service.dart
│   │   ├── report_service.dart
│   │   ├── pdf_report_service.dart
│   │   ├── messaging_service.dart
│   │   ├── notification_service.dart
│   │   ├── doctor_alert_service.dart
│   │   ├── emergency_alert_service.dart
│   │   ├── emergency_notification_service.dart
│   │   └── emergency_settings_service.dart
│   │
│   └── features/
│       ├── auth/screens/
│       │   ├── starting_page.dart
│       │   ├── login_page.dart
│       │   ├── registration_page.dart
│       │   ├── email_verification_page.dart
│       │   └── second_password_page.dart
│       │
│       ├── home/screens/
│       │   └── main_navigation_page.dart
│       │
│       ├── patient/
│       │   ├── screens/
│       │   │   ├── patient_home_page.dart
│       │   │   ├── add_reading_page.dart
│       │   │   ├── edit_reading_page.dart
│       │   │   ├── readings_page.dart
│       │   │   ├── history_page.dart
│       │   │   ├── log_meal_page.dart
│       │   │   ├── log_activity_page.dart
│       │   │   ├── take_medicine_page.dart
│       │   │   ├── add_edit_medicine_page.dart
│       │   │   ├── medicine_list_page.dart
│       │   │   ├── medicine_history_page.dart
│       │   │   ├── add_edit_reminder_page.dart
│       │   │   ├── reminders_page.dart
│       │   │   ├── profile_page.dart
│       │   │   ├── health_score_details_page.dart
│       │   │   ├── export_report_page.dart
│       │   │   ├── pdf_preview_page.dart
│       │   │   ├── patient_appointments_page.dart
│       │   │   └── emergency_alert_details_page.dart
│       │   ├── widgets/
│       │   │   ├── health_score_card.dart
│       │   │   ├── next_reminder_widget.dart
│       │   │   ├── reminder_card.dart
│       │   │   ├── reminder_empty_state.dart
│       │   │   ├── repeat_selector.dart
│       │   │   ├── weekday_selector.dart
│       │   │   ├── diabetes_control_dialog.dart
│       │   │   ├── export_report_button.dart
│       │   │   ├── report_range_selector.dart
│       │   │   ├── report_summary_card.dart
│       │   │   ├── emergency_action_card.dart
│       │   │   ├── emergency_alert_banner.dart
│       │   │   └── emergency_status_chip.dart
│       │   └── history/
│       │       ├── data/repositories/
│       │       │   └── history_reports_repository.dart
│       │       ├── models/
│       │       │   ├── history_date_range.dart
│       │       │   ├── history_statistics.dart
│       │       │   ├── glucose_trend_point.dart
│       │       │   └── glucose_trend_period.dart
│       │       └── presentation/
│       │           ├── screens/
│       │           │   └── history_page.dart
│       │           ├── viewmodels/
│       │           │   └── history_reports_viewmodel.dart
│       │           └── widgets/
│       │               ├── history_header.dart
│       │               ├── history_date_filter_bar.dart
│       │               ├── history_period_selector.dart
│       │               ├── history_stats_section.dart
│       │               ├── history_loading_state.dart
│       │               ├── history_empty_state.dart
│       │               ├── glucose_trend_chart.dart
│       │               ├── glucose_reading_history_tile.dart
│       │               └── glucose_readings_history_list.dart
│       │
│       ├── doctor/screens/
│       │   ├── doctor_home_page.dart
│       │   ├── doctor_patients_page.dart
│       │   ├── doctor_appointments_page.dart
│       │   ├── doctor_patient_profile_page.dart
│       │   ├── doctor_prescription_detail_page.dart
│       │   ├── doctor_add_edit_prescription_page.dart
│       │   ├── doctor_add_edit_consultation_note_page.dart
│       │   ├── doctor_monitoring_dashboard_page.dart
│       │   └── doctor_alerts_page.dart
│       │
│       ├── admin/screens/
│       │   ├── admin_home_page.dart
│       │   ├── admin_user_management_page.dart
│       │   ├── admin_system_monitoring_page.dart
│       │   ├── admin_audit_logs_page.dart
│       │   ├── admin_backup_export_page.dart
│       │   ├── admin_backup_restore_page.dart
│       │   ├── admin_announcement_management_page.dart
│       │   └── admin_invite_access_requests_page.dart
│       │
│       └── shared/screens/
│           ├── settings_page.dart
│           ├── reminder_settings_page.dart
│           ├── doctor_consultation_page.dart
│           ├── diabetes_essentials_page.dart
│           ├── conversation_list_page.dart
│           ├── chat_page.dart
│           ├── select_conversation_partner_page.dart
│           ├── emergency_settings_page.dart
│           ├── notifications_page.dart     # Notifications + Announcements tabs
│           └── announcements_page.dart
│
├── android/                  # Android app (Gradle, manifest, build)
├── ios/                      # iOS app
├── functions/                # Firebase Cloud Functions (scheduled retention, etc.)
├── firestore.rules
├── firestore.indexes.json
├── firebase.json
├── pubspec.yaml
├── README.md
└── PROJECT_STRUCTURE.md      # This file
```

## Layer Summary

| Layer       | Purpose |
|------------|---------|
| **core/**  | App-wide navigation, theme, and utilities. |
| **ui/**    | Shared UI helpers (e.g. `Responsive`, `ResponsiveCenter` for breakpoints and padding). |
| **models/**| Domain/data models (user, glucose, medicine, prescription, appointment, reminder, emergency, etc.). |
| **services/** | Firebase and local business logic (auth, CRUD, reminders, reports, PDF, appointments, prescriptions, alerts, emergency, messaging). |
| **features/** | Role-based UI: auth, home (tabs), patient (screens + widgets + history), doctor, admin, shared. |

## Doctor Feature Notes

- **My Patients**: [DoctorPatientsPage](lib/features/doctor/screens/doctor_patients_page.dart) lists patients with **accepted** appointments only (`DoctorPatientService.getMyPatientsForDoctor`). Optional `selectedPatientId` opens that patient’s profile. Tapping a patient opens [DoctorPatientProfilePage](lib/features/doctor/screens/doctor_patient_profile_page.dart).
- **Appointments**: [DoctorAppointmentsPage](lib/features/doctor/screens/doctor_appointments_page.dart) shows pending/accepted/rejected requests; “View in My Patients” opens [DoctorPatientsPage](lib/features/doctor/screens/doctor_patients_page.dart) with that patient selected.
- **Patient profile (doctor view)**: Name, contact, basic info; risk status (last 7 days glucose); health history; glucose trends; **prescriptions** (grouped by prescription, expand/collapse); consultation notes. Add prescription via FAB; per-prescription “View prescription” opens [DoctorPrescriptionDetailPage](lib/features/doctor/screens/doctor_prescription_detail_page.dart).
- **Prescriptions**: Grouped in Firestore (`prescriptions/{id}` + `medicines` with `prescriptionId`). [DoctorAddEditPrescriptionPage](lib/features/doctor/screens/doctor_add_edit_prescription_page.dart) supports multi-dose, meal-relative times (“after lunch”, etc.), add multiple medicines, delete medicine or full prescription. [DoctorPrescriptionDetailPage](lib/features/doctor/screens/doctor_prescription_detail_page.dart) for view/PDF/add medicine/delete prescription.
- **Consultation notes**: [DoctorAddEditConsultationNotePage](lib/features/doctor/screens/doctor_add_edit_consultation_note_page.dart); [ConsultationNoteService](lib/services/consultation_note_service.dart); Firestore `consultation_notes`.
- **Risk & monitoring**: [PatientRisk](lib/models/patient_risk.dart), [DoctorPatientService](lib/services/doctor_patient_service.dart). [DoctorMonitoringDashboardPage](lib/features/doctor/screens/doctor_monitoring_dashboard_page.dart), [DoctorAlertsPage](lib/features/doctor/screens/doctor_alerts_page.dart), [DoctorAlertService](lib/services/doctor_alert_service.dart).
- **Messaging**: [ConversationListPage](lib/features/shared/screens/conversation_list_page.dart), [ChatPage](lib/features/shared/screens/chat_page.dart), [MessagingService](lib/services/messaging_service.dart).

## Patient Feature Notes

- **Dashboard**: [PatientHomePage](lib/features/patient/screens/patient_home_page.dart) with responsive layout; quick actions, glucose card, reminders, health score.
- **My Medicines**: [MedicineListPage](lib/features/patient/screens/medicine_list_page.dart) shows medicines grouped by prescription (from `prescriptionId`); expand/collapse; Take/Missed; Edit/Delete via menu.
- **Appointments**: [DoctorConsultationPage](lib/features/shared/screens/doctor_consultation_page.dart) to request; [PatientAppointmentsPage](lib/features/patient/screens/patient_appointments_page.dart) to list.
- **History**: `features/patient/history/` – data (repository), models, presentation (screen, viewmodel, widgets). Reports & PDF: report_service, pdf_report_service, export_report_page, pdf_preview_page.
- **Reminders**: reminder_service, reminder_storage_service, reminder_notification_service; reminders_page, add_edit_reminder_page; reminder_settings_page (shared).
- **Emergency**: emergency_alert_service, emergency_settings_service; emergency_alert_details_page, emergency_settings_page (shared); emergency_* widgets.

## Auth Flow

Start → Login/Register → (Email verify) → (Second password for Doctor/Admin) → Home.

- **AppRouter** (`core/navigation`): pushLogin, pushRegister, goToHome, goToStart, etc.
- **Professional access**: Doctor/Admin submit a request; admin approves in-app; user completes second password setup.
- **Second password**: Required for Doctor/Admin after approval.

## Firestore Collections

| Collection           | Purpose / key fields |
|---------------------|-----------------------|
| `users/{uid}`       | Profile: email, displayName, role, phone, createdAt, secondPasswordHash? |
| `users/{uid}/announcement_reads/{announcementId}` | Per-user announcement read receipts: readAt |
| `users/{uid}/access_requests/{id}` | Doctor/Admin access requests: status, email, role, createdAt |
| `glucose_readings`  | userId, value, type, date, time, notes, createdAt |
| `medicines`         | userId, name, dosage, time, times?, frequency, prescriptionId?, createdAt |
| `prescriptions/{id}`| patientId, createdAt (group for medicines) |
| `medicine_entries`  | userId, medicineId, medicineName, date, taken, takenAt?, createdAt |
| `consultation_notes`| patientId, doctorId, note, diagnosis, createdAt, updatedAt? |
| `appointments`      | patientId, doctorId, status (pending/accepted/rejected), createdAt, etc. |
| `meals`             | userId, date, category, carbs, notes, createdAt |
| `activities`        | userId, date, type, durationMinutes, calories, notes, createdAt |
| `conversations`     | participants, lastMessageAt |
| `messages`          | conversationId, senderId, receiverId, text, createdAt |
| `notifications`     | In-app notifications (messages/appointments), read flag, createdAt |
| `announcements`     | Admin broadcast announcements/campaigns (published, targetRole, timestamps) |
| `audit_logs`        | Append-only audit trail (admin/auth events; retention purged by function) |
| (others)            | doctor_alert, emergency, etc. as implemented |

Reminders/settings may use local storage or Firestore via reminder_storage_service.

## Run

```bash
flutter devices
flutter run -d android   # or chrome, windows
```

See **README.md** for setup (Firebase, Firestore rules, first admin).
