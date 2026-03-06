/// **FIREBASE CONFIGURATION MANAGER**
///
/// Manages Firebase initialization per flavor với:
/// - Environment-specific Firebase projects
/// - Dynamic configuration loading via `--dart-define` (NO hardcoded keys)
/// - Service initialization
/// - Runtime validation of required env vars
/// - Error handling và fallbacks
///
/// **Architecture:** Factory Pattern + Environment Abstraction + Enterprise Standards
///
/// **SECURITY:** All Firebase API keys are injected at build time via
/// `--dart-define` or `--dart-define-from-file`. See `FIREBASE_SETUP.md`.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/firebase_options_staging.dart';
import 'package:flutter_chat_app/firebase_options_production.dart';

/// **Firebase Configuration Manager**
///
/// Handles Firebase initialization based on current flavor.
/// Firebase options are loaded from compile-time `--dart-define` variables.
class FirebaseConfigManager {
  FirebaseConfigManager._();

  static final AppLogger _logger = AppLogger();
  static bool _isInitialized = false;

  /// Standalone app currently has compile-time Firebase options only for web,
  /// Android, and iOS. Desktop should skip Firebase until configured.
  static bool get supportsConfiguredPlatform {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  static String get currentPlatformLabel => _getCurrentPlatformKey();

  /// Required `--dart-define` keys for Firebase initialization.
  ///
  /// Build will fail fast if any of these are missing.
  static const List<String> _requiredEnvVars = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
  ];

  /// Platform-specific required keys (checked at runtime based on platform)
  static const Map<String, List<String>> _platformRequiredVars = {
    'web': ['FIREBASE_WEB_API_KEY', 'FIREBASE_WEB_APP_ID'],
    'android': ['FIREBASE_ANDROID_API_KEY', 'FIREBASE_ANDROID_APP_ID'],
    'ios': ['FIREBASE_IOS_API_KEY', 'FIREBASE_IOS_APP_ID'],
  };

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize Firebase with flavor-specific configuration
  ///
  /// This method:
  /// 1. Validates required `--dart-define` env vars are present
  /// 2. Determines current flavor from FlavorConfig
  /// 3. Loads appropriate Firebase options (staging/production)
  /// 4. Initializes Firebase with platform-specific configuration
  /// 5. Enables Firebase services based on flavor settings
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('Firebase already initialized');
      return;
    }

    if (!supportsConfiguredPlatform) {
      _logger.info(
        'Skipping Firebase initialization on $currentPlatformLabel until '
        'desktop Firebase options are configured.',
      );
      return;
    }

    try {
      final config = FlavorConfig.instance;

      // Validate env vars before attempting initialization
      _validateEnvironmentVariables();

      final firebaseOptions = _getFirebaseOptions(config.flavor);

      _logger.info(
        'Initializing Firebase for ${config.flavor.name} environment...',
      );

      if (kIsWeb) {
        // Web: Single default app instance
        await Firebase.initializeApp(
          options: firebaseOptions,
        );
      } else {
        // Mobile: Named app instance to support environment switching
        await Firebase.initializeApp(
          name: 'oxii-chat-${config.flavor.name}',
          options: firebaseOptions,
        );
      }

      _isInitialized = true;
      _logger.info('Firebase initialized successfully');

      // Initialize Firebase services based on flavor config
      await _initializeFirebaseServices(config);

      // Verify Firebase connection
      await _verifyFirebaseConnection(config);
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Firebase', e, stackTrace);

      // Try fallback initialization for development
      if (kDebugMode) {
        await _initializeFallback();
      } else {
        rethrow;
      }
    }
  }

  /// Validate that required `--dart-define` environment variables are set.
  ///
  /// Throws [StateError] in release mode if keys are missing.
  /// Logs warning in debug mode to allow development without Firebase.
  static void _validateEnvironmentVariables() {
    final missingVars = <String>[];

    // Check common required vars
    for (final varName in _requiredEnvVars) {
      final value = _getEnvVar(varName);
      if (value.isEmpty) {
        missingVars.add(varName);
      }
    }

    // Check platform-specific required vars
    final platform = _getCurrentPlatformKey();
    final platformVars = _platformRequiredVars[platform];
    if (platformVars != null) {
      for (final varName in platformVars) {
        final value = _getEnvVar(varName);
        if (value.isEmpty) {
          missingVars.add(varName);
        }
      }
    }

    if (missingVars.isNotEmpty) {
      final message = 'Missing required Firebase --dart-define variables: '
          '${missingVars.join(', ')}. '
          'See FIREBASE_SETUP.md for configuration instructions.';

      if (kDebugMode) {
        _logger.warning(message);
        _logger.warning(
          'Firebase may not work correctly. '
          'Run with: flutter run --dart-define-from-file=.env.staging',
        );
      } else {
        throw StateError(message);
      }
    }
  }

  /// Read a `--dart-define` variable value at compile time.
  static String _getEnvVar(String name) {
    // String.fromEnvironment is resolved at compile time via --dart-define
    switch (name) {
      case 'FIREBASE_PROJECT_ID':
        return const String.fromEnvironment('FIREBASE_PROJECT_ID');
      case 'FIREBASE_MESSAGING_SENDER_ID':
        return const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
      case 'FIREBASE_WEB_API_KEY':
        return const String.fromEnvironment('FIREBASE_WEB_API_KEY');
      case 'FIREBASE_WEB_APP_ID':
        return const String.fromEnvironment('FIREBASE_WEB_APP_ID');
      case 'FIREBASE_ANDROID_API_KEY':
        return const String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
      case 'FIREBASE_ANDROID_APP_ID':
        return const String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
      case 'FIREBASE_IOS_API_KEY':
        return const String.fromEnvironment('FIREBASE_IOS_API_KEY');
      case 'FIREBASE_IOS_APP_ID':
        return const String.fromEnvironment('FIREBASE_IOS_APP_ID');
      default:
        return '';
    }
  }

  /// Get current platform key for validation lookup.
  static String _getCurrentPlatformKey() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Get Firebase options based on flavor
  ///
  /// Uses options loaded from `--dart-define` env vars:
  /// - [StagingFirebaseOptions] for staging environment
  /// - [ProductionFirebaseOptions] for production environment
  static FirebaseOptions _getFirebaseOptions(FlavorType flavor) {
    switch (flavor) {
      case FlavorType.staging:
        return StagingFirebaseOptions.currentPlatform;
      case FlavorType.production:
        return ProductionFirebaseOptions.currentPlatform;
    }
  }

  /// Initialize Firebase services based on configuration
  ///
  /// Services enabled/disabled based on [EnvironmentConfig]:
  /// - Analytics: Enabled in production, optional in staging
  /// - Crashlytics: Enabled in production for crash reporting
  /// - Performance: Enabled in production for monitoring
  static Future<void> _initializeFirebaseServices(FlavorConfig config) async {
    try {
      // Initialize Analytics if enabled
      if (config.environment.enableAnalytics) {
        // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        // _logger.info('Firebase Analytics enabled');
      }

      // Initialize Crashlytics if enabled
      if (config.environment.enableCrashlytics) {
        // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        // _logger.info('Firebase Crashlytics enabled');
      }

      // Initialize Performance Monitoring if enabled
      if (config.environment.enablePerformanceMonitoring) {
        // await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
        // _logger.info('Firebase Performance Monitoring enabled');
      }

      // Initialize Messaging (always enabled for push notifications)
      // await FirebaseMessaging.instance.requestPermission();
      // _logger.info('Firebase Messaging initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Firebase services', e, stackTrace);
    }
  }

  /// Fallback initialization for development only
  ///
  /// Used when primary initialization fails in debug mode.
  /// Should NOT be used in production.
  static Future<void> _initializeFallback() async {
    if (!kDebugMode) {
      throw UnsupportedError(
        'Fallback initialization only allowed in debug mode',
      );
    }

    try {
      // Try default initialization without options
      await Firebase.initializeApp();
      _isInitialized = true;
      _logger.warning('Firebase initialized with fallback configuration');
    } catch (e) {
      _logger.error('Firebase fallback initialization failed: $e');
      // Continue without Firebase for development
      _isInitialized = false;
    }
  }

  /// Verify Firebase connection and configuration
  ///
  /// Validates that:
  /// 1. Firebase app is accessible
  /// 2. Project ID matches expected `--dart-define` value
  static Future<void> _verifyFirebaseConnection(FlavorConfig config) async {
    try {
      final app = getCurrentApp();
      if (app == null) {
        throw StateError('Firebase app not found');
      }

      final expectedProjectId = const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
      );
      final actualProjectId = app.options.projectId;

      if (expectedProjectId.isNotEmpty &&
          actualProjectId != expectedProjectId) {
        _logger.warning(
          'Project ID mismatch: expected $expectedProjectId, '
          'got $actualProjectId',
        );
      }

      _logger.info('Firebase connection verified: $actualProjectId');
    } catch (e, stackTrace) {
      _logger.error('Firebase connection verification failed', e, stackTrace);
      if (!kDebugMode) {
        throw StateError('Firebase verification failed: $e');
      }
    }
  }

  /// Get current Firebase app instance
  ///
  /// Returns the app instance based on current flavor:
  /// - Web: Default app
  /// - Mobile: Named app (oxii-chat-staging or oxii-chat-production)
  static FirebaseApp? getCurrentApp() {
    if (!_isInitialized) return null;

    try {
      final config = FlavorConfig.instance;
      if (kIsWeb) {
        return Firebase.app();
      }
      return Firebase.app('oxii-chat-${config.flavor.name}');
    } catch (e) {
      _logger.error('Failed to get Firebase app: $e');
      return null;
    }
  }

  /// Get Firebase options for current flavor
  ///
  /// Useful for services that need direct access to Firebase configuration.
  static FirebaseOptions? getCurrentOptions() {
    if (!supportsConfiguredPlatform) {
      return null;
    }

    try {
      final config = FlavorConfig.instance;
      return _getFirebaseOptions(config.flavor);
    } catch (e) {
      _logger.error('Failed to get Firebase options: $e');
      return null;
    }
  }

  /// Reset Firebase (for testing purposes only)
  ///
  /// Deletes all Firebase app instances and resets initialization state.
  /// Only available in debug mode.
  static Future<void> reset() async {
    if (!kDebugMode) {
      throw UnsupportedError('Firebase reset is only allowed in debug mode');
    }

    try {
      final apps = Firebase.apps;
      for (final app in apps) {
        await app.delete();
      }
      _isInitialized = false;
      _logger.info('Firebase reset completed');
    } catch (e, stackTrace) {
      _logger.error('Failed to reset Firebase', e, stackTrace);
    }
  }

  /// Get Firebase configuration summary for debugging.
  ///
  /// **SECURITY:** Redacts API keys — only shows project-level info.
  static Map<String, dynamic> getConfigurationSummary() {
    final config = FlavorConfig.instance;
    final options = getCurrentOptions();

    return {
      'flavor': config.flavor.name,
      'initialized': _isInitialized,
      'projectId': options?.projectId,
      // Redact sensitive fields — only show prefix for debugging
      'appId': _redact(options?.appId),
      'messagingSenderId': options?.messagingSenderId,
      'analyticsEnabled': config.environment.enableAnalytics,
      'crashlyticsEnabled': config.environment.enableCrashlytics,
      'performanceEnabled': config.environment.enablePerformanceMonitoring,
    };
  }

  /// Redact sensitive string — show first 8 chars + '***'
  static String? _redact(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length <= 8) return '***';
    return '${value.substring(0, 8)}***';
  }
}
