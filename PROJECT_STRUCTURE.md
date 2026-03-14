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

### Patient – feature roadmap (branch: feature/patient)

**Basic (MVP)** – implement in:

| # | Feature | Where to implement |
|---|---------|--------------------|
| 1 | Dashboard: Take medicine action + Next glucose test reminder | `features/patient/screens/patient_home_page.dart`, `take_medicine_page.dart` ✓ |
| 2 | Glucose: Reading type (Fasting/Before/After meal/Bedtime), Notes, Edit/Delete, Search | `add_reading_page.dart`, `readings_page.dart`, `edit_reading_page.dart`, `models/glucose_reading.dart`, `services/glucose_reading_service.dart` ✓ |
| 3 | History: List + date filter, Daily/Weekly/Monthly graphs, Stats (avg, max, min) | `features/patient/screens/history_page.dart`, `main_navigation_page.dart` ✓ |
| 4 | Medication: Log (add, dosage, time, frequency), Reminder, History (taken/missed) | `add_edit_medicine_page.dart`, `medicine_list_page.dart`, `medicine_history_page.dart`, `take_medicine_page.dart`, `models/medicine.dart`, `models/medicine_entry.dart`, `services/medicine_service.dart`, Firestore `medicines`, `medicine_entries` ✓ |
| 5 | Meal Tracking: Add meal, carbs, category (Breakfast/Lunch/Dinner/Snack) | `log_meal_page.dart`, `models/meal.dart`, `services/meal_service.dart`, Firestore `meals` ✓ |
| 6 | Activity: Exercise type, duration, calories | `log_activity_page.dart`, `models/activity.dart`, `services/activity_service.dart`, Firestore `activities` ✓ |
| 7 | Profile: Name, Age, Weight, Height, Diabetes type | `profile_page.dart`, `services/profile_service.dart`, `users` doc (age, weight, height, diabetesType) ✓ |
| 8 | Settings: Notifications, Target glucose range, Emergency contact | `features/shared/screens/settings_page.dart` |

**Moderate** – implement in:

| # | Feature | Where to implement |
|---|---------|--------------------|
| 9 | Analytics: Trend (rising/stable/improving), Pattern detection | `features/patient/` analytics widget or new screen, use readings data |
| 10 | Smart Graphs: Morning vs night, Meal impact, Weekly variation | `features/patient/screens/history_page.dart` or new `analytics_page.dart` |
| 11 | Health Score: Add exercise + meal logging to calculation | `patient_home_page.dart` + small scoring service/helper |
| 12 | Achievement System: Streaks, badges (e.g. 7-day streak) | `features/patient/` achievements widget/screen, models for badges |
| 13 | Smart Reminders: Medicine, glucose test, appointment, exercise | `services/` reminder/notification service, local notifications |
| 14 | Report Generation: Export PDF/CSV, Share with doctor | `features/patient/` report page or settings, export service |
| 15 | Doctor Connection: Send report, Request appointment, Chat | `features/patient/` + `features/doctor/`, shared chat/requests |

Existing patient files:
- `patient_home_page.dart` – Dashboard (greeting, latest glucose, today summary, quick actions, mini graph, reminders, health score)
- `add_reading_page.dart` – Add glucose reading
- `readings_page.dart` – View glucose readings
- `history_page.dart` – List + date filter, Daily/Weekly/Monthly graphs, stats
- `log_meal_page.dart` – Log meal (date, category, carbs, notes)
- `log_activity_page.dart` – Log activity (date, type, duration, calories)
- `take_medicine_page.dart` – opens Medicine list
- `add_edit_medicine_page.dart`, `medicine_list_page.dart`, `medicine_history_page.dart` – Medication log, Take/Missed, History
- `profile_page.dart` – Edit profile (name, age, weight, height, diabetes type). Opened from Settings for patients.

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
- `glucose_readings/{id}`: userId, value, type, date, time, notes, createdAt
- `medicines/{id}`: userId, name, dosage, time, frequency, createdAt
- `medicine_entries/{id}`: userId, medicineId, medicineName, date, taken, takenAt?, createdAt
- `meals/{id}`: userId, date, category, carbs, notes, createdAt
- `activities/{id}`: userId, date, type, durationMinutes, calories, notes, createdAt

## Run

```bash
flutter run -d android   # or windows, macos
```
