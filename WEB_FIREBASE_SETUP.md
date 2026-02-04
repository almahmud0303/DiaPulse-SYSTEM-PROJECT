# Firebase Web Setup Guide

## 🔍 Problem: Firebase Not Working on Web

When you run `flutter run -d chrome` or build for web, Firebase authentication doesn't work because:
- ✅ Android uses `google-services.json` (already configured)
- ❌ Web needs Firebase JavaScript SDK configuration in `web/index.html`

---

## ✅ Solution: Configure Firebase for Web

### Step 1: Register Web App in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **dia-plus-7c78c** (or your project name)
3. Click **Project Overview** (home icon)
4. Click the **Web icon** (`</>`) or **"Add app"** → **Web**
5. Fill in:
   - **App nickname**: `Dia Plus Web` (or any name)
   - **Firebase Hosting**: Leave unchecked (unless you're using hosting)
6. Click **"Register app"**

---

### Step 2: Copy Firebase Configuration

After registering, Firebase will show you a configuration object like this:

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

**Copy this entire `firebaseConfig` object** - you'll need it in the next step.

---

### Step 3: Update `web/index.html`

Open `web/index.html` and find this section:

```html
<script>
  // Firebase configuration will be initialized here
  var firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  
  // Initialize Firebase only if config is valid
  if (firebaseConfig.apiKey !== "YOUR_API_KEY") {
    firebase.initializeApp(firebaseConfig);
  }
</script>
```

**Replace the placeholder values** with your actual Firebase config:

```html
<script>
  var firebaseConfig = {
    apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",  // ← Your actual API key
    authDomain: "dia-plus-7c78c.firebaseapp.com",    // ← Your auth domain
    projectId: "dia-plus-7c78c",                      // ← Your project ID
    storageBucket: "dia-plus-7c78c.appspot.com",     // ← Your storage bucket
    messagingSenderId: "284015189329",                // ← Your sender ID
    appId: "1:284015189329:web:xxxxxxxxxxxxx"        // ← Your web app ID
  };
  
  // Initialize Firebase
  firebase.initializeApp(firebaseConfig);
</script>
```

**Important:** Remove the `if` check after you add real values, or Firebase won't initialize.

---

### Step 4: Update `lib/firebase_options.dart` (Optional but Recommended)

Open `lib/firebase_options.dart` and update the web section with your actual values:

```dart
if (kIsWeb) {
  return const FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',                    // ← From Firebase Console
    appId: 'YOUR_WEB_APP_ID',                       // ← From Firebase Console
    messagingSenderId: '284015189329',              // ← Your sender ID
    projectId: 'dia-plus-7c78c',                    // ← Your project ID
    authDomain: 'dia-plus-7c78c.firebaseapp.com',   // ← Your auth domain
    storageBucket: 'dia-plus-7c78c.appspot.com',    // ← Your storage bucket
  );
}
```

---

### Step 5: Test Web Build

1. **Stop any running app**
2. **Run for web**:
   ```bash
   flutter run -d chrome
   ```
   Or:
   ```bash
   flutter run -d web-server
   ```

3. **Test the app**:
   - Open the app in browser
   - Click **"Register"**
   - Fill in the form and create an account
   - Should work now! ✅

---

## 🔧 Quick Reference: Where to Find Firebase Config

### In Firebase Console:

1. **Project Overview** → Click **Web app** icon (`</>`)
2. Or: **Project Settings** (gear icon) → **Your apps** → **Web app**
3. Look for **"SDK setup and configuration"** section
4. Copy the `firebaseConfig` object

### Your Current Project Info (from google-services.json):

- **Project ID**: `dia-plus-7c78c`
- **Project Number**: `284015189329`
- **Storage Bucket**: `dia-plus-7c78c.firebasestorage.app`

**Note:** Web config will have different values for `apiKey` and `appId` than Android.

---

## ✅ Verification Checklist

- [ ] Web app registered in Firebase Console
- [ ] `firebaseConfig` copied from Firebase Console
- [ ] `web/index.html` updated with real Firebase config
- [ ] `lib/firebase_options.dart` updated (optional)
- [ ] App runs on web: `flutter run -d chrome`
- [ ] Registration/Login works on web

---

## 🐛 Troubleshooting

### Problem: "Firebase: No Firebase App '[DEFAULT]' has been created"

**Solution:**
- Check that `firebase.initializeApp(firebaseConfig)` is called in `index.html`
- Verify Firebase SDK scripts are loaded before initialization
- Check browser console for JavaScript errors

### Problem: "Firebase: Error (auth/invalid-api-key)"

**Solution:**
- Verify API key in `index.html` matches Firebase Console
- Make sure you're using the **Web app** API key, not Android API key
- Check that Authentication is enabled in Firebase Console

### Problem: "Firebase: Error (auth/operation-not-allowed)"

**Solution:**
- Go to Firebase Console → **Authentication** → **Sign-in method**
- Ensure **Email/Password** is enabled

### Problem: App works on Android but not web

**Solution:**
- Android uses `google-services.json` ✅
- Web uses `web/index.html` config ❌ (needs to be set up)
- They are **separate configurations** - both need to be done

---

## 📝 Summary

| Platform | Config File | Location |
|----------|-------------|----------|
| **Android** | `google-services.json` | `android/app/` ✅ Done |
| **iOS** | `GoogleService-Info.plist` | `ios/Runner/` (if needed) |
| **Web** | `firebaseConfig` in `index.html` | `web/index.html` ⚠️ Needs setup |

---

## 🚀 After Setup

Once configured, your app will work on:
- ✅ **Android** (already working)
- ✅ **Web** (after following this guide)
- ⚠️ **iOS** (if you add `GoogleService-Info.plist`)

All platforms will share the same Firebase project and user database!
