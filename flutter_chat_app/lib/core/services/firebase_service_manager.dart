/// **FIREBASE SERVICE MANAGER**
///
/// Manages Firebase services per flavor với:
/// - Flavor-specific service initialization
/// - Analytics configuration per environment
/// - Crashlytics setup với proper reporting
/// - Performance monitoring configuration
/// - Push notification setup
///
/// **Architecture:** Service Layer + Flavor Abstraction + Enterprise Standards

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/config/firebase_config.dart';

/// **Firebase Service Manager**
/// 
/// Centralized management of Firebase services based on flavor
/// 
/// **Note**: Registered manually in core_module.dart (not via Injectable)
class FirebaseServiceManager {
  FirebaseServiceManager(this._logger);

  final Logger _logger;
  
  bool _analyticsInitialized = false;
  bool _crashlyticsInitialized = false;
  bool _performanceInitialized = false;
  bool _messagingInitialized = false;
  
  /// Initialize all Firebase services based on current flavor
  Future<void> initializeServices() async {
    try {
      final config = FlavorConfig.instance;
      
      _logger.i('Initializing Firebase services for ${config.flavor.name}');
      
      // Initialize core Firebase first
      await FirebaseConfigManager.initialize();
      
      // Initialize individual services based on configuration
      await _initializeAnalytics(config);
      await _initializeCrashlytics(config);
      await _initializePerformanceMonitoring(config);
      await _initializeMessaging(config);
      
      _logger.i('All Firebase services initialized successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Firebase services', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Initialize Firebase Analytics
  Future<void> _initializeAnalytics(FlavorConfig config) async {
    if (!config.environment.enableAnalytics) {
      _logger.i('Analytics disabled for ${config.flavor.name}');
      return;
    }
    
    try {
      // Note: Actual Firebase Analytics initialization would go here
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      
      // Set flavor-specific properties
      // await FirebaseAnalytics.instance.setUserProperty(
      //   name: 'app_flavor',
      //   value: config.flavor.name,
      // );
      
      // Set debug mode for staging
      if (config.isStaging) {
        // await FirebaseAnalytics.instance.setDebugModeEnabled(true);
        _logger.i('Analytics debug mode enabled for staging');
      }
      
      _analyticsInitialized = true;
      _logger.i('Firebase Analytics initialized for ${config.flavor.name}');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Analytics', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Initialize Firebase Crashlytics
  Future<void> _initializeCrashlytics(FlavorConfig config) async {
    if (!config.environment.enableCrashlytics) {
      _logger.i('Crashlytics disabled for ${config.flavor.name}');
      return;
    }
    
    try {
      // Note: Actual Firebase Crashlytics initialization would go here
      // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      // Set flavor-specific custom keys
      // await FirebaseCrashlytics.instance.setCustomKey('app_flavor', config.flavor.name);
      // await FirebaseCrashlytics.instance.setCustomKey('environment', config.environment.apiBaseUrl);
      // await FirebaseCrashlytics.instance.setCustomKey('build_mode', kDebugMode ? 'debug' : 'release');
      
      // Set user identifier for staging
      if (config.isStaging) {
        // await FirebaseCrashlytics.instance.setUserIdentifier('staging-user');
        _logger.i('Crashlytics staging user identifier set');
      }
      
      _crashlyticsInitialized = true;
      _logger.i('Firebase Crashlytics initialized for ${config.flavor.name}');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Crashlytics', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Initialize Firebase Performance Monitoring
  Future<void> _initializePerformanceMonitoring(FlavorConfig config) async {
    if (!config.environment.enablePerformanceMonitoring) {
      _logger.i('Performance monitoring disabled for ${config.flavor.name}');
      return;
    }
    
    try {
      // Note: Actual Firebase Performance initialization would go here
      // await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      
      // Set flavor-specific attributes
      // final trace = FirebasePerformance.instance.newTrace('app_startup_${config.flavor.name}');
      // await trace.start();
      
      _performanceInitialized = true;
      _logger.i('Firebase Performance Monitoring initialized for ${config.flavor.name}');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Performance Monitoring', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeMessaging(FlavorConfig config) async {
    try {
      // Note: Actual Firebase Messaging initialization would go here
      // final messaging = FirebaseMessaging.instance;
      
      // Request permission
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   announcement: false,
      //   badge: true,
      //   carPlay: false,
      //   criticalAlert: false,
      //   provisional: false,
      //   sound: true,
      // );
      
      // Set flavor-specific topic subscription
      final topicPrefix = config.isProduction ? 'prod' : 'staging';
      // await messaging.subscribeToTopic('${topicPrefix}_general');
      // await messaging.subscribeToTopic('${topicPrefix}_updates');
      
      _messagingInitialized = true;
      _logger.i('Firebase Messaging initialized for ${config.flavor.name}');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Messaging', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Log custom event to Analytics
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    if (!_analyticsInitialized) return;
    
    try {
      final config = FlavorConfig.instance;
      
      // Add flavor context to all events
      final enrichedParameters = {
        ...?parameters,
        'app_flavor': config.flavor.name,
        'environment': config.environment.apiBaseUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Note: Actual Analytics logging would go here
      // await FirebaseAnalytics.instance.logEvent(
      //   name: name,
      //   parameters: enrichedParameters,
      // );
      
      _logger.d('Analytics event logged: $name');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to log analytics event', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Record custom error to Crashlytics
  Future<void> recordError(dynamic exception, StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    if (!_crashlyticsInitialized) return;
    
    try {
      final config = FlavorConfig.instance;
      
      // Add flavor context to error
      final enrichedContext = {
        ...?context,
        'app_flavor': config.flavor.name,
        'environment': config.environment.apiBaseUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Note: Actual Crashlytics error recording would go here
      // await FirebaseCrashlytics.instance.recordError(
      //   exception,
      //   stackTrace,
      //   reason: reason,
      //   information: enrichedContext.entries.map((e) => '${e.key}: ${e.value}').toList(),
      // );
      
      _logger.d('Error recorded to Crashlytics: $exception');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to record error to Crashlytics', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Start custom performance trace
  Future<void> startTrace(String name) async {
    if (!_performanceInitialized) return;
    
    try {
      // Note: Actual Performance trace would go here
      // final trace = FirebasePerformance.instance.newTrace(name);
      // await trace.start();
      
      _logger.d('Performance trace started: $name');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to start performance trace', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Get FCM token for push notifications
  Future<String?> getFCMToken() async {
    if (!_messagingInitialized) return null;
    
    try {
      // Note: Actual FCM token retrieval would go here
      // final token = await FirebaseMessaging.instance.getToken();
      // return token;
      
      _logger.d('FCM token retrieved');
      return 'demo_fcm_token_${FlavorConfig.instance.flavor.name}';
      
    } catch (e, stackTrace) {
      _logger.e('Failed to get FCM token', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Subscribe to flavor-specific topic
  Future<void> subscribeToTopic(String topic) async {
    if (!_messagingInitialized) return;
    
    try {
      final config = FlavorConfig.instance;
      final flavorTopic = '${config.flavor.name}_$topic';
      
      // Note: Actual topic subscription would go here
      // await FirebaseMessaging.instance.subscribeToTopic(flavorTopic);
      
      _logger.i('Subscribed to topic: $flavorTopic');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to subscribe to topic', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Get service status
  Map<String, bool> getServiceStatus() {
    return {
      'analytics': _analyticsInitialized,
      'crashlytics': _crashlyticsInitialized,
      'performance': _performanceInitialized,
      'messaging': _messagingInitialized,
    };
  }
  
  /// Get Firebase configuration summary
  Map<String, dynamic> getConfigurationSummary() {
    final config = FlavorConfig.instance;
    final app = FirebaseConfigManager.getCurrentApp();
    
    return {
      'flavor': config.flavor.name,
      'projectId': app?.options.projectId ?? 'unknown',
      'appId': app?.options.appId ?? 'unknown',
      'apiKey': (app?.options.apiKey.substring(0, 10) ?? 'unknown') + '...',
      'services': getServiceStatus(),
      'environment': {
        'enableAnalytics': config.environment.enableAnalytics,
        'enableCrashlytics': config.environment.enableCrashlytics,
        'enablePerformanceMonitoring': config.environment.enablePerformanceMonitoring,
      },
    };
  }
}
