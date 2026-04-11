# DiaPulse - Intelligent Diabetes Management System

**Version:** 1.0.0  
**Platform:** Android, Web, Windows  
**Tech Stack:** Flutter + Firebase  

DiaPulse is a comprehensive diabetes management application built for three user roles — Patients, Doctors, and Admins. It provides real-time glucose monitoring, intelligent pattern detection, emergency alerting, doctor-patient communication, medication management, PDF report generation, and a full admin control panel with dynamic app configuration.

---

## Table of Contents

- [System Architecture](#system-architecture)
- [Authentication & Role System](#authentication--role-system)
- [Patient Features](#patient-features)
- [Doctor Features](#doctor-features)
- [Admin Features](#admin-features)
- [Shared Features](#shared-features)
- [Data Models](#data-models)
- [Service Layer](#service-layer)
- [Firestore Schema](#firestore-schema)
- [Security Rules](#security-rules)
- [Cloud Functions](#cloud-functions)
- [Design System](#design-system)
- [Dependencies](#dependencies)
- [Setup & Deployment](#setup--deployment)

---

## System Architecture

```
lib/
├── main.dart                              App entry point, Firebase init, step counter registration
├── firebase_options.dart                  Firebase configuration (auto-generated)
├── core/
│   ├── navigation/app_router.dart         Centralized route definitions & navigation helpers
│   ├── theme/app_theme.dart               Material 3 theme (colors, typography, components)
│   ├── theme/theme_notifier.dart           Theme state management
│   └── utils/page_transitions.dart        Custom page transition animations
├── ui/
│   └── responsive.dart                    Responsive breakpoints (phone < 600, tablet < 1024, desktop)
├── background/
│   └── step_counter_background.dart       Android WorkManager periodic step sync (~15 min)
├── models/                                34 domain models
├── services/                              38 service classes
└── features/
    ├── auth/screens/                      7 authentication screens
    ├── home/screens/                      Main navigation container (role-based tabs)
    ├── patient/screens/                   22 patient screens
    │   └── history/presentation/          History sub-feature (graphs, stats, filters)
    ├── doctor/screens/                    9 doctor screens
    ├── admin/screens/                     9 admin screens
    └── shared/screens/                    11 shared screens (settings, chat, essentials)
```

**Key Architectural Decisions:**
- Feature-first folder structure with role separation
- Service layer abstracts all Firebase operations from UI
- Models are immutable with `fromMap` / `toMap` / `copyWith` patterns
- StreamBuilder-based reactive UI with Firestore real-time listeners
- In-memory stream caching in services to reduce Firestore reads
- Hardcoded fallbacks for admin-configurable values (graceful degradation)
- Platform-adaptive file I/O (io/web/stub variants for backup export)

---

## Authentication & Role System

### Roles

| Role | Access Level | Onboarding |
|------|-------------|------------|
| **Patient** | Personal health data, self-management tools | Register → Email verify → Dashboard |
| **Doctor** | Patient monitoring, prescriptions, consultations | Register → Email verify → Request access → Admin approval → Second password → Dashboard |
| **Admin** | Full system control, user management, audit logs | Register → Email verify → Request access → Approval → Second password → Dashboard |

### Auth Flow

```
StartingPage → Login / Register
    ↓
Email Verification
    ↓
[Patient] ──────────────────────────→ MainNavigationPage
[Doctor/Admin] → Professional Access Request
    ↓
Admin Approval (pending queue)
    ↓
Complete Professional Registration → Second Password Setup
    ↓
MainNavigationPage (role-specific dashboard)
```

### Security

- Firebase Authentication for identity (email/password)
- Firestore role field (`users/{uid}.role`) for authorization
- Second password hashed with SHA-256 via `crypto` package
- Blocked users (`blocked: true`) auto-signed out on login and home page bootstrap
- Protected fields: `role` and `blocked` cannot be self-modified (enforced by security rules)

---

## Patient Features

### Dashboard (`patient_home_page.dart`)
- Personalized greeting with user name
- Latest glucose reading card with color-coded status
- Today's summary (readings count, average, status)
- Quick action buttons: Add Reading, Log Meal, Log Activity, Take Medicine
- 7-day glucose mini graph (fl_chart)
- Upcoming reminders
- Health score card with period toggle

### Glucose Tracking
- **Add Reading** — Slider input (40-400 mg/dL), meal time selection, date picker, notes
- **Edit Reading** — Modify any field of an existing reading
- **Readings List** — Searchable list with edit/delete
- **Auto Status Classification:**
  - Low: < 70 mg/dL (blue)
  - Normal: 70-140 mg/dL (green)
  - High: 141-200 mg/dL (orange)
  - Very High: > 200 mg/dL (red)

### History & Analytics
- Date range filters: Today, Last 7 days, Last 30 days, This month
- Interactive glucose trend graphs (daily/weekly/monthly)
- Statistics: average, highest, lowest, standard deviation
- Chronological readings list

### Pattern Detection & Insights
- Rule-based intelligent pattern analysis
- Detects: morning highs, post-meal spikes, low episodes, high variability, improving trends, good control
- Severity levels: info, warning, success, critical
- Configurable thresholds for pattern sensitivity

### Health Score
- Composite score 0-100 calculated from glucose readings
- Periods: Today (10 readings target), Last 7 days (21), Last 30 days (90)
- Categories: Excellent (80+), Good (60-79), Fair (40-59), Poor (<40)
- Breakdown view showing contributing factors

### Emergency Alerts
- Automatic detection when glucose falls below or rises above critical thresholds
- Default thresholds: Critical Low (< 60 mg/dL), Critical High (> 300 mg/dL)
- Per-user configurable thresholds via emergency settings
- Alert types: Critical Low, Critical High, Moderate High
- 2-minute duplicate cooldown to prevent alert spam
- Alert history (max 200 records) with acknowledge/dismiss
- Simulated doctor and emergency contact notifications

### Medication Management
- Add/edit/delete medicines with name, dosage, frequency, timing
- Medicine timing options: specific time, before/after breakfast/lunch/dinner
- Take medicine logging with timestamp
- Medicine usage history
- Prescription view (from doctor-assigned prescriptions)

### Meal & Activity Logging
- **Log Meal** — Category (admin-configurable), carbs, notes, date
- **Log Activity** — Type (admin-configurable), duration, calories, notes, date

### PDF Reports
- Professional branded PDF generation
- Includes glucose data, statistics, trends
- Preview before sharing
- Export/print/share via device capabilities

### Appointments
- Request appointments with doctors
- View appointment status (pending, accepted, rejected)

### Reminders
- Types: Glucose test, Medicine, Exercise, Appointment
- Repeat modes: Once, Daily, Weekly, Monthly
- Local push notifications with timezone support
- Persistent storage via SharedPreferences

### Step Counter
- Hardware pedometer integration (Android)
- Background sync via WorkManager (~15 minute intervals)
- Daily step totals stored in `users/{uid}/daily_steps/{date}`
- Requires activity recognition permission

---

## Doctor Features

### Dashboard (`doctor_home_page.dart`)
- Overview of assigned patients
- Quick access to appointments and alerts

### Patient Management
- **My Patients** — List of all patients with risk badges
- **Patient Profile** — Name, contact, basic info, risk status
- **Health History** — Recent glucose readings for the patient
- **Glucose Trends** — 7-day summary graphs
- **Risk Assessment** — Calculated from last 7 days of readings

### Clinical Tools
- **Prescriptions** — Create/edit prescription groups with multiple medicines
  - Insulin support: rapid-acting, short-acting, intermediate-acting, long-acting, mixed
  - Frequency options: once daily, twice daily, weekly
- **Consultation Notes** — Write diagnosis and clinical notes per patient
- **Monitoring Dashboard** — Real-time patient glucose trend monitoring

### Appointments
- View incoming appointment requests from patients
- Accept or reject appointments

### Alerts
- Emergency alert notifications from patients
- Very high glucose threshold alerts (> 200 mg/dL)
- Critical glucose alerts (< 60 or > 300 mg/dL)
- Configurable lookback period (default 2 days)

---

## Admin Features

### Dashboard (`admin_home_page.dart`)
- Active user statistics (total, by role, suspended count)
- Daily glucose readings count (today and last 7 days)
- Quick navigation to all admin tools

### User Management
- Search and filter all users
- Change user role (patient / doctor / admin)
- Suspend/unsuspend users (blocked flag)
- Delete user with full Firestore data cleanup across all collections

### Professional Access Requests
- Pending queue of doctor/admin applicants
- Approve or reject each request
- Approval enables the applicant to complete registration and set second password

### Audit Logs
- Paginated audit timeline with filters
- Filter by: action type, category, actor UID, target UID, date range
- Tracked actions: login success/blocked, role changes, user blocks, user deletions, config changes
- 90-day retention (auto-purged by Cloud Function)

### Announcements
- Create announcements with title, body
- Target by role: all, patient, doctor, admin
- Publish/unpublish toggle
- Edit and delete existing announcements

### App Configuration (Dynamic Values)
- **Meal Categories** — Manage meal types used in Log Meal (e.g., Breakfast, Lunch, Dinner, Snack)
- **Meal Times** — Manage glucose reading meal-time options (e.g., Fasting, Before meal, After meal)
- **Activity Types** — Manage exercise types used in Log Activity (e.g., Walking, Running, Cycling)
- **Diabetes Essentials** — Manage educational content shown on user dashboard (grouped by section)
- Each item supports: name, description, color, icon, sort order, active/inactive toggle
- Changes are reflected instantly for all users via real-time Firestore streams
- All config mutations are audit-logged

### Backup & Restore
- **Export** — Select collections and export to JSON
- **Restore** — Validate backup JSON, dry-run preview, then execute import with batching

### System Monitoring
- Glucose readings per day trend chart (last 14 days)
- Active users per day trend chart (last 14 days)

---

## Shared Features

### Settings
- Profile management (name, phone, photo)
- Theme and display preferences
- Reminder notification settings
- Emergency alert threshold configuration

### Messaging
- Real-time doctor-patient chat
- Conversation list with last message preview
- New conversation partner selection
- Messages stored in Firebase Realtime Database for low-latency delivery
- Metadata in Firestore for querying and admin access

### Notifications
- In-app notification inbox with unread badge
- Notification types: appointment updates, new messages, prescription changes
- Read/unread toggle (immutable content fields enforced by security rules)

### Announcements
- Published announcements from admin
- Role-filtered display (patients see patient announcements, etc.)
- Read receipts tracked per user

### Diabetes Essentials
- Admin-managed educational content
- Sections: Understanding Diabetes, Diet & Nutrition, Exercise Tips, Medication Guide
- Section-based filtering with chip navigation
- Content cards with descriptions

### Doctor Consultation
- Patient can request consultations with available doctors

---

## Data Models

| Model | File | Purpose |
|-------|------|---------|
| `AppUser` | `app_user.dart` | User profile with role, email, name, phone, avatar, block status |
| `UserRole` | `user_role.dart` | Enum: patient, doctor, admin |
| `GlucoseReading` | `glucose_reading.dart` | Reading value, meal time, date, notes, status calculation |
| `GlucosePatternInsight` | `glucose_pattern_insight.dart` | Detected pattern with type, severity, description |
| `GlucosePatternType` | `glucose_pattern_type.dart` | Enum: morning-high, post-meal-spike, low-episode, etc. |
| `GlucoseReportData` | `glucose_report_data.dart` | DTO for PDF report generation |
| `GlucoseReportStats` | `glucose_report_stats.dart` | Statistics: avg, min, max, std dev, count |
| `HealthScore` | `health_score.dart` | Score 0-100 with period and timestamp |
| `HealthScoreBreakdown` | `health_score_breakdown.dart` | Component scores |
| `InsightSeverity` | `insight_severity.dart` | Enum: info, warning, success, critical |
| `Medicine` | `medicine.dart` | Name, dosage, frequency, timing, prescription link |
| `MedicineEntry` | `medicine_entry.dart` | Medicine adherence tracking |
| `Prescription` | `prescription.dart` | Prescription group with medicines |
| `Meal` | `meal.dart` | Meal log: category, carbs, notes, date |
| `Activity` | `activity.dart` | Activity log: type, duration, calories, notes, date |
| `Appointment` | `appointment.dart` | Request with status (pending/accepted/rejected) |
| `ConsultationNote` | `consultation_note.dart` | Doctor's notes, diagnosis, patient/doctor IDs |
| `PatientRisk` | `patient_risk.dart` | Risk level from recent readings |
| `Reminder` | `reminder.dart` | Time, type, repeat mode, enabled status |
| `ReminderType` | `reminder_type.dart` | Enum: medicine, glucoseTest, exercise, appointment |
| `ReminderRepeatMode` | `reminder_repeat_mode.dart` | Enum: once, daily, weekly, monthly |
| `ReminderSettings` | `reminder_settings.dart` | User reminder preferences |
| `AppNotification` | `app_notification.dart` | In-app notification with actor, type, read status |
| `EmergencyAlert` | `emergency_alert.dart` | Emergency event with glucose value, type, timestamps |
| `EmergencyAlertType` | `emergency_alert_type.dart` | Enum: criticalLow, criticalHigh |
| `EmergencySettings` | `emergency_settings.dart` | Per-user thresholds (default: low 60, high 300) |
| `DoctorAlert` | `doctor_alert.dart` | Alert for doctors about patient readings |
| `Conversation` | `conversation.dart` | Chat conversation metadata |
| `ChatMessage` | `chat_message.dart` | Message with sender, receiver, text, timestamp |
| `Announcement` | `announcement.dart` | Admin broadcast with title, body, target role, publish status |
| `AuditLogEntry` | `audit_log_entry.dart` | Audit record with actor, action, category, metadata |
| `InviteAccessRequest` | `invite_access_request.dart` | Professional access request |
| `AppConfigItem` | `app_config_item.dart` | Dynamic config: name, description, icon, color, order, isActive, metadata |

---

## Service Layer

### Authentication & Profiles
| Service | Purpose |
|---------|---------|
| `AuthService` | Firebase Auth sign in/up, email verification, second password, session management |
| `ProfileService` | User profile CRUD |
| `RoleService` | Role-based permission checks |

### Glucose & Health
| Service | Purpose |
|---------|---------|
| `GlucoseReadingService` | CRUD for glucose readings, Firestore queries |
| `PatternDetectionService` | Rule-based AI pattern detection with configurable thresholds |
| `HealthScoreService` | Health score calculation by period (today, 7d, 30d) |

### Reports
| Service | Purpose |
|---------|---------|
| `PdfReportService` | Professional branded PDF generation |
| `ReportService` | Report data assembly and statistics |

### Appointments & Consultations
| Service | Purpose |
|---------|---------|
| `AppointmentService` | Request/accept/reject appointments |
| `ConsultationNoteService` | Doctor's notes CRUD |

### Reminders & Notifications
| Service | Purpose |
|---------|---------|
| `ReminderService` | Reminder scheduling and management |
| `ReminderNotificationService` | Local push notification handling |
| `ReminderStorageService` | Persistent reminder storage (SharedPreferences) |
| `NotificationService` | In-app notification CRUD |

### Emergency
| Service | Purpose |
|---------|---------|
| `EmergencyAlertService` | Threshold detection, alert creation, duplicate cooldown |
| `EmergencyNotificationService` | Emergency notification delivery |
| `EmergencySettingsService` | Per-user threshold CRUD |

### Messaging
| Service | Purpose |
|---------|---------|
| `MessagingService` | Real-time chat via Realtime Database + Firestore metadata |

### Medicines & Activities
| Service | Purpose |
|---------|---------|
| `MedicineService` | Medicine CRUD |
| `MealService` | Meal logging |
| `ActivityService` | Activity logging |

### Health Sensors
| Service | Purpose |
|---------|---------|
| `StepCounterService` | Pedometer integration, daily step totals |

### Doctor Tools
| Service | Purpose |
|---------|---------|
| `DoctorAlertService` | Emergency and high-glucose alerts for doctors |
| `DoctorPatientService` | Doctor's patient list and relationship management |

### Admin
| Service | Purpose |
|---------|---------|
| `AdminUserService` | Role updates, block/unblock, multi-collection user data deletion |
| `AdminAnnouncementService` | Announcement CRUD with publish control |
| `AnnouncementService` | Announcement delivery to users |
| `AdminBackupService` | Collection export and JSON serialization |
| `AdminRestoreService` | Backup validation and restore pipeline with batching |
| `AdminConfigService` | Dynamic app configuration CRUD with audit logging |
| `ConfigService` | User-facing config reads with in-memory stream caching |
| `InviteAccessRequestService` | Professional access request queue |
| `AuditLogService` | Audit trail append + paginated query API |

---

## Firestore Schema

| Collection | Fields | Access |
|------------|--------|--------|
| `users/{uid}` | email, displayName, role, phone, photoUrl, blocked, createdAt, updatedAt, secondPasswordHash, professionalInvitePending, extra | Auth read; owner update (except role/blocked); admin full |
| `users/{uid}/access_requests/{id}` | userId, email, displayName, role, status, message, createdAt | Owner read/create; admin update/delete |
| `users/{uid}/announcement_reads/{aid}` | (read receipt) | Owner read/write; admin read/delete |
| `users/{uid}/daily_steps/{date}` | steps, lastUpdated | Owner only |
| `glucose_readings` | userId, date, glucoseLevel, mealTime, notes, createdAt | Auth read; owner create; owner+admin update/delete |
| `medicines` | userId, name, dosage, frequency, time, prescriptionId, createdAt | Owner+doctor+admin read; owner+doctor write |
| `medicine_entries` | userId, medicineId, takenAt | Owner+doctor+admin read; owner create |
| `prescriptions/{id}` | patientId, doctorId, createdAt | Patient+doctor+admin read; doctor write |
| `consultation_notes` | patientId, doctorId, note, diagnosis, createdAt | Patient+doctor+admin read; doctor write |
| `meals` | userId, date, category, carbs, notes, createdAt | Owner+doctor+admin read; owner write |
| `activities` | userId, date, type, durationMinutes, calories, notes, createdAt | Owner+doctor+admin read; owner write |
| `appointments` | patientId, doctorId, status, createdAt | Patient+doctor+admin read; patient create; doctor update |
| `conversations` | participants, lastMessageAt | Participants+admin read/write |
| `messages` | senderId, receiverId, text, createdAt | Sender+receiver+admin read; sender create |
| `notifications` | userId, actorId, type, title, body, read, createdAt | Recipient+admin read; actor create; recipient update (read only) |
| `announcements` | title, body, targetRole, published, createdBy, createdAt | Auth read (published); admin write |
| `audit_logs` | actorId, action, category, targetUserId, metadata, createdAt | Auth append-only; admin read; no update/delete |
| `app_config/{collection}/items/{id}` | name, description, icon, color, order, isActive, metadata, createdAt, updatedAt | Auth read; admin write |

---

## Security Rules

- Role-based authorization via `isAdmin()` and `isDoctor()` helper functions
- Admin checks: `users/{uid}.role == 'admin'` with existence guard
- Self-escalation prevention: users cannot change their own `role` or `blocked` fields
- Append-only audit logs: no update or delete allowed for any user
- Notification immutability: recipients can only toggle the `read` field
- Access requests: applicants can only create with `status: 'pending'`
- Professional access: requires admin approval before second password setup

---

## Cloud Functions

### `purgeAuditLogs`
- **Schedule:** Daily at 03:00 UTC
- **Purpose:** Removes audit log entries older than 90 days
- **Batch Size:** 500 documents per iteration
- **Retry:** 2 attempts
- **Runtime:** Firebase Admin SDK (bypasses security rules)

---

## Design System

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#A8E6CF` (Mint Green) | Buttons, FABs, active states |
| Secondary | `#CDB4DB` (Lavender) | Accents, secondary actions |
| Accent | `#FFD6A5` (Peach) | Highlights, badges |
| Background | `#F8F9FA` (Light Gray) | Page backgrounds |
| Card Mint | `#EAF7F1` | Card tints |
| Card Lavender | `#F3EFFF` | Card tints |
| Text Primary | `#1E1E1E` | Headings, body text |
| Text Secondary | `#4A4A4A` | Subtitles, captions |
| Error | `#FF8A80` (Soft Red) | Error states |

### Typography
- Font family: **Poppins** (Google Fonts)
- Material Design 3 enabled
- Consistent weight scale: w400 (body), w600 (subtitle), w700 (title), w800 (stat values)

### Components
- Rounded corners: 12-28px depending on component
- Card elevation with subtle shadows
- Gradient buttons (teal for primary actions)
- Color-coded glucose status indicators
- Chip-based selection for categories and filters

---

## Dependencies

### Core
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | UI framework |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### Firebase
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^4.4.0 | Firebase initialization |
| `firebase_auth` | ^6.1.4 | Authentication |
| `cloud_firestore` | ^6.1.1 | Database |
| `firebase_database` | ^12.1.3 | Realtime DB (messaging) |

### Data & Security
| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | ^2.2.2 | Local key-value storage |
| `crypto` | ^3.0.3 | SHA-256 second password hashing |

### UI & Visualization
| Package | Version | Purpose |
|---------|---------|---------|
| `google_fonts` | ^6.3.2 | Poppins typography |
| `intl` | ^0.19.0 | Date/time formatting |
| `fl_chart` | ^0.69.0 | Glucose trend graphs |

### Reports
| Package | Version | Purpose |
|---------|---------|---------|
| `pdf` | ^3.10.8 | PDF document generation |
| `printing` | ^5.13.1 | PDF preview, share, print |

### Notifications
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_local_notifications` | ^17.2.3 | Push notifications |
| `timezone` | ^0.9.4 | Timezone handling |
| `flutter_timezone` | ^4.1.1 | Device timezone detection |

### Health & Sensors
| Package | Version | Purpose |
|---------|---------|---------|
| `pedometer` | ^4.1.1 | Step counter hardware sensor |
| `permission_handler` | ^11.3.1 | Runtime permission requests |
| `workmanager` | ^0.9.0+3 | Android background task scheduling |

### File System
| Package | Version | Purpose |
|---------|---------|---------|
| `path_provider` | ^2.1.5 | Platform file paths |

---

## Setup & Deployment

### Prerequisites
- Flutter SDK ^3.10.7
- Firebase project with Authentication (email/password) and Firestore enabled
- Android Studio / SDK (for Android builds)
- Node.js (for Cloud Functions deployment)

### Installation
```bash
git clone <repo-url>
cd DiaPulse-SYSTEM-PROJECT
flutter pub get
```

### Firebase Configuration
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure

# Deploy security rules
firebase login
firebase deploy --only firestore:rules

# Deploy Cloud Functions
cd functions
npm install
firebase deploy --only functions
```

### First Admin Setup
1. Register a user in the app
2. Open Firebase Console -> Firestore -> `users` collection
3. Find the user document by UID
4. Set `role` field to `"admin"`
5. Use that account to approve future doctor/admin requests

### Run
```bash
flutter run -d android
flutter run -d chrome
flutter run -d windows
```

---

## License

Private project. All rights reserved.
