import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_manager.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_service.dart';
import 'package:flutter_chat_app/core/monitoring/crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/message_delivery_tracker.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/services/performance_service.dart';

/// Module đăng ký các dịch vụ monitoring vào dependency injection
@module
abstract class MonitoringModule {
  /// Cung cấp Firebase Analytics instance
  @preResolve
  @singleton
  @Environment('prod')
  Future<FirebaseAnalytics> provideFirebaseAnalytics() async {
    final analytics = FirebaseAnalytics.instance;
    // Disable trong chế độ debug
    await analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    return analytics;
  }
  
  /// Cung cấp Firebase Crashlytics instance
  @preResolve
  @singleton
  @Environment('prod')
  Future<FirebaseCrashlytics> provideFirebaseCrashlytics() async {
    final crashlytics = FirebaseCrashlytics.instance;
    // Disable trong chế độ debug
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    return crashlytics;
  }
  
  /// Cung cấp Firebase Performance instance
  @preResolve
  @singleton
  @Environment('prod')
  Future<FirebasePerformance> provideFirebasePerformance() async {
    final performance = FirebasePerformance.instance;
    // Disable trong chế độ debug
    await performance.setPerformanceCollectionEnabled(!kDebugMode);
    return performance;
  }
  
  /// Cung cấp PerformanceService
  @preResolve
  @lazySingleton
  Future<PerformanceService> providePerformanceService(
    FirebasePerformance performance,
  ) async {
    final service = PerformanceService(performance);
    await service.initialize();
    return service;
  }
  
  /// Cung cấp Analytics Service dựa trên Firebase
  @preResolve
  @singleton
  @Environment('prod')
  Future<AnalyticsService> provideAnalyticsService(
    FirebaseAnalytics analytics,
    CrashReporter crashReporter,
    PerformanceMonitor performanceMonitor,
  ) async {
    final service = AnalyticsService(
      analytics, 
      crashReporter, 
      performanceMonitor,
    );
    await service.initialize();
    return service;
  }
  
  /// Cung cấp Firebase Analytics Manager
  @preResolve
  @Environment('prod')
  Future<AnalyticsManager> provideFirebaseAnalyticsManager(
    FirebaseAnalytics analytics,
  ) async {
    final manager = FirebaseAnalyticsManager(analytics);
    await manager.initialize();
    return manager;
  }
  
  /// Cung cấp Default Analytics Manager (cho prod/staging)
  @preResolve
  @Singleton(as: AnalyticsManager)
  @Environment('prod')
  Future<DefaultAnalyticsManager> provideDefaultAnalyticsManager(
    @Named('firebaseAnalyticsManager') AnalyticsManager firebaseManager,
  ) async {
    final manager = DefaultAnalyticsManager(
      providers: [firebaseManager],
    );
    await manager.initialize();
    return manager;
  }
  
  /// Cung cấp Crash Reporter
  /// 
  /// Note: Removed @preResolve because @factoryParam is not compatible with it.
  /// CrashReporter will initialize itself when first accessed.
  @singleton
  CrashReporter provideCrashReporter(
    FirebaseCrashlytics crashlytics,
  ) {
    return CrashReporter(crashlytics);
  }
  
  /// Cung cấp Performance Monitor
  /// 
  /// Note: Removed @preResolve because @factoryParam is not compatible with it.
  /// PerformanceMonitor will initialize itself when first accessed.
  @singleton
  PerformanceMonitor providePerformanceMonitor(
    FirebasePerformance performance,
  ) {
    return PerformanceMonitor(performance);
  }
  
  /// Cung cấp Message Delivery Tracker
  @preResolve
  @singleton
  Future<MessageDeliveryTracker> provideMessageDeliveryTracker(
    PerformanceMonitor performanceMonitor,
  ) async {
    final tracker = MessageDeliveryTracker(performanceMonitor);
    await tracker.initialize();
    return tracker;
  }
  
  /// Tạo Crashlytics giả lập cho môi trường không hỗ trợ
  FirebaseCrashlytics? _createNoOpCrashlytics() {
    if (kDebugMode) {
      print('Creating NoOp Crashlytics');
    }
    // Return null for stub implementation - will be handled by adapter
    return null;
  }
  
  /// Tạo Performance giả lập cho môi trường không hỗ trợ
  FirebasePerformance? _createNoOpPerformance() {
    if (kDebugMode) {
      print('Creating NoOp Performance');
    }
    // Return null for stub implementation - will be handled by adapter
    return null;
  }
}

/// Triển khai Firebase Analytics Manager
class FirebaseAnalyticsManager implements AnalyticsManager {
  final FirebaseAnalytics _analytics;
  
  FirebaseAnalyticsManager(this._analytics);
  
  @override
  Future<void> initialize() async {
    // Đã được khởi tạo khi inject
  }
  
  @override
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
  
  @override
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
  
  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
  
  @override
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }
  
  @override
  Future<void> logScreenView(String screenName, [String? screenClass]) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }
  
  @override
  Future<void> setEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }
} 