# Chat Foundation - Deployment Guide

**Version:** 1.0  
**Last Updated:** 2025-01-28  
**Status:** Ready for Deployment

---

## 🚀 Quick Start

### Prerequisites

```bash
# Verify Flutter installation
flutter doctor

# Verify dependencies
flutter pub get

# Expected output: All checks passed ✓
```

### Run the App

```bash
cd flutter_chat_app

# Run on connected device
flutter run

# Run in release mode
flutter run --release

# Run specific flavor
flutter run --flavor staging
flutter run --flavor production
```

---

## 🧪 Testing Guide

### Step 1: Generate Mocks

```bash
cd flutter_chat_app

# Generate mocks for tests
flutter pub run build_runner build --delete-conflicting-outputs

# Expected output: Build completed successfully
```

### Step 2: Run Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/integration/chat_flow_integration_test.dart

# Run integration tests only
flutter test test/integration/

# Run unit tests only
flutter test test/unit/
```

### Step 3: View Coverage Report

```bash
# Generate HTML coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

### Expected Test Results

```
✓ All tests passed
✓ Test coverage: >60%
✓ No failing tests
✓ No test errors
```

---

## 🔍 Code Quality Check

### Run Flutter Analyze

```bash
cd flutter_chat_app

# Run analyzer
flutter analyze

# Expected: 0 errors (warnings are acceptable)
```

### Fix Common Issues

```bash
# Fix formatting
flutter format lib/ test/

# Fix imports
flutter pub run import_sorter:main

# Run code generation
dart run build_runner build --delete-conflicting-outputs
```

---

## 📱 Manual Testing Checklist

### 1. Chat List Page

- [ ] Load conversations successfully
- [ ] Display conversation list with avatars
- [ ] Show last message and timestamp
- [ ] Display unread count badge
- [ ] Pull to refresh works
- [ ] Pagination loads more chats
- [ ] Search conversations works
- [ ] Navigate to chat details on tap
- [ ] Show empty state when no chats
- [ ] Show error state with retry button

### 2. Chat Details Page

- [ ] Load messages successfully
- [ ] Display messages in reverse order (newest at bottom)
- [ ] Show sender avatar and name
- [ ] Display timestamp correctly
- [ ] Show "Edited" indicator for edited messages
- [ ] Display reactions if present
- [ ] Message input field works
- [ ] Send button enabled when text entered
- [ ] Send message successfully
- [ ] Show sending indicator
- [ ] Scroll to bottom on new message
- [ ] Pull to refresh loads older messages
- [ ] Long press shows context menu
- [ ] Copy message works
- [ ] Edit message works
- [ ] Delete message works

### 3. Offline Mode

- [ ] Turn on airplane mode
- [ ] Send message (should queue)
- [ ] Message shows as "pending"
- [ ] Turn off airplane mode
- [ ] Message sends automatically
- [ ] Message status updates to "sent"
- [ ] Queue processes in FIFO order
- [ ] Failed messages show retry option

### 4. Real-Time Features

- [ ] Receive messages instantly
- [ ] Typing indicator shows when other user types
- [ ] Read receipts update in real-time
- [ ] Reactions appear instantly
- [ ] Message edits update immediately
- [ ] Message deletes remove message

### 5. Error Handling

- [ ] Network error shows user-friendly message
- [ ] Server error shows retry button
- [ ] Validation errors show specific message
- [ ] Retry action works correctly
- [ ] No app crashes on errors

### 6. Localization

- [ ] Switch language to Vietnamese
- [ ] All strings translated correctly
- [ ] No hardcoded English text
- [ ] Switch back to English
- [ ] All strings display correctly

### 7. Performance

- [ ] App starts in <2 seconds
- [ ] Scrolling is smooth (60fps)
- [ ] No lag when typing
- [ ] Images load quickly
- [ ] No memory leaks
- [ ] Battery usage is reasonable

---

## 🏗️ Build for Release

### Android

```bash
cd flutter_chat_app

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
cd flutter_chat_app

# Build iOS app
flutter build ios --release

# Build IPA (requires Xcode)
flutter build ipa --release

# Output location:
# build/ios/iphoneos/Runner.app
# build/ios/ipa/flutter_chat_app.ipa
```

### Web

```bash
cd flutter_chat_app

# Build web app
flutter build web --release

# Output location:
# build/web/
```

---

## 🔧 Configuration

### Environment Variables

Create `.env` files for different environments:

**`.env.staging`**
```env
API_URL=https://staging-api.example.com
SOCKET_URL=wss://staging-socket.example.com
ENVIRONMENT=staging
```

**`.env.production`**
```env
API_URL=https://api.example.com
SOCKET_URL=wss://socket.example.com
ENVIRONMENT=production
```

### Backend Configuration

Update backend endpoints in:
```dart
// lib/core/network/api_config.dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.example.com',
  );
  
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'wss://socket.example.com',
  );
}
```

---

## 📊 Performance Monitoring

### Enable Performance Monitoring

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable performance monitoring
  await PerformanceMonitor.initialize();
  
  runApp(const MyApp());
}
```

### Monitor Key Metrics

```dart
// Track startup time
PerformanceMonitor.trackStartup();

// Track message send time
PerformanceMonitor.trackOperation('send_message', () async {
  await messageRepository.sendMessage(...);
});

// Track frame rate
PerformanceMonitor.trackFrameRate();
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Build Runner Fails

```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

#### 2. Tests Fail

```bash
# Regenerate mocks
flutter pub run build_runner build --delete-conflicting-outputs

# Clear test cache
flutter test --clear-cache

# Run tests again
flutter test
```

#### 3. Isar Database Issues

```bash
# Clear Isar cache
flutter clean

# Regenerate Isar schemas
dart run build_runner build --delete-conflicting-outputs
```

#### 4. Socket.IO Connection Issues

```dart
// Check socket connection
final isConnected = await socketManager.isConnected;
print('Socket connected: $isConnected');

// Reconnect manually
await socketManager.connect();
```

#### 5. Offline Queue Not Processing

```dart
// Check queue size
final queueSize = await offlineQueueService.getQueueSize();
print('Queue size: $queueSize');

// Process queue manually
await offlineQueueService.processQueue();
```

---

## 📦 Deployment Checklist

### Pre-Deployment

- [ ] All tests passing
- [ ] Flutter analyze shows 0 errors
- [ ] Manual testing completed
- [ ] Performance profiling done
- [ ] Backend endpoints configured
- [ ] Environment variables set
- [ ] App icons and splash screens ready
- [ ] App store listings prepared

### Staging Deployment

- [ ] Build staging APK/IPA
- [ ] Deploy to internal testing
- [ ] Test with staging backend
- [ ] Verify all features work
- [ ] Check performance metrics
- [ ] Fix any issues found

### Production Deployment

- [ ] Build production APK/IPA
- [ ] Upload to Play Store / App Store
- [ ] Configure production backend
- [ ] Enable monitoring and analytics
- [ ] Prepare rollback plan
- [ ] Monitor for issues
- [ ] Collect user feedback

---

## 🔐 Security Checklist

### Before Deployment

- [ ] No hardcoded API keys
- [ ] No sensitive data in logs
- [ ] HTTPS only for API calls
- [ ] Secure WebSocket connections
- [ ] Input validation on all forms
- [ ] SQL injection prevention (Isar handles this)
- [ ] XSS prevention in messages
- [ ] Authentication tokens secured
- [ ] Local data encrypted (if required)

---

## 📈 Post-Deployment Monitoring

### Key Metrics to Monitor

1. **Crash Rate**
   - Target: <1%
   - Monitor: Firebase Crashlytics

2. **API Response Time**
   - Target: <500ms
   - Monitor: Backend logs

3. **Message Delivery Rate**
   - Target: >99%
   - Monitor: Socket.IO logs

4. **Offline Queue Success Rate**
   - Target: >95%
   - Monitor: App logs

5. **User Engagement**
   - Daily active users
   - Messages sent per user
   - Average session duration

---

## 🆘 Support

### Getting Help

**Documentation:**
- Architecture Guide: `.kiro/specs/chat-foundation/project-architecture.md`
- Design Document: `.kiro/specs/chat-foundation/design.md`
- Task List: `.kiro/specs/chat-foundation/tasks.md`

**Common Commands:**
```bash
# Check Flutter version
flutter --version

# Check dependencies
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Clean project
flutter clean

# Get dependencies
flutter pub get
```

---

## ✅ Final Checklist

Before marking deployment as complete:

- [ ] All tests passing (>60% coverage)
- [ ] Manual testing completed on Android
- [ ] Manual testing completed on iOS
- [ ] Performance targets met
- [ ] No critical bugs
- [ ] Backend integration verified
- [ ] Offline mode tested
- [ ] Real-time features tested
- [ ] Error handling verified
- [ ] Localization verified
- [ ] Security checklist completed
- [ ] Monitoring configured
- [ ] Rollback plan prepared

---

**Status:** ✅ Ready for Deployment  
**Confidence Level:** HIGH  
**Estimated Deployment Time:** 1-2 days

**Good luck with the deployment! 🚀**

