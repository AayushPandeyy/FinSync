# Google Sign-In Implementation Guide

This document outlines the steps required to set up Google Sign-In with Firebase in the FinSync application.

## Overview

Google Sign-In has been implemented in the following files:

- `lib/service/AuthFirestoreService.dart` - Added `signInWithGoogle()` and `signUpWithGoogle()` methods
- `lib/pages/common/auth/LoginPage.dart` - Added Google sign-in button to the UI
- `pubspec.yaml` - Added `google_sign_in: ^6.2.1` dependency

## Implementation Details

### AuthFirestoreService Methods

#### 1. `signUpWithGoogle()`

Creates a new account using Google credentials and saves user data to Firestore.

- Retrieves user's display name and email from Google account
- Saves user info to Firestore `Users` collection
- Returns `UserCredential` on success

#### 2. `signInWithGoogle()`

Signs in existing user or creates new account if user doesn't exist in Firestore.

- Automatically adds user to Firestore if they don't exist
- Returns `UserCredential` on success

#### 3. Updated `logout()`

Now signs out from both Google and Firebase Auth.

### User Data Saved to Firestore

When a user signs in with Google, the following data is saved to the `Users` collection:

```dart
{
  'uid': user_id,
  'email': user_email,
  'username': display_name_from_google,
  'phoneNumber': '', // Empty for Google sign-in
  'income': 0,
  'expense': 0,
  'totalBalance': 0,
  'preferredCurrency': 'NPR',
}
```

## Platform-Specific Setup

### Android Setup

1. **Get SHA-1 Fingerprint**

   ```bash
   cd android
   ./gradlew signingReport
   ```

   Copy the SHA-1 value from the output.

2. **Add to Firebase Console**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project (finance-tracker-e132f)
   - Go to Project Settings → Your apps → Android app
   - Under "SHA certificate fingerprints", add the SHA-1 fingerprint

3. **Update google-services.json**
   - Download the updated `google-services.json` from Firebase Console
   - Replace the file at `android/app/google-services.json`

4. **Android Manifest** (should already be configured by google_sign_in package)
   - Verify `AndroidManifest.xml` contains:
     ```xml
     <uses-permission android:name="android.permission.INTERNET" />
     ```

### iOS Setup

1. **Get Bundle ID**
   - Your iOS bundle ID is: `com.example.financeTracker` (update if different)

2. **Add to Firebase Console**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project (finance-tracker-e132f)
   - Go to Project Settings → Your apps → iOS app
   - Ensure the bundle ID is registered

3. **Configure iOS Build Settings**
   - The `google_sign_in` package should automatically configure most settings
   - Verify `ios/Runner.xcodeproj/project.pbxproj` includes proper schemes

4. **Info.plist Setup**
   - Add to `ios/Runner/Info.plist`:
     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleTypeRole</key>
         <string>Editor</string>
         <key>CFBundleURLName</key>
         <string>com.google.Firebase.auth</string>
         <key>CFBundleURLSchemes</key>
         <array>
           <string>REVERSED_CLIENT_ID</string>
         </array>
       </dict>
     </array>
     ```
   - Get the REVERSED_CLIENT_ID from your `GoogleService-Info.plist` file

### Web Setup (if needed)

1. **OAuth Consent Screen**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Go to APIs & Services → OAuth Consent Screen
   - Ensure the app is configured

2. **Web Application Credentials**
   - Create Web application credentials in Google Cloud Console
   - Add authorized JavaScript origins and redirect URIs

## Testing the Implementation

### To Test Google Sign-In:

1. **Run the app**

   ```bash
   flutter pub get
   flutter run
   ```

2. **On the LoginPage**
   - Click "Sign in with Google" button
   - Select your Google account
   - User should be created in Firestore automatically
   - App should navigate to HomePage

3. **Verify in Firebase Console**
   - Go to Firebase Console → Firestore Database
   - Check the `Users` collection for your user document with email and username

## Troubleshooting

### Google Sign-In Returns Null

- **Android**: Check SHA-1 fingerprint is added to Firebase Console
- **iOS**: Check Bundle ID is correct and Info.plist is updated
- **General**: Ensure Google Sign-In API is enabled in Google Cloud Console

### User Not Appearing in Firestore

- Check Firestore security rules allow read/write for authenticated users
- Verify email is being saved correctly in AuthFirestoreService

### "Operation not allowed" Error

- Ensure Google Sign-In is enabled in Firebase Console
  - Go to Authentication → Sign-in method → Enable Google

### Compilation Errors

- Run `flutter pub get` to ensure all dependencies are installed
- Run `flutter clean` and rebuild if needed

## Firebase Rules for Google Sign-In Users

Add to your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own user document
    match /Users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    // Allow authenticated users to read/write their own subcollections
    match /Transactions/{uid}/transaction/{doc=**} {
      allow read, write: if request.auth.uid == uid;
    }

    match /Budgets/{uid}/budget/{doc=**} {
      allow read, write: if request.auth.uid == uid;
    }

    // Add similar rules for other subcollections
  }
}
```

## Security Considerations

1. **Email Verification**: Google sign-in doesn't require email verification (it's already verified by Google)
2. **Phone Number**: Not provided by Google Sign-In - users can update this manually in their profile
3. **Data Privacy**: User data is securely stored in Firestore with proper access controls

## References

- [Google Sign-In Flutter Documentation](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication Guide](https://firebase.google.com/docs/auth)
- [Firebase Setup for Flutter](https://firebase.flutter.dev/)
