# 🔥 Firebase Security Setup Guide

## Overview
This guide will help you secure your Firebase project for the TourVN mobile app.

**Project**: `tourvn-mobile-2026`

## ⚠️ CRITICAL: API Key Restrictions

GitHub has detected Firebase API keys in the repository. This is **NORMAL and SAFE** for mobile apps, but you **MUST** configure API restrictions.

### Step 1: Configure Android API Key

**API Key**: `AIzaSyCvTjh-wHQ692CduXxAnST4D3GZQ7sNvl8`

1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Select project: **tourvn-mobile-2026**
3. Go to **APIs & Services > Credentials**
4. Find the Android API key (ends with `...sNvl8`)
5. Click **Edit**
6. Under **Application restrictions**:
   - Select **Android apps**
   - Click **+ Add package name and fingerprint**
   - Package name: `com.tourvn.tourVn`

7. **Add SHA-1 fingerprints**:
   
   **Debug (Development)**:
   ```bash
   # Get debug SHA-1
   cd android
   ./gradlew signingReport
   # Look for SHA-1 under "Variant: debug"
   ```

   **Release (Production)**:
   ```bash
   # Get release SHA-1 from your keystore
   keytool -list -v -keystore your_release_keystore.jks -alias your_key_alias
   ```

8. Under **API restrictions**:
   - Select **Restrict key**
   - Enable these APIs:
     - ✅ Firebase Authentication API
     - ✅ Cloud Firestore API
     - ✅ Firebase Storage API
     - ✅ Firebase Cloud Messaging API
     - ✅ Firebase Installations API

9. Click **Save**

### Step 2: Configure iOS API Key

**API Key**: `AIzaSyCCh8ASr_Ok5Ff2NHd_SljHhH5RvB2XPho`

1. In the same **Credentials** page
2. Find the iOS API key (ends with `...XPho`)
3. Click **Edit**
4. Under **Application restrictions**:
   - Select **iOS apps**
   - Click **+ Add an item**
   - Bundle ID: `com.tourvn.tourVn`

5. Under **API restrictions**:
   - Enable the same APIs as Android (see above)

6. Click **Save**

### Step 3: Verify Configuration

Test that your app still works after restrictions:

```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# If you get authentication errors, verify:
# - Package name matches
# - Bundle ID matches
# - SHA-1 fingerprints are correct
```

## 🛡️ Firebase Security Rules

### Firestore Rules

Update your Firestore security rules:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select **tourvn-mobile-2026**
3. Go to **Firestore Database > Rules**
4. Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Default: Require authentication
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Tours collection (public read, admin write)
    match /tours/{tourId} {
      allow read: if true;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Bookings (user-specific)
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
  }
}
```

5. Click **Publish**

### Storage Rules

1. Go to **Storage > Rules**
2. Replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId &&
                     request.resource.size < 5 * 1024 * 1024 && // 5MB max
                     request.resource.contentType.matches('image/.*');
    }
    
    // Tour images (admin only)
    match /tours/{tourId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

3. Click **Publish**

## 🔐 Firebase App Check (Recommended)

App Check prevents unauthorized access to your Firebase resources.

### Installation

1. Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_app_check: ^0.3.3+2
```

2. Run:
```bash
flutter pub get
```

3. Update `lib/main.dart`:
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );
  
  runApp(const MyApp());
}
```

4. Enable in Firebase Console:
   - Go to **App Check**
   - Register your apps
   - Enable enforcement for Firestore, Storage, etc.

## 📊 Monitoring & Auditing

### 1. Monitor Usage
- Firebase Console > **Usage and billing**
- Set up billing alerts
- Monitor for suspicious spikes

### 2. Review Audit Logs
- Go to **Cloud Logging** in Google Cloud Console
- Filter by Firebase services
- Look for unusual patterns

### 3. Set Up Alerts
```bash
# Example: Alert on high read operations
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High Firestore Reads" \
  --condition-display-name="Read count" \
  --condition-threshold-value=10000 \
  --condition-threshold-duration=300s
```

## ✅ Security Checklist

After following this guide, verify:

- [ ] **API restrictions configured** for both Android and iOS keys
- [ ] **SHA-1 fingerprints added** for Android (debug + release)
- [ ] **Bundle ID verified** for iOS
- [ ] **Firestore security rules** published and tested
- [ ] **Storage security rules** published and tested
- [ ] **App Check enabled** (recommended)
- [ ] **Authentication configured** (Firebase Auth)
- [ ] **Billing alerts set up**
- [ ] **Regular monitoring scheduled**

## 🚨 Responding to GitHub Alerts

### Why GitHub Flagged This
GitHub's secret scanning detected Firebase API keys. This is a **false positive** for mobile apps.

### What to Do
1. **Verify API restrictions** are configured (Steps 1-2 above)
2. **Dismiss the GitHub alert**:
   - Go to **Security > Secret scanning alerts** in GitHub
   - Click on each alert
   - Select **Dismiss alert**
   - Reason: "Used in tests" or "Won't fix"
   - Comment: "Firebase mobile API key - safe when restricted. Restrictions configured per FIREBASE_SECURITY_SETUP.md"

### When to Rotate Keys
Only rotate if:
- Keys were exposed **before** restrictions were applied
- You detect suspicious activity in Firebase Console
- Keys were accidentally used in backend code

**How to rotate**:
```bash
# Regenerate Firebase config
flutterfire configure

# Or manually create new apps in Firebase Console
# and update google-services.json / GoogleService-Info.plist
```

## 📚 Additional Resources

- [Firebase Security Rules Guide](https://firebase.google.com/docs/rules)
- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
- [Flutter Firebase Security](https://firebase.flutter.dev/docs/overview#security)

## 🆘 Troubleshooting

### "API Key not found" error
- Verify API restrictions allow your app's package/bundle ID
- Check SHA-1 fingerprints match

### "Permission denied" in Firestore
- Review security rules
- Ensure user is authenticated
- Check user's role/permissions

### "App Check token invalid"
- Ensure App Check is initialized before Firebase
- Verify app is registered in Firebase Console App Check

---
**Last Updated**: 2026-01-26  
**Next Review**: Before production release
