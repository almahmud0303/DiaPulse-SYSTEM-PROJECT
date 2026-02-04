# Fix: Cannot Login on Web (Edge Browser)

## 🔍 Problem

- ✅ **Mobile (Android)**: Login works fine
- ❌ **Web (Edge)**: Cannot login with same email

## 🔎 Root Cause

Firebase web configuration is **not set up**. The `web/index.html` and `lib/firebase_options.dart` still have **placeholder values** (`YOUR_WEB_API_KEY`, `YOUR_WEB_APP_ID`), so Firebase never initializes on web.

---

## ✅ Solution: Get Web Config from Firebase Console

### Step 1: Register Web App (If Not Done)

1. Go to **[Firebase Console](https://console.firebase.google.com/)**
2. Select your project: **dia-plus-7c78c**
3. Click **Project Overview** (home icon)
4. Look for **"Your apps"** section
5. If you see a **Web icon (`</>`)**, click it
   - If you don't see it, click **"Add app"** → **Web**
6. Fill in:
   - **App nickname**: `Dia Plus Web`
   - **Firebase Hosting**: Leave unchecked
7. Click **"Register app"**

---

### Step 2: Copy Web Configuration

After registering, Firebase shows a config like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "dia-plus-7c78c.firebaseapp.com",
  projectId: "dia-plus-7c78c",
  storageBucket: "dia-plus-7c78c.appspot.com",
  messagingSenderId: "284015189329",
  appId: "1:284015189329:web:xxxxxxxxxxxxx"
};
```

**Copy these TWO values:**
- `apiKey` (starts with `AIzaSy...`)
- `appId` (starts with `1:284015189329:web:...`)

---

### Step 3: Update `lib/firebase_options.dart`

Open `lib/firebase_options.dart` and find the web section (around line 22-32):

**Current (WRONG):**
```dart
if (kIsWeb) {
  return const FirebaseOptions(
    apiKey: 'web-api-key-from-console',  // ❌ Placeholder
    appId: 'web-app-id-from-console',     // ❌ Placeholder
    messagingSenderId: 'messaging-sender-id',
    projectId: 'dia-plus-7c78c',
    authDomain: 'dia-plus-7c78c.firebaseapp.com',
    storageBucket: 'dia-plus-7c78c.firebasestorage.app',
  );
}
```

**Replace with (CORRECT):**
```dart
if (kIsWeb) {
  return const FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',  // ← Your web API key from Firebase Console
    appId: '1:284015189329:web:xxxxxxxxxxxxx',      // ← Your web app ID from Firebase Console
    messagingSenderId: '284015189329',
    projectId: 'dia-plus-7c78c',
    authDomain: 'dia-plus-7c78c.firebaseapp.com',
    storageBucket: 'dia-plus-7c78c.appspot.com',    // ← Note: .appspot.com (not .firebasestorage.app)
  );
}
```

**Important:** Replace `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` and `1:284015189329:web:xxxxxxxxxxxxx` with your **actual values** from Firebase Console.

---

### Step 4: Update `web/index.html` (Optional but Recommended)

Open `web/index.html` and update the Firebase config:

**Find this section (around line 50-64):**
```javascript
var firebaseConfig = {
  apiKey: "YOUR_WEB_API_KEY",  // ← Replace this
  authDomain: "dia-plus-7c78c.firebaseapp.com",
  projectId: "dia-plus-7c78c",
  storageBucket: "dia-plus-7c78c.appspot.com",
  messagingSenderId: "284015189329",
  appId: "YOUR_WEB_APP_ID"  // ← Replace this
};
```

**Replace with:**
```javascript
var firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",  // ← Your actual web API key
  authDomain: "dia-plus-7c78c.firebaseapp.com",
  projectId: "dia-plus-7c78c",
  storageBucket: "dia-plus-7c78c.appspot.com",
  messagingSenderId: "284015189329",
  appId: "1:284015189329:web:xxxxxxxxxxxxx"  // ← Your actual web app ID
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
```

**Also remove the `if` check** - change line 60-64 from:
```javascript
if (firebaseConfig.apiKey !== "YOUR_WEB_API_KEY" && firebaseConfig.appId !== "YOUR_WEB_APP_ID") {
  firebase.initializeApp(firebaseConfig);
} else {
  console.warn("Firebase web config not set...");
}
```

**To:**
```javascript
firebase.initializeApp(firebaseConfig);
```

---

### Step 5: Test

1. **Stop the app** if running
2. **Clean build** (recommended):
   ```bash
   flutter clean
   flutter pub get
   ```
3. **Run on web**:
   ```bash
   flutter run -d chrome
   ```
   Or for Edge:
   ```bash
   flutter run -d edge
   ```
4. **Test login**:
   - Use the **same email/password** you used on mobile
   - Should work now! ✅

---

## 🔍 How to Find Web Config in Firebase Console

### Method 1: Project Overview

1. Firebase Console → **Project Overview**
2. Scroll to **"Your apps"** section
3. Find the **Web app** (has `</>` icon)
4. Click the **gear icon** ⚙️ next to it
5. Scroll to **"SDK setup and configuration"**
6. Copy `apiKey` and `appId` from the config

### Method 2: Project Settings

1. Firebase Console → **Project Settings** (gear icon ⚙️)
2. Scroll to **"Your apps"** section
3. Find **Web app**
4. Click **"SDK setup and configuration"**
5. Copy `apiKey` and `appId`

---

## ✅ Verification Checklist

- [ ] Web app registered in Firebase Console
- [ ] Copied `apiKey` from Firebase Console (Web app)
- [ ] Copied `appId` from Firebase Console (Web app)
- [ ] Updated `lib/firebase_options.dart` with real values
- [ ] Updated `web/index.html` with real values (optional)
- [ ] Removed placeholder checks in `index.html`
- [ ] Ran `flutter clean` and `flutter pub get`
- [ ] Tested login on web browser

---

## 🐛 Troubleshooting

### Problem: Still can't login on web

**Check:**
1. Open browser **Developer Tools** (F12)
2. Go to **Console** tab
3. Look for Firebase errors
4. Common errors:
   - `Firebase: Error (auth/invalid-api-key)` → Wrong API key
   - `Firebase: No Firebase App '[DEFAULT]' has been created` → Firebase not initialized
   - `Firebase: Error (auth/operation-not-allowed)` → Email/Password not enabled

### Problem: "Invalid API key" error

**Solution:**
- Make sure you're using the **Web app** API key, not Android API key
- Web API key is different from Android API key
- Both are in the same Firebase project but different apps

### Problem: Firebase initializes but login still fails

**Check:**
1. Firebase Console → **Authentication** → **Sign-in method**
2. Ensure **Email/Password** is **Enabled**
3. Check browser console for specific error messages
4. Verify you're using the correct email/password

### Problem: Works on Chrome but not Edge

**Solution:**
- Clear Edge browser cache
- Try incognito/private mode
- Check Edge console for errors (F12)

---

## 📝 Quick Summary

| What | Where | Status |
|------|-------|--------|
| **Android Config** | `android/app/google-services.json` | ✅ Working |
| **Web Config** | `lib/firebase_options.dart` + `web/index.html` | ❌ Needs setup |

**Action Required:**
1. Get web `apiKey` and `appId` from Firebase Console
2. Update `lib/firebase_options.dart` (line 26-27)
3. Update `web/index.html` (line 51, 56)
4. Test login on web

---

## 🎯 Why This Happens

- **Android** uses `google-services.json` → ✅ Already configured
- **Web** uses `firebase_options.dart` → ❌ Still has placeholders
- **Same Firebase project**, but **different apps** (Android vs Web)
- Each platform needs its own configuration

After fixing, both mobile and web will use the **same Firebase project** and **same user database**, so you can login with the same email on both! 🎉
