# 🏗️ Multi-Flavor Setup Guide

## Overview

OXII Chat sử dụng multi-flavor architecture để support nhiều environments:
- **Staging**: Development và testing environment
- **Production**: Live production environment

## 🎯 Quick Start

### Build Commands

```bash
# Staging builds
flutter run --flavor staging --target lib/main_staging.dart
flutter build apk --flavor staging --target lib/main_staging.dart

# Production builds
flutter run --flavor production --target lib/main_production.dart
flutter build apk --flavor production --target lib/main_production.dart
```

### Using Build Scripts

```bash
# Build staging
./scripts/build_staging.sh android
./scripts/build_staging.sh ios
./scripts/build_staging.sh web
./scripts/build_staging.sh all

# Build production
./scripts/build_production.sh android
./scripts/build_production.sh ios
./scripts/build_production.sh web
./scripts/build_production.sh all
```

## 🏗️ Architecture

### Flavor Configuration

```
lib/
├── main.dart                    # Default entry point
├── main_staging.dart           # Staging entry point
├── main_production.dart        # Production entry point
└── core/
    └── config/
        ├── flavor_config.dart      # Flavor configuration
        ├── environment_manager.dart # Environment management
        ├── firebase_config.dart    # Firebase per flavor
        └── app_identity.dart       # App identity per flavor
```

### Environment Files

```
.env.staging        # Staging environment variables
.env.production     # Production environment variables
```

### Build Configuration

```
android/
├── app/
│   ├── build.gradle           # Flavor configuration
│   └── src/
│       ├── staging/           # Staging-specific files
│       └── production/        # Production-specific files
```

## 🔧 Configuration Details

### Flavor Differences

| Feature | Staging | Production |
|---------|---------|------------|
| **App Name** | OXII Chat STG | OXII Chat |
| **Package ID** | com.oxii.chat.staging | com.oxii.chat |
| **API URL** | api-staging.oxii.chat | api.oxii.chat |
| **Firebase** | oxii-chat-staging | oxii-chat-prod |
| **Debug Tools** | ✅ Enabled | ❌ Disabled |
| **Mock Data** | ✅ Enabled | ❌ Disabled |
| **Obfuscation** | ❌ Disabled | ✅ Enabled |
| **App Icon** | 🟠 Orange | 🔵 Blue |

### Environment Variables

#### Staging (.env.staging)
```env
FLAVOR=staging
API_BASE_URL=https://api-staging.oxii.chat
WEBSOCKET_URL=wss://ws-staging.oxii.chat
FIREBASE_PROJECT_ID=oxii-chat-staging
ENABLE_DEBUG_TOOLS=true
ENABLE_MOCK_DATA=true
LOG_LEVEL=DEBUG
```

#### Production (.env.production)
```env
FLAVOR=production
API_BASE_URL=https://api.oxii.chat
WEBSOCKET_URL=wss://ws.oxii.chat
FIREBASE_PROJECT_ID=oxii-chat-prod
ENABLE_DEBUG_TOOLS=false
ENABLE_MOCK_DATA=false
LOG_LEVEL=ERROR
```

## 🚀 CI/CD Pipeline

### GitHub Actions Workflows

1. **PR Check** (`.github/workflows/pr-check.yml`)
   - Code quality checks
   - Build verification
   - Security scanning
   - Performance analysis

2. **Staging Build** (`.github/workflows/staging-build.yml`)
   - Automated staging builds
   - Firebase App Distribution
   - Integration testing

3. **Production Release** (`.github/workflows/production-release.yml`)
   - Security gates
   - Production builds
   - Google Play Console deployment
   - Release notifications

### Required Secrets

```yaml
# Firebase
FIREBASE_SERVICE_ACCOUNT
FIREBASE_STAGING_APP_ID

# Android Signing
ANDROID_KEYSTORE
ANDROID_KEY_ALIAS
ANDROID_STORE_PASSWORD
ANDROID_KEY_PASSWORD

# Google Play
GOOGLE_PLAY_SERVICE_ACCOUNT

# Notifications
SLACK_WEBHOOK_URL
EMAIL_USERNAME
EMAIL_PASSWORD
```

## 📱 Platform-Specific Setup

### Android

#### Flavor Configuration (android/app/build.gradle)
```gradle
flavorDimensions "environment"

productFlavors {
    staging {
        dimension "environment"
        applicationIdSuffix ".staging"
        versionNameSuffix "-staging"
        buildConfigField "String", "FLAVOR", '"staging"'
        resValue "string", "app_name", "OXII Chat STG"
    }
    
    production {
        dimension "environment"
        buildConfigField "String", "FLAVOR", '"production"'
        resValue "string", "app_name", "OXII Chat"
    }
}
```

#### Manifest Files
- `android/app/src/staging/AndroidManifest.xml`
- `android/app/src/production/AndroidManifest.xml`

### iOS

#### Schemes
- OXII Chat Staging
- OXII Chat Production

#### Info.plist Files
- `ios/Runner/Info-staging.plist`
- `ios/Runner/Info-production.plist`

## 🎨 Assets & Branding

### App Icons

```
assets/icons/
├── app_icon_staging.png        # Orange staging icon
├── app_icon_production.png     # Blue production icon
├── app_icon_foreground_staging.png
└── app_icon_foreground_production.png
```

### Splash Screens

```
assets/splash/
├── splash_staging.png
├── splash_production.png
├── splash_staging_dark.png
└── splash_production_dark.png
```

### Icon Generation

```bash
# Generate staging icons
flutter packages pub run flutter_launcher_icons:main -f flutter_launcher_icons-staging.yaml

# Generate production icons
flutter packages pub run flutter_launcher_icons:main -f flutter_launcher_icons-production.yaml
```

### Splash Screen Generation

```bash
# Generate staging splash
flutter packages pub run flutter_native_splash:create --path=flutter_native_splash-staging.yaml

# Generate production splash
flutter packages pub run flutter_native_splash:create --path=flutter_native_splash-production.yaml
```

## 🧪 Testing

### Flavor-Specific Tests

```
test/
├── staging/
│   ├── staging_integration_test.dart
│   └── staging_unit_test.dart
└── production/
    ├── production_integration_test.dart
    └── production_unit_test.dart
```

### Running Tests

```bash
# Run staging tests
flutter test test/staging/ --dart-define=FLAVOR=staging

# Run production tests
flutter test test/production/ --dart-define=FLAVOR=production

# Run all tests
flutter test --coverage
```

## 🔧 Development Workflow

### 1. Feature Development
```bash
# Work on feature branch
git checkout -b feature/new-feature

# Test with staging
flutter run --flavor staging --target lib/main_staging.dart

# Create PR
git push origin feature/new-feature
```

### 2. Staging Deployment
```bash
# Merge to develop branch
git checkout develop
git merge feature/new-feature

# Automatic staging build via GitHub Actions
# Deploy to Firebase App Distribution
```

### 3. Production Release
```bash
# Create release tag
git tag v1.0.0
git push origin v1.0.0

# Automatic production build via GitHub Actions
# Deploy to Google Play Console
```

## 🚨 Troubleshooting

### Common Issues

1. **Flavor not found**
   ```bash
   # Ensure flavor is defined in android/app/build.gradle
   # Check iOS scheme configuration
   ```

2. **Environment variables not loaded**
   ```bash
   # Verify .env.staging and .env.production files exist
   # Check dart-define-from-file parameter
   ```

3. **Firebase configuration mismatch**
   ```bash
   # Verify Firebase project IDs in environment files
   # Check google-services.json files
   ```

4. **Build script permissions**
   ```bash
   chmod +x scripts/build_staging.sh
   chmod +x scripts/build_production.sh
   ```

### Debug Commands

```bash
# Check current flavor configuration
flutter run --flavor staging --target lib/main_staging.dart --verbose

# Analyze build configuration
flutter build apk --flavor staging --target lib/main_staging.dart --analyze-size

# Check environment variables
flutter run --dart-define-from-file=.env.staging --verbose
```

## 📚 Best Practices

1. **Always test both flavors** before releasing
2. **Keep environment files in sync** with actual configurations
3. **Use feature flags** for gradual rollouts
4. **Monitor both environments** separately
5. **Maintain separate Firebase projects** for isolation
6. **Use semantic versioning** for releases
7. **Document configuration changes** in this file

## 🔗 Related Documentation

- [Firebase Setup Guide](FIREBASE_SETUP.md)
- [CI/CD Pipeline Guide](CICD_GUIDE.md)
- [Testing Strategy](TESTING_STRATEGY.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
