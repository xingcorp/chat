# Firebase Setup Guide — Sharitek Office Chat

## 🚨 SECURITY: API Keys Are NOT Committed to Git

Firebase API keys are injected at **build time** via `--dart-define`.
**NEVER** hardcode API keys in source code.

---

## Quick Start

### 1. Copy the example env file

```bash
cd flutter_chat_app

# For staging
cp .env.example .env.staging

# For production
cp .env.example .env.production
```

### 2. Fill in your Firebase credentials

Get values from [Firebase Console](https://console.firebase.google.com):
- Go to **Project Settings** → **General** → **Your apps**
- Copy the config values for each platform (Web, Android, iOS)

Edit `.env.staging` (or `.env.production`):

```env
FLAVOR=staging
API_BASE_URL=https://api-staging.oxii.chat
SOCKET_URL=wss://ws-staging.oxii.chat

FIREBASE_PROJECT_ID=your-project-id
FIREBASE_MESSAGING_SENDER_ID=000000000000
FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app

FIREBASE_WEB_API_KEY=AIzaSy...
FIREBASE_WEB_APP_ID=1:000000000000:web:...
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_MEASUREMENT_ID=G-...

FIREBASE_ANDROID_API_KEY=AIzaSy...
FIREBASE_ANDROID_APP_ID=1:000000000000:android:...

FIREBASE_IOS_API_KEY=AIzaSy...
FIREBASE_IOS_APP_ID=1:000000000000:ios:...
FIREBASE_IOS_BUNDLE_ID=com.oxii.chat
```

### 3. Run the app

```bash
# Staging (recommended for development)
flutter run --flavor staging \
  --target lib/main_staging.dart \
  --dart-define-from-file=.env.staging

# Production
flutter run --flavor production \
  --target lib/main_production.dart \
  --dart-define-from-file=.env.production

# Auto-detect flavor from env file
flutter run --dart-define-from-file=.env.staging
```

### 4. Build for release

```bash
# Android APK
flutter build apk --flavor production \
  --dart-define-from-file=.env.production --release

# Android App Bundle
flutter build appbundle --flavor production \
  --dart-define-from-file=.env.production --release

# iOS
flutter build ios --flavor production \
  --dart-define-from-file=.env.production --release
```

---

## Android: `google-services.json`

The `google-services.json` file is **NOT committed to git**.
You must place it manually:

```bash
# Staging
flutter_chat_app/android/app/src/staging/google-services.json

# Production
flutter_chat_app/android/app/src/production/google-services.json

# Default (used when no flavor-specific file exists)
flutter_chat_app/android/app/google-services.json
```

Download from Firebase Console:
1. Go to **Project Settings** → **General**
2. Find your Android app → click **google-services.json** download button
3. Place in the appropriate directory above

---

## iOS: `GoogleService-Info.plist`

The `GoogleService-Info.plist` file is **NOT committed to git**.
Place it at:

```
flutter_chat_app/ios/Runner/GoogleService-Info.plist
```

Download from Firebase Console:
1. Go to **Project Settings** → **General**
2. Find your iOS app → click **GoogleService-Info.plist** download button

---

## CI/CD Setup

### GitHub Actions

Store Firebase credentials as **GitHub Secrets**, then inject at build time:

```yaml
# .github/workflows/build.yml
jobs:
  build:
    steps:
      - name: Create env file
        run: |
          cat > flutter_chat_app/.env.production << EOF
          FLAVOR=production
          API_BASE_URL=${{ secrets.API_BASE_URL }}
          SOCKET_URL=${{ secrets.SOCKET_URL }}
          FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
          FIREBASE_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_MESSAGING_SENDER_ID }}
          FIREBASE_STORAGE_BUCKET=${{ secrets.FIREBASE_STORAGE_BUCKET }}
          FIREBASE_WEB_API_KEY=${{ secrets.FIREBASE_WEB_API_KEY }}
          FIREBASE_WEB_APP_ID=${{ secrets.FIREBASE_WEB_APP_ID }}
          FIREBASE_AUTH_DOMAIN=${{ secrets.FIREBASE_AUTH_DOMAIN }}
          FIREBASE_MEASUREMENT_ID=${{ secrets.FIREBASE_MEASUREMENT_ID }}
          FIREBASE_ANDROID_API_KEY=${{ secrets.FIREBASE_ANDROID_API_KEY }}
          FIREBASE_ANDROID_APP_ID=${{ secrets.FIREBASE_ANDROID_APP_ID }}
          FIREBASE_IOS_API_KEY=${{ secrets.FIREBASE_IOS_API_KEY }}
          FIREBASE_IOS_APP_ID=${{ secrets.FIREBASE_IOS_APP_ID }}
          FIREBASE_IOS_BUNDLE_ID=${{ secrets.FIREBASE_IOS_BUNDLE_ID }}
          EOF

      - name: Decode google-services.json
        run: |
          echo "${{ secrets.GOOGLE_SERVICES_JSON_PRODUCTION }}" | base64 -d \
            > flutter_chat_app/android/app/src/production/google-services.json

      - name: Build
        run: |
          cd flutter_chat_app
          flutter build apk --flavor production \
            --dart-define-from-file=.env.production --release
```

---

## Troubleshooting

### "Missing required Firebase --dart-define variables"

You forgot to pass `--dart-define-from-file`. Run with:
```bash
flutter run --dart-define-from-file=.env.staging
```

### "Firebase app not found"

Check that:
1. `.env.staging` has valid, non-empty values
2. `FIREBASE_PROJECT_ID` matches your Firebase Console project ID
3. Platform-specific keys (Android/iOS/Web) are set for your target platform

### "google-services.json not found"

Download from Firebase Console and place in:
- `android/app/src/staging/google-services.json` (for staging)
- `android/app/src/production/google-services.json` (for production)

---

## Files Overview

| File | Committed? | Purpose |
|------|-----------|---------|
| `.env.example` | ✅ Yes | Template with placeholder values |
| `.env.staging` | ❌ No | Your staging credentials (local only) |
| `.env.production` | ❌ No | Your production credentials (local only) |
| `lib/firebase_options_staging.dart` | ✅ Yes | Reads `--dart-define` at compile time |
| `lib/firebase_options_production.dart` | ✅ Yes | Reads `--dart-define` at compile time |
| `android/app/src/*/google-services.json` | ❌ No | Android Firebase config (local only) |
| `ios/Runner/GoogleService-Info.plist` | ❌ No | iOS Firebase config (local only) |
