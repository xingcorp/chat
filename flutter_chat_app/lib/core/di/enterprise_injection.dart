/// Enterprise Dependency Injection System
/// 
/// Unified, high-performance DI system for enterprise-grade Flutter chat app.
/// Replaces fragmented DI files with single source of truth.
/// 
/// Performance Targets:
/// - Startup time: <500ms
/// - Memory usage: <150MB
/// - Zero duplicate registrations
/// 
/// Author: Senior Flutter/Mobile Architect
library enterprise_injection;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_service.dart';
import 'package:flutter_chat_app/core/monitoring/crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/network/socket_analytics.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_chat_app/core/network/socket_rate_limiter.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/enterprise_background_sync_service.dart';
import 'package:flutter_chat_app/core/services/localization_service.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/core/utils/adaptive_animations.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';
import 'package:flutter_chat_app/core/utils/system_resources.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Enterprise Dependency Injection Manager
/// 
/// Single source of truth for all dependency registration and management.
/// Follows Clean Architecture principles with proper error handling.
class EnterpriseDI {
  static bool _isInitialized = false;
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Performance tracking
  static final Map<String, int> _initializationTimes = {};
  static late final Stopwatch _totalStopwatch;

  /// Initialize the complete enterprise DI system
  /// 
  /// Performance target: <500ms total initialization
  /// Memory target: <20MB for DI system
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('🔄 Enterprise DI already initialized, skipping...');
      return;
    }

    _totalStopwatch = Stopwatch()..start();
    _logger.i('🚀 Initializing Enterprise DI System...');

    try {
      // Initialize in dependency order for optimal performance
      await _initializeFoundation();     // Target: <100ms
      await _initializeCore();           // Target: <150ms
      await _initializeNetworking();     // Target: <100ms
      await _initializeStorage();        // Target: <100ms
      await _initializeServices();       // Target: <50ms

      _isInitialized = true;
      _totalStopwatch.stop();
      
      final totalTime = _totalStopwatch.elapsedMilliseconds;
      _logger.i('✅ Enterprise DI initialized successfully in ${totalTime}ms');
      
      // Performance validation
      await _validatePerformance(totalTime);
      
      // Log detailed timing breakdown
      _logPerformanceBreakdown();
      
    } catch (error, stackTrace) {
      _logger.e('❌ Enterprise DI initialization failed', error: error, stackTrace: stackTrace);
      await _handleInitializationFailure(error, stackTrace);
      rethrow;
    }
  }

  /// Initialize foundation services (logging, performance monitoring)
  static Future<void> _initializeFoundation() async {
    final stopwatch = Stopwatch()..start();
    _logger.d('📋 Initializing Foundation Services...');

    try {
      // Logger (already initialized, just register)
      if (!serviceLocator.isRegistered<Logger>()) {
        serviceLocator.registerSingleton<Logger>(_logger);
      }

      // Firebase Performance
      final firebasePerformance = FirebasePerformance.instance;
      serviceLocator.registerSingleton<FirebasePerformance>(firebasePerformance);

      // Performance Monitor (enterprise-grade monitoring)
      final performanceMonitor = PerformanceMonitor(firebasePerformance);
      await performanceMonitor.initialize();
      serviceLocator.registerSingleton<PerformanceMonitor>(performanceMonitor);

      // System Resource Monitor (for isolate scaling decisions)
      final systemResourceMonitor = SystemResourceMonitor();
      systemResourceMonitor.initialize(); // Note: initialize() returns void, not Future
      serviceLocator.registerSingleton<SystemResourceMonitor>(systemResourceMonitor);

      // Isolate Manager (for heavy computational tasks)
      final isolateManager = IsolateManager(performanceMonitor, systemResourceMonitor);
      await isolateManager.initialize();
      serviceLocator.registerSingleton<IsolateManager>(isolateManager);

      // Adaptive Animation Manager (for smooth UX)
      serviceLocator.registerSingleton<AdaptiveAnimationManager>(
        AdaptiveAnimationManager(performanceMonitor),
      );

      // Firebase Analytics
      serviceLocator.registerLazySingleton<FirebaseAnalytics>(
        () => FirebaseAnalytics.instance,
      );

      // Firebase Crashlytics
      serviceLocator.registerLazySingleton<FirebaseCrashlytics>(
        () => FirebaseCrashlytics.instance,
      );

      // Crash Reporter (needed for AnalyticsService)
      serviceLocator.registerLazySingleton<CrashReporter>(
        () => CrashReporter(serviceLocator<FirebaseCrashlytics>()),
      );

      // Analytics Service (for tracking and monitoring)
      serviceLocator.registerLazySingleton<AnalyticsService>(
        () => AnalyticsService(
          serviceLocator<FirebaseAnalytics>(),
          serviceLocator<CrashReporter>(),
          performanceMonitor,
        ),
      );

      stopwatch.stop();
      _initializationTimes['foundation'] = stopwatch.elapsedMilliseconds;
      _logger.d('✅ Foundation Services initialized in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Foundation initialization failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize core services (connectivity, storage basics)
  static Future<void> _initializeCore() async {
    final stopwatch = Stopwatch()..start();
    _logger.d('🔧 Initializing Core Services...');

    try {
      // Connectivity
      serviceLocator.registerLazySingleton<Connectivity>(Connectivity.new);
      serviceLocator.registerLazySingleton<INetworkInfo>(
        () => NetworkInfo(
          connectivity: serviceLocator<Connectivity>(),
          logger: serviceLocator<Logger>(),
        ),
      );

      // Shared Preferences (initialized once for performance)
      final sharedPreferences = await SharedPreferences.getInstance();
      serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

      // Local Storage
      serviceLocator.registerLazySingleton<LocalStorage>(
        () => LocalStorageImpl(serviceLocator<SharedPreferences>()),
      );

      // Secure Storage
      serviceLocator.registerLazySingleton<SecureStorage>(
        SecureStorageImpl.new,
      );

      stopwatch.stop();
      _initializationTimes['core'] = stopwatch.elapsedMilliseconds;
      _logger.d('✅ Core Services initialized in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Core initialization failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize networking services (GraphQL, Socket.IO)
  static Future<void> _initializeNetworking() async {
    final stopwatch = Stopwatch()..start();
    _logger.d('🌐 Initializing Networking Services...');

    try {
      // Initialize Hive for GraphQL cache
      await initHiveForFlutter();

      // GraphQL Client with optimized cache
      serviceLocator.registerLazySingleton<GraphQLClient>(() {
        final httpLink = HttpLink(AppConfig.apiUrl); // Use apiUrl instead of graphqlEndpoint
        return GraphQLClient(
          cache: GraphQLCache(store: HiveStore()),
          link: httpLink,
        );
      });

      // Socket Analytics & Rate Limiter
      serviceLocator.registerLazySingleton<SocketAnalytics>(
        () => SocketAnalytics(
          analyticsService: serviceLocator<AnalyticsService>(),
          logger: serviceLocator<Logger>(),
        ),
      );

      serviceLocator.registerLazySingleton<SocketRateLimiter>(
        SocketRateLimiter.new,
      );

      // Socket Manager
      serviceLocator.registerLazySingleton<SocketManager>(() => SocketManager(
        serverUrl: AppConfig.webSocketUrl,
        logger: serviceLocator<Logger>(),
        analytics: serviceLocator<AnalyticsService>(), // Use AnalyticsService instead of SocketAnalytics
        options: _getSocketOptions(),
      ));

      // Enhanced Socket Manager
      serviceLocator.registerLazySingleton<EnhancedSocketManager>(
        () => EnhancedSocketManager(
          serviceLocator<SocketManager>(),
          serviceLocator<SocketAnalytics>(),
          serviceLocator<SocketRateLimiter>(),
        ),
      );

      stopwatch.stop();
      _initializationTimes['networking'] = stopwatch.elapsedMilliseconds;
      _logger.d('✅ Networking Services initialized in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Networking initialization failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize storage services (database, cache)
  static Future<void> _initializeStorage() async {
    final stopwatch = Stopwatch()..start();
    _logger.d('💾 Initializing Storage Services...');

    try {
      // Firebase Auth
      serviceLocator.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

      // Database Service
      final databaseService = DatabaseService();
      await databaseService.initialize();
      serviceLocator.registerSingleton<DatabaseService>(databaseService);

      // Cache Managers (using singleton pattern)
      serviceLocator.registerLazySingleton<AppCacheManager>(
        AppCacheManager.new, // Singleton factory constructor
      );

      serviceLocator.registerLazySingleton<MediaCacheManager>(
        MediaCacheManager.new, // Singleton factory constructor
      );

      // Connectivity Service (needed for repositories)
      serviceLocator.registerLazySingleton<ConnectivityService>(
        () => ConnectivityService(serviceLocator<Connectivity>()),
      );

      // Repositories
      serviceLocator.registerLazySingleton<OfflineFirstRepository>(
        () => OfflineFirstRepositoryImpl(
          serviceLocator<DatabaseService>(),
          serviceLocator<ConnectivityService>(),
        ),
      );

      stopwatch.stop();
      _initializationTimes['storage'] = stopwatch.elapsedMilliseconds;
      _logger.d('✅ Storage Services initialized in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Storage initialization failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize application services
  static Future<void> _initializeServices() async {
    final stopwatch = Stopwatch()..start();
    _logger.d('🎯 Initializing Application Services...');

    try {
      // Localization Service
      serviceLocator.registerLazySingleton<LocalizationService>(
        () => LocalizationService(serviceLocator<LocalStorage>()),
      );

      // Enterprise Background Sync Service (replaces workmanager)
      serviceLocator.registerLazySingleton<EnterpriseBackgroundSyncService>(
        EnterpriseBackgroundSyncService.new,
      );

      stopwatch.stop();
      _initializationTimes['services'] = stopwatch.elapsedMilliseconds;
      _logger.d('✅ Application Services initialized in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Services initialization failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get Socket.IO connection options
  static Map<String, dynamic> _getSocketOptions() {
    return {
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false,
      'auth': {
        'token': _getAuthToken(),
      },
    };
  }

  /// Get authentication token for Socket.IO
  static String? _getAuthToken() {
    // TODO: Implement proper token retrieval from secure storage
    return null;
  }

  /// Validate performance against enterprise standards
  static Future<void> _validatePerformance(int totalTime) async {
    const int performanceThreshold = 500; // 500ms target

    if (totalTime > performanceThreshold) {
      final message = 'DI initialization exceeded ${performanceThreshold}ms: ${totalTime}ms';
      _logger.w('⚠️ $message');

      // In development, throw exception for immediate feedback
      if (kDebugMode) {
        throw PerformanceException(message);
      }
    } else {
      _logger.i('🎯 Performance target met: ${totalTime}ms < ${performanceThreshold}ms');
    }
  }

  /// Log detailed performance breakdown
  static void _logPerformanceBreakdown() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Enterprise DI Performance Breakdown:');
    
    int totalTime = 0;
    _initializationTimes.forEach((phase, time) {
      buffer.writeln('  $phase: ${time}ms');
      totalTime += time;
    });
    
    buffer.writeln('  Total: ${totalTime}ms');
    _logger.i(buffer.toString());
  }

  /// Handle initialization failure with proper cleanup
  static Future<void> _handleInitializationFailure(Object error, StackTrace stackTrace) async {
    _logger.e('🚨 Performing emergency cleanup after DI failure...');
    
    try {
      // Reset GetIt instance
      await serviceLocator.reset();
      _isInitialized = false;
      
      // Clear performance tracking
      _initializationTimes.clear();
      
      _logger.i('🔄 Emergency cleanup completed');
    } catch (cleanupError) {
      _logger.e('❌ Emergency cleanup failed', error: cleanupError);
    }
  }

  /// Reset the DI system (for testing purposes)
  @visibleForTesting
  static Future<void> reset() async {
    await serviceLocator.reset();
    _isInitialized = false;
    _initializationTimes.clear();
    _logger.i('🔄 Enterprise DI System reset completed');
  }

  /// Check if DI system is initialized
  static bool get isInitialized => _isInitialized;

  /// Get service instance with type safety and error handling
  static T get<T extends Object>() {
    if (!_isInitialized) {
      throw StateError('Enterprise DI not initialized. Call EnterpriseDI.initialize() first.');
    }
    
    try {
      return serviceLocator<T>();
    } catch (e) {
      _logger.e('❌ Failed to resolve service ${T.toString()}', error: e);
      rethrow;
    }
  }

  /// Check if service is registered
  static bool isRegistered<T extends Object>() {
    return serviceLocator.isRegistered<T>();
  }
}

/// Custom exception for performance violations
class PerformanceException implements Exception {
  final String message;
  const PerformanceException(this.message);
  
  @override
  String toString() => 'PerformanceException: $message';
}
