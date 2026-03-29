# Dia Plus

A Flutter diabetes management app with role-based access for **Patients**, **Doctors**, and **Admins**. Patients track glucose readings, view history with graphs and statistics, and manage their health dashboard. Doctors and Admins request professional access (admin approval), then set a second password.

## Features

### Roles & Auth
- **Patient** – Register or log in; track glucose, view history, use dashboard.
- **Doctor** – After registration and email verification, request professional access; once an admin approves, set a second password; dedicated dashboard. **My Patients** lists all patients with risk badges; tap a patient for **Patient profile**: name, contact, basic info; **risk status** (from last 7 days glucose); **health history** (recent glucose); **glucose trends** (7-day summary); **prescriptions** (add/edit medicines); **consultation notes & diagnosis** (add/edit per patient).
- **Admin** – Same professional onboarding as Doctor for admin accounts; can approve access requests and manage users.

Auth flow: **Login/Register** → Email verification → (Professional access request → approval → second password for Doctor/Admin) → **Dashboard**.

### Patient Features
- **Dashboard** – Greeting, latest glucose card, today’s summary, quick actions (Add Reading, Log Meal, Log Activity, Take Medicine), 7-day mini graph, upcoming reminders, health score.
- **Glucose Readings** – Add reading (value, type e.g. Fasting/Before meal/After meal/Bedtime, notes), edit, delete, search. Auto status: Low / Normal / High.
- **History** – Date filter (Today, Last 7 days, Last 30 days, This month), daily/weekly/monthly graphs, statistics (average, highest, lowest), list of readings.
- **Readings tab** – Full list with search; edit and delete from list.
- **Settings** – Profile and app settings (see `features/shared/screens/settings_page.dart`).
- **Doctor consultation** and **Diabetes essentials** – Linked from dashboard.

### Tech Stack
- **Flutter** (Dart 3.x)
- **Firebase** – Authentication, Firestore
- **Packages** – `intl`, `shared_preferences`, `crypto`, `fl_chart` (charts), `pdf` & `printing` (reports), `flutter_local_notifications` & `timezone` (reminders)

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── core/                    # Navigation, theme, utils
│   ├── navigation/app_router.dart
│   ├── theme/app_theme.dart, theme_notifier.dart
│   └── utils/page_transitions.dart
├── ui/
│   └── responsive.dart      # ResponsiveCenter, breakpoints (phone/tablet/web)
├── models/                  # Domain models (user, glucose, medicine, prescription, appointment, reminder, etc.)
├── services/                # Auth, CRUD, reminders, reports, PDF, appointments, prescriptions, alerts, messaging
└── features/
    ├── auth/screens/        # Starting, Login, Register, Email verify, Second password
    ├── home/screens/        # MainNavigationPage (tab bar)
    ├── patient/             # Screens, widgets, history (data + presentation)
    ├── doctor/screens/      # Home, Patients, Appointments, Patient profile, Prescription detail, Add/edit prescription, Consultation note, Monitoring, Alerts
    ├── admin/screens/       # AdminHomePage, user management, access requests, audit logs, backups
    └── shared/screens/      # Settings, Reminder settings, Doctor consultation, Diabetes essentials, Chat, Emergency, Notifications
```

See **PROJECT_STRUCTURE.md** for the full file tree, layer summary, and Firestore collections.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (SDK ^3.10.7)
- [Firebase](https://firebase.google.com/) project with **Authentication** (Email/Password) and **Firestore** enabled
- For Android: Android Studio / SDK; for web: Chrome

## Setup

1. **Clone and install**
   ```bash
   git clone <your-repo-url>
   cd dia_plus
   flutter pub get
   ```

2. **Firebase**
   - Create a Firebase project and add an Android (and/or iOS/Web) app.
   - Download `google-services.json` (Android) and place it in `android/app/`.
   - Generate Flutter Firebase config:
     ```bash
     dart run flutterfire_cli:flutterfire configure
     ```
     This creates/updates `lib/firebase_options.dart`.

3. **Firestore rules**
   - Deploy Firestore rules (security for users, readings, etc.):
     ```bash
     firebase use dia-plus-7c78c   # or your project ID
     firebase deploy --only firestore:rules
     ```
   - Ensure `.firebaserc` has the correct `default` project.

4. **First admin user**
   - Register a user in the app, then in **Firebase Console → Firestore → users**, open the document for that user’s UID and set `role` to `"admin"`. Use that account to approve Doctor/Admin access requests in the app.

## Run

```bash
# List devices
flutter devices

# Run on a connected device or emulator
flutter run -d android
flutter run -d chrome
flutter run -d windows
```

To deploy Firestore rules:

```bash
firebase use <your-project-id>
firebase deploy --only firestore:rules
```

## Firestore Collections

| Collection           | Purpose |
|----------------------|--------|
| `users/{uid}`        | Profile: email, displayName, role, phone, createdAt, secondPasswordHash? |
| `users/{uid}/access_requests/{id}` | Professional access requests (pending/approved/rejected) |
| `glucose_readings`   | Readings: userId, date, glucoseLevel, mealTime, notes, createdAt |
| `medicines`          | Medicines: userId, name, dosage, time, times?, frequency, prescriptionId?, createdAt |
| `prescriptions/{id}` | Prescription groups: patientId, createdAt |
| `consultation_notes` | Doctor notes/diagnosis: patientId, doctorId, note, diagnosis, createdAt, updatedAt? |
| `appointments`      | Appointment requests: patientId, doctorId, status (pending/accepted/rejected), createdAt |
| `conversations`      | Chat: participants, lastMessageAt |
| `messages`           | Chat messages: conversationId, senderId, receiverId, text, createdAt |

See **PROJECT_STRUCTURE.md** for more collections and details.

## Additional docs

- **docs/C_DRIVE_SPACE.md** – How to move Gradle and Pub cache off the C: drive to save disk space.

## License

Private project. All rights reserved.
