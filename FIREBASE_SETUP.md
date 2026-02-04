# Firebase Setup Steps for Dia Plus

Follow these steps to connect your app to Firebase (Authentication + Firestore).

---

## 1. Create a Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** (or use an existing project).
3. Enter project name (e.g. `dia-plus`) and follow the wizard.
4. You can disable Google Analytics if you don’t need it.

---

## 2. Enable Authentication (Email/Password)

1. In the Firebase Console, open your project.
2. In the left menu, go to **Build → Authentication**.
3. Click **Get started**.
4. Open the **Sign-in method** tab.
5. Click **Email/Password**, turn **Enable** on, then **Save**.

---

## 3. Enable Firestore

1. In the left menu, go to **Build → Firestore Database**.
2. Click **Create database**.
3. Choose **Start in test mode** (for development).  
   For production, switch to production rules later.
4. Pick a Firestore location and **Enable**.

---

## 4. Register your Android app

1. In Project Overview (home), click the **Android** icon to add an Android app.
2. **Android package name**: use `com.example.dia_plus` (must match `android/app/build.gradle.kts` → `applicationId`).
3. App nickname and Debug signing certificate SHA-1 are optional for now.
4. Click **Register app**.
5. Download **google-services.json**.
6. Put `google-services.json` inside:
   ```
   dia_plus/android/app/
   ```
   (same folder as `build.gradle.kts`).

---

## 5. Register your iOS app (if you build for iOS)

1. In Project Overview, click the **iOS** icon.
2. **iOS bundle ID**: use the one from Xcode (e.g. `com.example.diaPlus`).
3. Download **GoogleService-Info.plist**.
4. Open the `ios/Runner` folder in Xcode and add **GoogleService-Info.plist** to the Runner target (check “Copy items if needed”).

---

## 6. (Optional) Web

1. In Project Overview, click the **Web** icon.
2. Register the app and copy the `firebaseConfig` object.
3. You can add it later to `web/index.html` if you use Firebase on web.

---

## 7. Firestore security rules (for production)

In **Firestore → Rules**, you can use rules like this so only signed-in users can read/write their own data:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

For development you can keep **test mode**; change to these rules before going to production.

---

## 8. Run the app

1. Ensure `google-services.json` is in `android/app/`.
2. From the project root run:
   ```bash
   flutter pub get
   flutter run
   ```
3. Open the app → you should see the **Starting** page with **Login** and **Register**.
4. Use **Register** to create an account (email + password). User profile is stored in Firestore under the `users` collection.

---

## Summary

| Step | What you did |
|------|----------------|
| 1 | Created a Firebase project |
| 2 | Enabled Email/Password sign-in |
| 3 | Created a Firestore database |
| 4 | Registered Android app and added `google-services.json` to `android/app/` |
| 5 | (Optional) Registered iOS and added `GoogleService-Info.plist` |
| 6 | (Optional) Registered web app |
| 7 | (Later) Adjusted Firestore rules for production |

**Important:** Do not commit `google-services.json` or `GoogleService-Info.plist` to a public repo if they contain sensitive data. You can add them to `.gitignore` for public repos or use environment-specific configs.
