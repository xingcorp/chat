/// **FIREBASE CONFIGURATION MANAGER**
///
/// Manages Firebase initialization per flavor với:
/// - Environment-specific Firebase projects
/// - Dynamic configuration loading from generated options
/// - Service initialization
/// - Error handling và fallbacks
///
/// **Architecture:** Factory Pattern + Environment Abstraction + Enterprise Standards
///
/// **Firebase Projects:**
/// - Staging: common-stag (616861138934)
/// - Production: common-18e05 (159636416445)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/firebase_options_staging.dart';
import 'package:flutter_chat_app/firebase_options_production.dart';

/// **Firebase Configuration Manager**
///
/// Handles Firebase initialization based on current flavor.
/// Uses generated Firebase options from FlutterFire CLI.
class FirebaseConfigManager {
  FirebaseConfigManager._();

  static final AppLogger _logger = AppLogger();
  static bool _isInitialized = false;

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize Firebase with flavor-specific configuration
  ///
  /// This method:
  /// 1. Determines current flavor from FlavorConfig
  /// 2. Loads appropriate Firebase options (staging/production)
  /// 3. Initializes Firebase with platform-specific configuration
  /// 4. Enables Firebase services based on flavor settings
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('Firebase already initialized');
      return;
    }

    try {
      final config = FlavorConfig.instance;
      final firebaseOptions = _getFirebaseOptions(config.flavor);

      // _logger.info('Initializing Firebase for ${config.flavor.name} environment...');
      // _logger.info('Firebase project: ${firebaseOptions.projectId}');

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
      // _logger.info('Firebase initialized successfully');
      // _logger.info('Firebase app ID: ${firebaseOptions.appId}');

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

  /// Get Firebase options based on flavor
  ///
  /// Uses generated options from FlutterFire CLI:
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
      } else {
        // _logger.info('Firebase Analytics disabled for ${config.flavor.name}');
      }

      // Initialize Crashlytics if enabled
      if (config.environment.enableCrashlytics) {
        // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        // _logger.info('Firebase Crashlytics enabled');
      } else {
        // _logger.info('Firebase Crashlytics disabled for ${config.flavor.name}');
      }

      // Initialize Performance Monitoring if enabled
      if (config.environment.enablePerformanceMonitoring) {
        // await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
        // _logger.info('Firebase Performance Monitoring enabled');
      } else {
        // _logger.info('Firebase Performance disabled for ${config.flavor.name}');
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
      throw UnsupportedError('Fallback initialization only allowed in debug mode');
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
  /// 2. Project ID matches expected flavor configuration
  static Future<void> _verifyFirebaseConnection(FlavorConfig config) async {
    try {
      final app = getCurrentApp();
      if (app == null) {
        throw StateError('Firebase app not found');
      }

      // Verify project ID matches flavor
      final expectedProjectId = _getExpectedProjectId(config.flavor);
      final actualProjectId = app.options.projectId;

      if (actualProjectId != expectedProjectId) {
        _logger.warning(
          'Project ID mismatch: expected $expectedProjectId, got $actualProjectId'
        );
      } else {
        // _logger.info('Firebase project ID verified: $actualProjectId');
      }

      // _logger.info('Firebase connection verified successfully');

    } catch (e, stackTrace) {
      _logger.error('Firebase connection verification failed', e, stackTrace);
      if (!kDebugMode) {
        throw StateError('Firebase verification failed: $e');
      }
    }
  }

  /// Get expected Firebase project ID for flavor
  static String _getExpectedProjectId(FlavorType flavor) {
    switch (flavor) {
      case FlavorType.staging:
        return 'common-stag';
      case FlavorType.production:
        return 'common-18e05';
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

  /// Get Firebase configuration summary for debugging
  static Map<String, dynamic> getConfigurationSummary() {
    final config = FlavorConfig.instance;
    final options = getCurrentOptions();

    return {
      'flavor': config.flavor.name,
      'initialized': _isInitialized,
      'projectId': options?.projectId,
      'appId': options?.appId,
      'messagingSenderId': options?.messagingSenderId,
      'analyticsEnabled': config.environment.enableAnalytics,
      'crashlyticsEnabled': config.environment.enableCrashlytics,
      'performanceEnabled': config.environment.enablePerformanceMonitoring,
    };
  }
}
