import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/monitoring/analytics_manager.dart';
import 'package:flutter_chat_app/core/monitoring/crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/services/chat_message_service.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/firebase_service_manager.dart';
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
      final firebaseServiceManager = FirebaseServiceManager(logger);
      await firebaseServiceManager.initializeServices();
      logger.i(
          'Firebase initialized: ${firebaseServiceManager.getConfigurationSummary()}');
    } catch (e) {
      logger.e('Firebase initialization failed', error: e);
    }

    try {
      await GetIt.I.getAsync<CrashReporter>();
      final performanceMonitor = await GetIt.I.getAsync<PerformanceMonitor>();
      final analyticsManager = await GetIt.I.getAsync<AnalyticsManager>();

      await performanceMonitor.startTrace(TraceType.appStartup);
      await performanceMonitor.stopTrace(TraceType.appStartup);

      await analyticsManager.logEvent('app_started', {
        'startup_time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      logger.e('Monitoring services initialization failed', error: e);
    }

    try {
      final performanceService = GetIt.I<PerformanceService>();
      await performanceService.initialize();

      if (kDebugMode) {
        performanceService.showPerformanceOverlay = true;
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
  }

  static Future<void> _initializeWebServices() async {
    // Web-specific services
    // NOTE: Isar database not supported on web platform
  }

  static Future<void> _initializeMobileServices() async {
    final databaseService = GetIt.I<DatabaseService>();
    await databaseService.initialize();
  }

  static Future<void> _initializeDesktopServices() async {
    final databaseService = GetIt.I<DatabaseService>();
    await databaseService.initialize();

    final chatMessageService = GetIt.I<ChatMessageService>();
    await chatMessageService.initialize();
  }
}
