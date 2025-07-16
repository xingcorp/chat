import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_chat_app/core/cache/enterprise_background_sync_worker.dart';
import 'package:flutter_chat_app/core/network/connectivity/connectivity_service.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enterprise Background Sync Service
/// Thay thế BackgroundSyncService cũ với enterprise-grade implementation
/// Sử dụng flutter_background_service thay vì workmanager để tránh v1 embedding issues
@lazySingleton
class EnterpriseBackgroundSyncService {
  /// Logger
  final Logger _logger = Logger();
  
  /// Dependencies
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  final EnterpriseBackgroundSyncWorker _enterpriseWorker = EnterpriseBackgroundSyncWorker();
  late final IConnectivityService _connectivityService;
  
  /// Service state
  bool _isInitialized = false;
  StreamSubscription? _connectivitySubscription;
  
  /// Performance metrics
  DateTime? _lastSyncTime;
  Duration? _lastSyncDuration;
  int _syncSuccessCount = 0;
  int _syncFailureCount = 0;
  
  /// Constructor
  EnterpriseBackgroundSyncService() {
    try {
      _connectivityService = GetIt.instance<IConnectivityService>();
    } catch (e) {
      _logger.w('ConnectivityService chưa được register trong DI: $e');
    }
  }
  
  /// Initialize enterprise background sync service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('🚀 Khởi tạo EnterpriseBackgroundSyncService');
      
      // Initialize enterprise worker
      await _enterpriseWorker.initialize(
        connectivityService: _connectivityService,
      );
      
      // Initialize background service for additional functionality
      await _initializeBackgroundService();
      
      // Setup connectivity monitoring
      await _setupConnectivityMonitoring();
      
      // Load performance metrics
      await _loadPerformanceMetrics();
      
      _isInitialized = true;
      _logger.i('✅ EnterpriseBackgroundSyncService đã được khởi tạo thành công');
    } catch (e) {
      _logger.e('❌ Lỗi khi khởi tạo EnterpriseBackgroundSyncService: $e');
      rethrow;
    }
  }
  
  /// Initialize background service for additional functionality
  Future<void> _initializeBackgroundService() async {
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: false, // Use enterprise worker for foreground
        notificationChannelId: 'enterprise_chat_sync_channel',
        initialNotificationTitle: 'Enterprise Chat Sync',
        initialNotificationContent: 'Đồng bộ tin nhắn enterprise',
        foregroundServiceNotificationId: 999,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onBackgroundServiceStart,
        onBackground: _onIosBackground,
      ),
    );
    
    _logger.i('📱 Enterprise Background Service đã được cấu hình');
  }
  
  /// Background service start handler
  @pragma('vm:entry-point')
  static void _onBackgroundServiceStart(ServiceInstance service) async {
    final logger = Logger();
    logger.i('🔄 Enterprise Background Service started');
    
    // Listen for service commands
    service.on('performSync').listen((event) async {
      await _performEnterpriseSync(service, logger);
    });
    
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
  
  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    final logger = Logger();
    logger.i('🍎 iOS enterprise background processing');
    
    try {
      await _performEnterpriseSync(service, logger);
      return true;
    } catch (e) {
      logger.e('❌ iOS enterprise sync failed: $e');
      return false;
    }
  }
  
  /// Perform enterprise sync
  static Future<void> _performEnterpriseSync(ServiceInstance service, Logger logger) async {
    final startTime = DateTime.now();
    logger.i('🔄 Bắt đầu enterprise sync');
    
    try {
      // Check if sync is enabled
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool('enterprise_sync_enabled') ?? true;
      
      if (!syncEnabled) {
        logger.i('⏸️ Enterprise sync bị tắt');
        return;
      }
      
      // Perform sync operations with enterprise standards
      await _syncWithEnterpriseStandards(logger);
      
      // Update metrics
      final duration = DateTime.now().difference(startTime);
      await prefs.setString('last_enterprise_sync_time', DateTime.now().toIso8601String());
      await prefs.setInt('last_enterprise_sync_duration_ms', duration.inMilliseconds);
      
      // Increment success counter
      final successCount = prefs.getInt('enterprise_sync_success_count') ?? 0;
      await prefs.setInt('enterprise_sync_success_count', successCount + 1);
      
      logger.i('✅ Enterprise sync hoàn thành trong ${duration.inSeconds}s');
      
      // Broadcast success
      service.invoke('syncComplete', {
        'success': true,
        'time': DateTime.now().toIso8601String(),
        'duration': duration.inMilliseconds,
      });
      
    } catch (e) {
      logger.e('❌ Enterprise sync failed: $e');
      
      // Update failure metrics
      final prefs = await SharedPreferences.getInstance();
      final failureCount = prefs.getInt('enterprise_sync_failure_count') ?? 0;
      await prefs.setInt('enterprise_sync_failure_count', failureCount + 1);
      
      // Broadcast failure
      service.invoke('syncFailed', {
        'success': false,
        'error': e.toString(),
        'time': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Sync with enterprise standards
  static Future<void> _syncWithEnterpriseStandards(Logger logger) async {
    // Enterprise-grade sync operations
    logger.i('💼 Thực hiện đồng bộ theo tiêu chuẩn enterprise');
    
    // Simulate enterprise sync operations
    await Future.delayed(const Duration(seconds: 2));
    
    // In real implementation:
    // - Sync user data with enterprise security
    // - Sync chat messages with encryption
    // - Sync media files with compression
    // - Update enterprise analytics
    // - Perform data validation
    // - Handle conflict resolution
  }
  
  /// Setup connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    try {
      _connectivitySubscription = _connectivityService.connectivityStream.listen(
        (connectionTypes) async {
          final isConnected = connectionTypes.isNotEmpty &&
              connectionTypes.any((type) => type != ConnectionType.none);
          _logger.i('🌐 Connectivity changed: $isConnected (types: $connectionTypes)');

          if (isConnected) {
            // Trigger immediate sync when connectivity is restored
            await requestImmediateSync(
              inputData: {'trigger': 'connectivity_restored'},
              priorityDataTypes: ['user_data', 'chat_messages'],
            );
          }
        },
        onError: (error) {
          _logger.e('❌ Connectivity monitoring error: $error');
        },
      );
    } catch (e) {
      _logger.w('⚠️ Không thể setup connectivity monitoring: $e');
    }
  }
  
  /// Load performance metrics
  Future<void> _loadPerformanceMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lastSyncStr = prefs.getString('last_enterprise_sync_time');
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.parse(lastSyncStr);
      }
      
      final lastDurationMs = prefs.getInt('last_enterprise_sync_duration_ms');
      if (lastDurationMs != null) {
        _lastSyncDuration = Duration(milliseconds: lastDurationMs);
      }
      
      _syncSuccessCount = prefs.getInt('enterprise_sync_success_count') ?? 0;
      _syncFailureCount = prefs.getInt('enterprise_sync_failure_count') ?? 0;
      
      _logger.i('📊 Performance metrics loaded: Success: $_syncSuccessCount, Failure: $_syncFailureCount');
    } catch (e) {
      _logger.e('❌ Error loading performance metrics: $e');
    }
  }
  
  /// Schedule periodic sync
  Future<void> schedulePeriodicSync({
    Duration frequency = const Duration(hours: 1),
    bool requiresCharging = false,
    bool requiresDeviceIdle = false,
  }) async {
    await _enterpriseWorker.setSyncInterval(frequency);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enterprise_sync_enabled', true);
    await prefs.setInt('enterprise_sync_frequency_hours', frequency.inHours);
    
    _logger.i('⏰ Đã đặt lịch enterprise sync mỗi ${frequency.inHours} giờ');
  }
  
  /// Request immediate sync
  Future<void> requestImmediateSync({
    Map<String, dynamic>? inputData,
    List<String>? priorityDataTypes,
  }) async {
    await _enterpriseWorker.requestImmediateSync(
      inputData: inputData,
      priorityDataTypes: priorityDataTypes,
    );
    
    _logger.i('⚡ Đã yêu cầu enterprise sync ngay lập tức');
  }
  
  /// Start background service
  Future<bool> startBackgroundService() async {
    final isRunning = await _backgroundService.isRunning();
    if (!isRunning) {
      await _backgroundService.startService();
      _logger.i('🚀 Enterprise background service started');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enterprise_sync_enabled', true);
    
    return await _backgroundService.isRunning();
  }
  
  /// Stop background service
  Future<bool> stopBackgroundService() async {
    await _enterpriseWorker.stopBackgroundSync();
    _backgroundService.invoke('stopService');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enterprise_sync_enabled', false);
    
    await Future.delayed(const Duration(seconds: 1));
    return !(await _backgroundService.isRunning());
  }
  
  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final enterpriseStats = await _enterpriseWorker.getSyncStats();
    
    return {
      ...enterpriseStats,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastSyncDuration': _lastSyncDuration?.inMilliseconds,
      'syncSuccessCount': _syncSuccessCount,
      'syncFailureCount': _syncFailureCount,
      'syncSuccessRate': _syncSuccessCount + _syncFailureCount > 0 
          ? _syncSuccessCount / (_syncSuccessCount + _syncFailureCount) 
          : 0.0,
    };
  }
  
  /// Check if service is running
  Future<bool> isRunning() async {
    return await _enterpriseWorker.isRunning();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _enterpriseWorker.dispose();
    _isInitialized = false;
    _logger.i('🧹 EnterpriseBackgroundSyncService đã được cleanup');
  }
}
