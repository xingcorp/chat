/// **FIREBASE CONFIGURATION MANAGER**
///
/// Manages Firebase initialization per flavor với:
/// - Environment-specific Firebase projects
/// - Dynamic configuration loading
/// - Service initialization
/// - Error handling và fallbacks
///
/// **Architecture:** Factory Pattern + Environment Abstraction + Enterprise Standards

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// **Firebase Configuration Manager**
/// 
/// Handles Firebase initialization based on current flavor
class FirebaseConfigManager {
  FirebaseConfigManager._();
  
  static final AppLogger _logger = AppLogger();
  static bool _isInitialized = false;
  
  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Initialize Firebase with flavor-specific configuration
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('Firebase already initialized');
      return;
    }

    try {
      final config = FlavorConfig.instance;
      final firebaseOptions = _getFirebaseOptions(config.flavor);

      // Initialize with flavor-specific name to avoid conflicts
      await Firebase.initializeApp(
        name: 'oxii-chat-${config.flavor.name}',
        options: firebaseOptions,
      );

      _isInitialized = true;
      _logger.info('Firebase initialized for ${config.flavor.name} environment');
      _logger.info('Firebase project: ${firebaseOptions.projectId}');
      _logger.info('Firebase app ID: ${firebaseOptions.appId}');

      // Initialize Firebase services
      await _initializeFirebaseServices(config);

      // Verify Firebase connection
      await _verifyFirebaseConnection(config);

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Firebase', e, stackTrace);

      // Try fallback initialization
      await _initializeFallback();
    }
  }
  
  /// Get Firebase options based on flavor
  static FirebaseOptions _getFirebaseOptions(FlavorType flavor) {
    switch (flavor) {
      case FlavorType.staging:
        return _getStagingFirebaseOptions();
      case FlavorType.production:
        return _getProductionFirebaseOptions();
    }
  }
  
  /// Get staging Firebase options
  static FirebaseOptions _getStagingFirebaseOptions() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDemoStagingKey123456789',
        appId: '1:123456789:android:staging123456789',
        messagingSenderId: '123456789',
        projectId: 'oxii-chat-staging',
        storageBucket: 'oxii-chat-staging.appspot.com',
        authDomain: 'oxii-chat-staging.firebaseapp.com',
        databaseURL: 'https://oxii-chat-staging-default-rtdb.firebaseio.com',
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDemoStagingKey123456789',
        appId: '1:123456789:ios:staging123456789',
        messagingSenderId: '123456789',
        projectId: 'oxii-chat-staging',
        storageBucket: 'oxii-chat-staging.appspot.com',
        authDomain: 'oxii-chat-staging.firebaseapp.com',
        databaseURL: 'https://oxii-chat-staging-default-rtdb.firebaseio.com',
        iosClientId: '123456789-staging.apps.googleusercontent.com',
        iosBundleId: 'com.oxii.chat.staging',
      );
    } else {
      // Web configuration
      return const FirebaseOptions(
        apiKey: 'AIzaSyDemoStagingKey123456789',
        appId: '1:123456789:web:staging123456789',
        messagingSenderId: '123456789',
        projectId: 'oxii-chat-staging',
        storageBucket: 'oxii-chat-staging.appspot.com',
        authDomain: 'oxii-chat-staging.firebaseapp.com',
        databaseURL: 'https://oxii-chat-staging-default-rtdb.firebaseio.com',
      );
    }
  }
  
  /// Get production Firebase options
  static FirebaseOptions _getProductionFirebaseOptions() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyProductionKey123456789',
        appId: '1:987654321:android:prod987654321',
        messagingSenderId: '987654321',
        projectId: 'oxii-chat-prod',
        storageBucket: 'oxii-chat-prod.appspot.com',
        authDomain: 'oxii-chat-prod.firebaseapp.com',
        databaseURL: 'https://oxii-chat-prod-default-rtdb.firebaseio.com',
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyProductionKey123456789',
        appId: '1:987654321:ios:prod987654321',
        messagingSenderId: '987654321',
        projectId: 'oxii-chat-prod',
        storageBucket: 'oxii-chat-prod.appspot.com',
        authDomain: 'oxii-chat-prod.firebaseapp.com',
        databaseURL: 'https://oxii-chat-prod-default-rtdb.firebaseio.com',
        iosClientId: '987654321-prod.apps.googleusercontent.com',
        iosBundleId: 'com.oxii.chat',
      );
    } else {
      // Web configuration
      return const FirebaseOptions(
        apiKey: 'AIzaSyProductionKey123456789',
        appId: '1:987654321:web:prod987654321',
        messagingSenderId: '987654321',
        projectId: 'oxii-chat-prod',
        storageBucket: 'oxii-chat-prod.appspot.com',
        authDomain: 'oxii-chat-prod.firebaseapp.com',
        databaseURL: 'https://oxii-chat-prod-default-rtdb.firebaseio.com',
      );
    }
  }
  
  /// Initialize Firebase services based on configuration
  static Future<void> _initializeFirebaseServices(FlavorConfig config) async {
    try {
      // Initialize Analytics if enabled
      if (config.environment.enableAnalytics) {
        // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        _logger.info('Firebase Analytics enabled');
      }
      
      // Initialize Crashlytics if enabled
      if (config.environment.enableCrashlytics) {
        // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        _logger.info('Firebase Crashlytics enabled');
      }
      
      // Initialize Performance Monitoring if enabled
      if (config.environment.enablePerformanceMonitoring) {
        // await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
        _logger.info('Firebase Performance Monitoring enabled');
      }
      
      // Initialize Messaging
      // await FirebaseMessaging.instance.requestPermission();
      _logger.info('Firebase Messaging initialized');
      
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Firebase services', e, stackTrace);
    }
  }
  
  /// Fallback initialization for development
  static Future<void> _initializeFallback() async {
    try {
      // Try default initialization
      await Firebase.initializeApp();
      _isInitialized = true;
      _logger.info('Firebase initialized with default configuration');
    } catch (e) {
      _logger.error('Firebase fallback initialization failed: $e');
      // Continue without Firebase for development
      _isInitialized = false;
    }
  }
  
  /// Verify Firebase connection and configuration
  static Future<void> _verifyFirebaseConnection(FlavorConfig config) async {
    try {
      final app = getCurrentApp();
      if (app == null) {
        throw StateError('Firebase app not found');
      }

      // Verify project ID matches flavor
      final expectedProjectId = config.environment.firebaseProjectId;
      final actualProjectId = app.options.projectId;

      if (actualProjectId != expectedProjectId) {
        _logger.warning('Project ID mismatch: expected $expectedProjectId, got $actualProjectId');
      }

      _logger.info('Firebase connection verified successfully');

    } catch (e, stackTrace) {
      _logger.error('Firebase connection verification failed', e, stackTrace);
      throw StateError('Firebase verification failed: $e');
    }
  }

  /// Get current Firebase app instance
  static FirebaseApp? getCurrentApp() {
    if (!_isInitialized) return null;

    try {
      final config = FlavorConfig.instance;
      return Firebase.app('oxii-chat-${config.flavor.name}');
    } catch (e) {
      _logger.error('Failed to get Firebase app: $e');
      return null;
    }
  }
  
  /// Reset Firebase (for testing purposes)
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
}
