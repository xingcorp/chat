// ignore_for_file: type=lint
/// **STAGING Firebase Options**
///
/// API keys are injected via `--dart-define` at build time.
/// NEVER hardcode API keys in this file.
///
/// Build command:
/// ```bash
/// flutter run --flavor staging --target lib/main_staging.dart \
///   --dart-define=FIREBASE_WEB_API_KEY=your_key \
///   --dart-define=FIREBASE_ANDROID_API_KEY=your_key \
///   --dart-define=FIREBASE_IOS_API_KEY=your_key \
///   --dart-define=FIREBASE_WEB_APP_ID=your_id \
///   --dart-define=FIREBASE_ANDROID_APP_ID=your_id \
///   --dart-define=FIREBASE_IOS_APP_ID=your_id \
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_id \
///   --dart-define=FIREBASE_PROJECT_ID=your_id \
///   --dart-define=FIREBASE_STORAGE_BUCKET=your_bucket \
///   --dart-define=FIREBASE_AUTH_DOMAIN=your_domain \
///   --dart-define=FIREBASE_MEASUREMENT_ID=your_id \
///   --dart-define=FIREBASE_IOS_BUNDLE_ID=your_bundle
/// ```
///
/// Or use a dart-define-from-file:
/// ```bash
/// flutter run --flavor staging \
///   --dart-define-from-file=.env.staging
/// ```
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for **STAGING** environment.
///
/// All values are loaded from compile-time `--dart-define` variables.
/// See `FIREBASE_SETUP.md` for configuration instructions.
class StagingFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'StagingFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'StagingFirebaseOptions have not been configured for Windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'StagingFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'StagingFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.oxii.chat',
    ),
  );
}
