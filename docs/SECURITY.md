# 🔐 Security Policy - TourVN Mobile App

## Firebase API Keys in Mobile Apps

### Important Notice
The API keys visible in `lib/firebase_options.dart` are **Firebase API keys for mobile applications**. Unlike backend API secrets, these keys are:

- ✅ **Designed to be embedded** in mobile apps
- ✅ **Safe to be public** when properly configured
- ✅ **Protected by Firebase security rules** and App Check

### Why These Keys Are Safe

Firebase mobile API keys work differently from traditional API secrets:

1. **Client-side authentication**: These keys identify your Firebase project, not authenticate access
2. **Protection layers**:
   - Firebase Security Rules (Firestore, Storage, RTDB)
   - Firebase App Check (prevents abuse from non-app clients)
   - API restrictions (configured in Google Cloud Console)

### Security Best Practices Implemented

#### ✅ 1. Firebase Security Rules
Protect your backend data with proper security rules:

```javascript
// Firestore Rules Example
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### ✅ 2. API Restrictions (Required)

**CRITICAL**: Configure API restrictions in Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project: `tourvn-mobile-2026`
3. Navigate to **APIs & Services > Credentials**
4. For each API key:
   - **Android Key** (`AIzaSyCvTjh-wHQ692CduXxAnST4D3GZQ7sNvl8`):
     - Application restrictions: Android apps
     - Add package name: `com.tourvn.tourVn`
     - Add SHA-1 certificate fingerprints
   - **iOS Key** (`AIzaSyCCh8ASr_Ok5Ff2NHd_SljHhH5RvB2XPho`):
     - Application restrictions: iOS apps
     - Add bundle ID: `com.tourvn.tourVn`

#### ✅ 3. Firebase App Check (Recommended)

Enable App Check to prevent API abuse:

```bash
# Add to pubspec.yaml
firebase_app_check: ^0.3.3+2

# Initialize in main.dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

#### ✅ 4. Environment-based Configuration (Optional Enhancement)

For additional security layers, you can use environment variables:

```dart
// Use --dart-define during build
flutter build apk --dart-define=FIREBASE_API_KEY=your_key
```

## Action Items

### 🔴 REQUIRED (Do This Now):
1. [ ] **Configure API restrictions** in Google Cloud Console (see section 2 above)
2. [ ] **Review Firebase Security Rules** for Firestore and Storage
3. [ ] **Add SHA-1/SHA-256** fingerprints for Android app
4. [ ] **Test authentication** after restrictions are applied

### 🟡 RECOMMENDED (Do This Soon):
5. [ ] **Enable Firebase App Check** to prevent abuse
6. [ ] **Set up Firebase Authentication** for user management
7. [ ] **Monitor usage** in Firebase Console for suspicious activity
8. [ ] **Review audit logs** regularly

### 🟢 OPTIONAL (Best Practices):
9. [ ] Use `flutter_dotenv` for additional config management
10. [ ] Set up Firebase Performance Monitoring
11. [ ] Implement certificate pinning for production

## Responding to the GitHub Alert

GitHub's secret scanning detected the Firebase API keys. Here's what to do:

### Option 1: Dismiss the Alert (Recommended)
Since Firebase mobile API keys are designed to be public:
1. Go to repository **Security > Secret scanning alerts**
2. For each alert, click **Dismiss**
3. Reason: "Used in tests" or "False positive" (GitHub doesn't have "Safe mobile API key" option)
4. Add comment: "Firebase mobile API key - safe when properly restricted. API restrictions configured in GCP Console."

### Option 2: Rotate Keys (If Compromised)
If you believe the keys were exposed before restrictions were applied:
1. Create new Android/iOS apps in Firebase Console
2. Update `google-services.json` and `GoogleService-Info.plist`
3. Run `flutterfire configure` to regenerate `firebase_options.dart`
4. Delete old apps from Firebase Console

## Additional Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
- [API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
- [Flutter Firebase Security](https://firebase.flutter.dev/docs/overview#security)

## Contact

For security concerns, contact: [Your Security Email]

---
**Last Updated**: 2026-01-26
**Project**: TourVN Mobile App
**Firebase Project**: tourvn-mobile-2026
