# Dia Plus - Project Structure

## Overview

Flutter diabetes app with **3 roles** (Patient, Doctor, Admin). Doctor/Admin require invite codes and a second password.

## Folder Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── navigation/app_router.dart
│   ├── theme/app_theme.dart
│   └── utils/page_transitions.dart
├── models/
│   ├── user_role.dart
│   └── app_user.dart
├── services/
│   ├── auth_service.dart
│   ├── role_service.dart         # Second password
│   └── invite_code_service.dart
└── features/
    ├── auth/screens/             # Login, Register, Email verify, Second password
    ├── home/screens/             # MainNavigationPage (tab bar)
    ├── patient/screens/          # PatientHomePage + future patient screens
    ├── doctor/screens/           # DoctorHomePage + future doctor screens
    ├── admin/screens/            # AdminHomePage, InviteCodesPage + future admin
    └── shared/screens/           # Settings, DoctorConsultation, DiabetesEssentials
```

## Future Extension by Role

### Patient
Add under `features/patient/screens/`:
- `patient_home_page.dart` - Main dashboard (greeting, latest glucose, today summary, quick actions, mini graph, reminders, health score)
- `add_reading_page.dart` - Add glucose reading
- `readings_page.dart` - View glucose readings
- `log_meal_page.dart` - Log meal (placeholder)
- `log_activity_page.dart` - Log activity (placeholder)
- `history_page.dart` - Readings history
- `profile_page.dart` - Patient profile

### Doctor
Add under `features/doctor/screens/`:
- `patients_list_page.dart` - Assigned patients
- `consultation_page.dart` - Manage consultations
- `schedule_page.dart` - Appointments

### Admin
Add under `features/admin/screens/`:
- `user_management_page.dart` - List/edit users
- `role_assignment_page.dart` - Change user roles
- `system_settings_page.dart` - App config

### Shared
Add under `features/shared/screens/` for screens used by multiple roles.

## Auth Flow

Start → Login/Register → (Email verify) → (Second password for Doctor/Admin) → Home

- **StartingPage**: Checks auth on load; redirects to home or second-password if already logged in
- **AppRouter** (core/navigation): `pushLogin()`, `pushRegister()`, `goToHome()`, `goToStart()`
- **Invite codes**: Admin generates → user enters at registration (Doctor/Admin only)
- **Second password setup**: If Doctor/Admin lacks second password, setup form appears (main + second password)

## Firestore

- `users/{uid}`: email, displayName, role, phone, createdAt, secondPasswordHash?
- `inviteCodes/{code}`: role, used, usedBy, usedAt, createdBy, createdAt

## Run

```bash
flutter run -d android   # or windows, macos
```
