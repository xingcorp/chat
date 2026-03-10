import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_manager.dart';
import 'package:flutter_chat_app/core/monitoring/i_crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';
import 'package:flutter_chat_app/core/services/chat_notification_orchestrator.dart';
import 'package:flutter_chat_app/core/services/chat_message_service.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/desktop_badge_service.dart';
import 'package:flutter_chat_app/core/services/firebase_service_manager.dart';
import 'package:flutter_chat_app/core/services/offline_queue_service.dart';
import 'package:flutter_chat_app/core/services/performance_service.dart';

/// Initializes non-critical and platform-specific services after the app has
/// rendered its first frame.
class ServiceInitializer {
  ServiceInitializer._();

  /// Initializes Firebase, monitoring, performance, and platform services.
  ///
  /// Failures in any individual service are caught and logged so that the
  /// rest of the app keeps running.
  static Future<void> initializeNonCriticalServices() async {
    final logger = GetIt.I<Logger>();

    try {
      // Deferred cache cleanup (moved out of critical startup path)
      AppCacheManager().deferredCleanup();
    } catch (e) {
      logger.e('Cache cleanup failed', error: e);
    }

    try {
      // Deferred CurrentUserProvider init (moved out of configureDependencies)
      if (GetIt.I.isRegistered<CurrentUserProvider>()) {
        await GetIt.I<CurrentUserProvider>().initialize();

        final currentUserId = GetIt.I<CurrentUserProvider>().currentUserId;
        if (currentUserId.isNotEmpty) {
          if (GetIt.I.isRegistered<String>(instanceName: 'currentUserId')) {
            await GetIt.I.unregister<String>(instanceName: 'currentUserId');
          }
          GetIt.I.registerSingleton<String>(
            currentUserId,
            instanceName: 'currentUserId',
          );
        }
      }
    } catch (e) {
      logger.e('CurrentUserProvider initialization failed', error: e);
    }

    try {
      final firebaseServiceManager = FirebaseServiceManager(logger);
      await firebaseServiceManager.initializeServices();
      logger.i(
          'Firebase initialized: ${firebaseServiceManager.getConfigurationSummary()}');
    } catch (e) {
      logger.e('Firebase initialization failed', error: e);
    }

    try {
      // These services are registered as LazySingleton (synchronous), not async
      if (GetIt.I.isRegistered<ICrashReporter>()) {
        GetIt.I<ICrashReporter>();
      }

      if (GetIt.I.isRegistered<IPerformanceMonitor>()) {
        final performanceMonitor = GetIt.I<IPerformanceMonitor>();
        await performanceMonitor.startTrace(TraceType.appStartup);
        await performanceMonitor.stopTrace(TraceType.appStartup);
      }

      if (GetIt.I.isRegistered<AnalyticsManager>()) {
        final analyticsManager = GetIt.I<AnalyticsManager>();
        await analyticsManager.logEvent('app_started', {
          'startup_time': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      logger.e('Monitoring services initialization failed', error: e);
    }

    try {
      if (GetIt.I.isRegistered<PerformanceService>()) {
        final performanceService = GetIt.I<PerformanceService>();
        await performanceService.initialize();

        if (kDebugMode) {
          performanceService.showPerformanceOverlay = true;
        }
      }
    } catch (e) {
      logger.e('PerformanceService initialization failed', error: e);
    }

    try {
      if (kIsWeb) {
        await _initializeWebServices();
      } else if (Platform.isAndroid || Platform.isIOS) {
        await _initializeMobileServices();
      } else {
        await _initializeDesktopServices();
      }
    } catch (e) {
      logger.e('Platform services initialization failed', error: e);
    }

    try {
      if (GetIt.I.isRegistered<ChatNotificationOrchestrator>()) {
        await GetIt.I<ChatNotificationOrchestrator>().initialize(
          enableBuiltInNotifications: true,
        );
      }
    } catch (e) {
      logger.e('Chat notification initialization failed', error: e);
    }
  }

  static Future<void> _initializeWebServices() async {
    // Web-specific services
    // NOTE: Isar database not supported on web platform
  }

  static Future<void> _initializeMobileServices() async {
    final logger = GetIt.I<Logger>();

    final databaseService = GetIt.I<DatabaseService>();
    await databaseService.initialize();

    _initializeOfflineQueueService(logger);
  }

  static Future<void> _initializeDesktopServices() async {
    final logger = GetIt.I<Logger>();

    final databaseService = GetIt.I<DatabaseService>();
    await databaseService.initialize();

    final chatMessageService = GetIt.I<ChatMessageService>();
    await chatMessageService.initialize();

    // Initialize desktop taskbar/dock badge (Windows + macOS).
    try {
      if (GetIt.I.isRegistered<DesktopBadgeService>()) {
        GetIt.I<DesktopBadgeService>().initialize();
        logger.i('DesktopBadgeService initialized');
      }
    } catch (e) {
      logger.e('DesktopBadgeService initialization failed', error: e);
    }

    _initializeOfflineQueueService(logger);
  }

  /// Force-init [OfflineQueueService] so its connectivity listener starts.
  ///
  /// Without this call the lazySingleton is never instantiated and pending
  /// messages are never retried when the device comes back online.
  static void _initializeOfflineQueueService(Logger logger) {
    try {
      if (GetIt.I.isRegistered<OfflineQueueService>()) {
        GetIt.I<OfflineQueueService>();
        logger.i(
            'OfflineQueueService initialized (connectivity listener active)');
      }
    } catch (e) {
      logger.e('OfflineQueueService initialization failed', error: e);
    }
  }
}
