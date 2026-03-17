# Dia Plus

A Flutter diabetes management app with role-based access for **Patients**, **Doctors**, and **Admins**. Patients track glucose readings, view history with graphs and statistics, and manage their health dashboard. Doctors and Admins use invite codes and a second password for extra security.

## Features

### Roles & Auth
- **Patient** – Register or log in; track glucose, view history, use dashboard.
- **Doctor** – Requires invite code and second password at registration; dedicated dashboard.
- **Admin** – Requires invite code and second password; can generate invite codes for Doctor/Admin.

Auth flow: **Login/Register** → Email verification → (Second password for Doctor/Admin) → **Dashboard**.

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
- **Packages** – `intl`, `shared_preferences`, `crypto`, `fl_chart` (charts)

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── core/                    # Navigation, theme, utils
│   ├── navigation/app_router.dart
│   ├── theme/app_theme.dart, theme_notifier.dart
│   └── utils/page_transitions.dart
├── models/                  # Domain models (user, glucose, medicine, meal, activity, reminder, health score, reports)
├── services/                 # Auth, CRUD, reminders, reports, PDF
└── features/
    ├── auth/screens/        # Starting, Login, Register, Email verify, Second password
    ├── home/screens/        # MainNavigationPage (tab bar)
    ├── patient/             # Screens, widgets, history (data + presentation)
    ├── doctor/screens/      # DoctorHomePage
    ├── admin/screens/       # AdminHomePage, InviteCodesPage
    └── shared/screens/      # Settings, Reminder settings, Doctor consultation, Diabetes essentials
```

See **PROJECT_STRUCTURE.md** for the full file tree, Firestore collections, and feature roadmap.

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
   - Deploy the rules so invite codes and glucose readings work:
     ```bash
     firebase use dia-plus-7c78c   # or your project ID
     firebase deploy --only firestore:rules
     ```
   - Ensure `.firebaserc` has the correct `default` project.

4. **First admin user**
   - Register a user in the app, then in **Firebase Console → Firestore → users**, open the document for that user’s UID and set `role` to `"admin"`. Then use that account to generate invite codes for Doctor/Admin.

## Run

```bash
# List devices
flutter devices

# Run on a connected device or emulator
flutter run -d android
flutter run -d chrome
flutter run -d windows
```

## Firestore Collections

| Collection         | Purpose |
|--------------------|--------|
| `users/{uid}`      | Profile: email, displayName, role, phone, createdAt, secondPasswordHash? |
| `inviteCodes/{id}` | Invite codes: role, used, usedBy, usedAt, createdBy, createdAt |
| `glucose_readings` | Readings: userId, date, glucoseLevel, mealTime, notes, createdAt |

## License

Private project. All rights reserved.
