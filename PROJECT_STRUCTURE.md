# Dia Plus – Project Structure

## Overview

Flutter diabetes app with **3 roles** (Patient, Doctor, Admin). Doctor/Admin require invite codes and a second password. Patients track glucose, medicines, meals, activities, reminders, and health scores; history uses a data/presentation split with reports and PDF export.

## Folder Structure

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/
│   ├── navigation/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_notifier.dart
│   └── utils/
│       └── page_transitions.dart
│
├── models/
│   ├── user_role.dart
│   ├── app_user.dart
│   ├── glucose_reading.dart
│   ├── glucose_report_data.dart
│   ├── glucose_report_stats.dart
│   ├── health_score.dart
│   ├── health_score_breakdown.dart
│   ├── meal.dart
│   ├── medicine.dart
│   ├── medicine_entry.dart
│   ├── activity.dart
│   ├── reminder.dart
│   ├── reminder_repeat_mode.dart
│   ├── reminder_settings.dart
│   ├── reminder_type.dart
│   ├── consultation_note.dart
│   └── patient_risk.dart
│
├── services/
│   ├── auth_service.dart
│   ├── role_service.dart
│   ├── invite_code_service.dart
│   ├── glucose_reading_service.dart
│   ├── medicine_service.dart
│   ├── meal_service.dart
│   ├── activity_service.dart
│   ├── profile_service.dart
│   ├── health_score_service.dart
│   ├── doctor_patient_service.dart
│   ├── consultation_note_service.dart
│   ├── reminder_service.dart
│   ├── reminder_storage_service.dart
│   ├── reminder_notification_service.dart
│   ├── report_service.dart
│   └── pdf_report_service.dart
│
└── features/
    ├── auth/screens/
    │   ├── starting_page.dart
    │   ├── login_page.dart
    │   ├── registration_page.dart
    │   ├── email_verification_page.dart
    │   └── second_password_page.dart
    │
    ├── home/screens/
    │   └── main_navigation_page.dart
    │
    ├── patient/
    │   ├── screens/
    │   │   ├── patient_home_page.dart
    │   │   ├── add_reading_page.dart
    │   │   ├── edit_reading_page.dart
    │   │   ├── readings_page.dart
    │   │   ├── history_page.dart
    │   │   ├── log_meal_page.dart
    │   │   ├── log_activity_page.dart
    │   │   ├── take_medicine_page.dart
    │   │   ├── add_edit_medicine_page.dart
    │   │   ├── medicine_list_page.dart
    │   │   ├── medicine_history_page.dart
    │   │   ├── add_edit_reminder_page.dart
    │   │   ├── reminders_page.dart
    │   │   ├── profile_page.dart
    │   │   ├── health_score_details_page.dart
    │   │   ├── export_report_page.dart
    │   │   └── pdf_preview_page.dart
    │   ├── widgets/
    │   │   ├── health_score_card.dart
    │   │   ├── next_reminder_widget.dart
    │   │   ├── reminder_card.dart
    │   │   ├── reminder_empty_state.dart
    │   │   ├── repeat_selector.dart
    │   │   ├── weekday_selector.dart
    │   │   ├── diabetes_control_dialog.dart
    │   │   ├── export_report_button.dart
    │   │   ├── report_range_selector.dart
    │   │   └── report_summary_card.dart
    │   └── history/
    │       ├── data/repositories/
    │       │   └── history_reports_repository.dart
    │       ├── models/
    │       │   ├── history_date_range.dart
    │       │   ├── history_statistics.dart
    │       │   ├── glucose_trend_point.dart
    │       │   └── glucose_trend_period.dart
    │       └── presentation/
    │           ├── screens/
    │           │   └── history_page.dart
    │           ├── viewmodels/
    │           │   └── history_reports_viewmodel.dart
    │           └── widgets/
    │               ├── history_header.dart
    │               ├── history_date_filter_bar.dart
    │               ├── history_period_selector.dart
    │               ├── history_stats_section.dart
    │               ├── history_loading_state.dart
    │               ├── history_empty_state.dart
    │               ├── glucose_trend_chart.dart
    │               ├── glucose_reading_history_tile.dart
    │               └── glucose_readings_history_list.dart
    │
    ├── doctor/screens/
    │   ├── doctor_home_page.dart
    │   ├── doctor_patients_page.dart
    │   ├── doctor_patient_profile_page.dart
    │   ├── doctor_add_edit_prescription_page.dart
    │   └── doctor_add_edit_consultation_note_page.dart
    │
    ├── admin/screens/
    │   ├── admin_home_page.dart
    │   └── invite_codes_page.dart
    │
    └── shared/screens/
        ├── settings_page.dart
        ├── reminder_settings_page.dart
        ├── doctor_consultation_page.dart
        └── diabetes_essentials_page.dart
```

## Layer Summary

| Layer     | Purpose |
|----------|---------|
| **core/** | App-wide navigation, theme, and utilities. |
| **models/** | Domain/data models (user, glucose, medicine, meal, activity, reminder, health score, reports). |
| **services/** | Firebase and local business logic (auth, CRUD, reminders, reports, PDF). |
| **features/** | Role-based UI: auth, home (tabs), patient (screens + widgets + history feature), doctor, admin, shared. |

## Doctor Feature Notes

- **My Patients**: [DoctorPatientsPage](lib/features/doctor/screens/doctor_patients_page.dart) lists all patients (from Firestore `users` where `role == patient`). Tapping a patient opens [DoctorPatientProfilePage](lib/features/doctor/screens/doctor_patient_profile_page.dart).
- **Patient profile (doctor view)**: Name, contact, basic info; **health history** (recent glucose readings); **glucose trends** (last 7 days avg/low/high); **prescriptions/medicines** list with add/edit via [DoctorAddEditPrescriptionPage](lib/features/doctor/screens/doctor_add_edit_prescription_page.dart).
- **Prescription system**: Doctor can add or update a medicine for a patient (name, dosage, time, frequency); stored in Firestore `medicines` with patient `userId`; uses [MedicineService](lib/services/medicine_service.dart).
- **Consultation notes & diagnosis (TODO #4)**: Doctor can add/edit notes and diagnosis per patient; stored in Firestore `consultation_notes`; [ConsultationNoteService](lib/services/consultation_note_service.dart), [DoctorAddEditConsultationNotePage](lib/features/doctor/screens/doctor_add_edit_consultation_note_page.dart); listed on patient profile.
- **Risk status (TODO #5)**: [PatientRisk](lib/models/patient_risk.dart) and [DoctorPatientService.getPatientRisk](lib/services/doctor_patient_service.dart) compute risk from last 7 days glucose (low/moderate/elevated/high). Shown on patient list (badge) and on patient profile (Risk status card with summary and avg/readings).
- **Service**: [DoctorPatientService](lib/services/doctor_patient_service.dart) – `getPatients()`, `getPatientProfile(uid)`, `getPatientRisk(uid)`.

### Doctor roadmap (TODOs)

| # | Feature | Status |
|---|---------|--------|
| 1 | Patient list – screen + service | Done |
| 2 | Patient profile – health history, glucose trends, meds | Done |
| 3 | Prescription system – add/update medicine for patient | Done |
| 4 | Consultation notes & diagnosis – save notes/diagnosis (Firestore + UI) | Done |
| 5 | Risk status – compute and show on list/profile | Done |
| 6 | Monitoring dashboard – high-risk, poor control | Pending |
| 7 | Alerts for doctor – very high sugar, missed medicines | Pending |
| 8 | Messaging – doctor ↔ patient | Pending |
| 9 | Insulin adjustment in prescription flow | Pending |
| 10 | Polish – latest readings summary and risk on dashboard | Pending |

## Patient Feature Notes

- **History** is implemented as a sub-feature under `features/patient/history/` with **data** (repository), **models** (date range, stats, trend), and **presentation** (screen, viewmodel, widgets). The older flat `patient/screens/history_page.dart` may coexist; prefer the presentation screen and viewmodel for new work.
- **Reports & PDF**: `report_service.dart`, `pdf_report_service.dart`, `export_report_page.dart`, `pdf_preview_page.dart`, and widgets like `report_range_selector.dart`, `report_summary_card.dart`, `export_report_button.dart`.
- **Reminders**: `reminder_service.dart`, `reminder_storage_service.dart`, `reminder_notification_service.dart`, plus `reminders_page.dart`, `add_edit_reminder_page.dart`, and shared `reminder_settings_page.dart`.

## Auth Flow

Start → Login/Register → (Email verify) → (Second password for Doctor/Admin) → Home

- **StartingPage**: Checks auth on load; redirects to home or second-password if already logged in.
- **AppRouter** (`core/navigation`): `pushLogin()`, `pushRegister()`, `goToHome()`, `goToStart()`, etc.
- **Invite codes**: Admin generates; user enters at registration (Doctor/Admin only).
- **Second password**: If Doctor/Admin has no second password, setup form (main + second password).

## Firestore Collections

| Collection          | Key fields / use |
|---------------------|-------------------|
| `users/{uid}`       | email, displayName, role, phone, createdAt, secondPasswordHash? |
| `inviteCodes/{code}`| role, used, usedBy, usedAt, createdBy, createdAt |
| `glucose_readings`  | userId, value, type, date, time, notes, createdAt |
| `medicines`         | userId, name, dosage, time, frequency, createdAt |
| `medicine_entries`  | userId, medicineId, medicineName, date, taken, takenAt?, createdAt |
| `meals`             | userId, date, category, carbs, notes, createdAt |
| `activities`        | userId, date, type, durationMinutes, calories, notes, createdAt |

Reminders and related settings are stored via `reminder_storage_service` (e.g. local or Firestore depending on implementation).

## Run

```bash
flutter run -d android   # or windows, macos, chrome
```
