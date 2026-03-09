import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_chat_app/core/cache/background_sync_helper.dart';
import 'package:flutter_chat_app/core/network/connectivity/connectivity_service.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enterprise-grade Background Sync Worker sử dụng Flutter Background Service
/// Thay thế workmanager để tránh v1 embedding issues
class BackgroundSyncWorker {
  /// Singleton instance
  static final BackgroundSyncWorker _instance =
      BackgroundSyncWorker._internal();
  
  /// Factory constructor
  factory BackgroundSyncWorker() => _instance;
  
  /// Logger
  final Logger _logger = Logger();

  /// Dependencies
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  late final IConnectivityService _connectivityService;
  
  /// Đã khởi tạo chưa
  bool _isInitialized = false;
  
  /// Port để giao tiếp giữa main isolate và background service
  ReceivePort? _receivePort;
  
  /// Timer cho periodic sync
  Timer? _periodicTimer;
  
  /// Các hằng số
  static const String backgroundSyncTask = 'com.oxii.chat.BACKGROUND_SYNC';
  static const String periodicSyncTask = 'com.oxii.chat.PERIODIC_SYNC';
  static const Duration minSyncInterval = Duration(minutes: 15);
  static const Duration defaultSyncInterval = Duration(hours: 1);
  static const int maxBackgroundTasks = 3;
  
  /// Performance targets
  static const Duration maxSyncDuration = Duration(minutes: 5);
  static const int maxMemoryUsageMB = 150;
  static const Duration targetDeliveryTime = Duration(milliseconds: 100);
  
  /// Private constructor
  BackgroundSyncWorker._internal() {
    try {
      _connectivityService = GetIt.instance<IConnectivityService>();
    } catch (e) {
      _logger.w('ConnectivityService chưa được register trong DI: $e');
    }
  }
  
  /// Khởi tạo enterprise background sync worker
  Future<void> initialize({IConnectivityService? connectivityService}) async {
    if (_isInitialized) return;
    
    try {
      _logger.i('🚀 Khởi tạo EnterpriseBackgroundSyncWorker');
      
      // Set connectivity service if provided
      if (connectivityService != null) {
        _connectivityService = connectivityService;
      }
      
      // Khởi tạo Background Service
      await _initializeBackgroundService();
      
      // Register port cho communication
      _registerPort();
      
      // Đặt lịch cho đồng bộ định kỳ
      await _schedulePeriodicSync();
      
      _isInitialized = true;
      _logger.i('✅ EnterpriseBackgroundSyncWorker đã được khởi tạo thành công');
    } catch (e) {
      _logger.e('❌ Lỗi khi khởi tạo EnterpriseBackgroundSyncWorker: $e');
      rethrow;
    }
  }
  
  /// Khởi tạo Flutter Background Service
  Future<void> _initializeBackgroundService() async {
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'chat_sync_channel',
        initialNotificationTitle: 'Chat Sync',
        initialNotificationContent: 'Đồng bộ tin nhắn trong nền',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onBackgroundServiceStart,
        onBackground: _onIosBackground,
      ),
    );
    
    _logger.i('📱 Background Service đã được cấu hình');
  }
  
  /// Callback khi background service start (Android)
  @pragma('vm:entry-point')
  static void _onBackgroundServiceStart(ServiceInstance service) async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    final logger = Logger();
    logger.i('🔄 Background Service started');
    
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }
    
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    
    // Periodic sync every 15 minutes
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      try {
        await _performEnterpriseBackgroundSync(service, logger);
      } catch (e) {
        logger.e('❌ Error in periodic sync: $e');
      }
    });
  }
  
  /// iOS background processing
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    final logger = Logger();
    logger.i('🍎 iOS background processing started');
    
    try {
      await _performEnterpriseBackgroundSync(service, logger);
      return true;
    } catch (e) {
      logger.e('❌ iOS background sync failed: $e');
      return false;
    }
  }
  
  /// Perform enterprise-grade background sync
  static Future<void> _performEnterpriseBackgroundSync(
    ServiceInstance service,
    Logger logger
  ) async {
    final startTime = DateTime.now();
    logger.i('Background sync started');

    try {
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool('background_sync_enabled') ?? true;

      if (!syncEnabled) {
        logger.i('Background sync disabled');
        return;
      }

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Chat Sync',
          content: 'Syncing messages...',
        );
      }

      // Use BackgroundSyncHelper for real sync via GraphQL + Isar
      final helper = await BackgroundSyncHelper.initialize();
      try {
        await helper.syncChatList();
      } finally {
        await helper.dispose();
      }

      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      final duration = DateTime.now().difference(startTime);
      logger.i('Background sync completed in ${duration.inSeconds}s');

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Chat Sync',
          content: 'Sync completed at ${DateTime.now().toString().substring(11, 16)}',
        );
      }

      service.invoke('syncComplete', {
        'time': DateTime.now().toIso8601String(),
        'duration': duration.inMilliseconds,
      });

    } catch (e) {
      logger.e('Background sync failed: $e');

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Chat Sync',
          content: 'Sync failed - will retry later',
        );
      }
    }
  }
  
  /// Perform manual sync using BackgroundSyncHelper
  Future<void> performManualSync() async {
    if (!_isInitialized) {
      _logger.w('Background sync worker not initialized');
      return;
    }

    try {
      _logger.i('Starting manual sync');

      final isConnected = await _connectivityService.isConnected();
      if (!isConnected) {
        _logger.w('No network connection, skipping sync');
        return;
      }

      final helper = await BackgroundSyncHelper.initialize();
      try {
        await helper.syncChatList();
      } finally {
        await helper.dispose();
      }

      _logger.i('Manual sync completed');
    } catch (e) {
      _logger.e('Manual sync failed: $e');
      rethrow;
    }
  }

  /// Đăng ký port cho communication
  void _registerPort() {
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      'enterprise_background_sync_port',
    );

    _receivePort!.listen((dynamic message) {
      _logger.i('📨 Nhận thông báo từ background service: $message');
    });
  }
  
  /// Đặt lịch cho đồng bộ định kỳ
  Future<void> _schedulePeriodicSync() async {
    final prefs = await SharedPreferences.getInstance();
    final intervalMinutes = prefs.getInt('background_sync_interval_minutes') ?? 
        defaultSyncInterval.inMinutes;
    
    // Start background service
    final isRunning = await _backgroundService.isRunning();
    if (!isRunning) {
      await _backgroundService.startService();
      _logger.i('🚀 Background service started');
    }
    
    _logger.i('⏰ Đã đặt lịch đồng bộ định kỳ mỗi $intervalMinutes phút');
  }
  
  /// Thay đổi khoảng thời gian đồng bộ
  Future<void> setSyncInterval(Duration interval) async {
    if (interval < minSyncInterval) {
      interval = minSyncInterval;
      _logger.w('⚠️ Interval quá nhỏ, đã điều chỉnh thành ${minSyncInterval.inMinutes} phút');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('background_sync_interval_minutes', interval.inMinutes);
    
    _logger.i('⏰ Đã cập nhật sync interval thành ${interval.inMinutes} phút');
    
    // Restart service với interval mới
    await stopBackgroundSync();
    await _schedulePeriodicSync();
  }
  
  /// Yêu cầu đồng bộ ngay lập tức
  Future<void> requestImmediateSync({
    Map<String, dynamic>? inputData,
    List<String>? priorityDataTypes,
  }) async {
    _logger.i('⚡ Yêu cầu đồng bộ ngay lập tức');
    
    try {
      // Invoke immediate sync through background service
      _backgroundService.invoke('immediateSync', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'inputData': inputData ?? {},
        'priorityDataTypes': priorityDataTypes ?? ['user_data', 'chat_list'],
      });
      
      _logger.i('✅ Đã gửi yêu cầu đồng bộ ngay lập tức');
    } catch (e) {
      _logger.e('❌ Lỗi khi yêu cầu đồng bộ ngay lập tức: $e');
    }
  }
  
  /// Dừng background sync
  Future<void> stopBackgroundSync() async {
    try {
      final isRunning = await _backgroundService.isRunning();
      if (isRunning) {
        _backgroundService.invoke('stopService');
        _logger.i('⏹️ Đã dừng background service');
      }
      
      _periodicTimer?.cancel();
      _periodicTimer = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_sync_enabled', false);
      
    } catch (e) {
      _logger.e('❌ Lỗi khi dừng background sync: $e');
    }
  }
  
  /// Cleanup resources
  Future<void> dispose() async {
    await stopBackgroundSync();
    _receivePort?.close();
    _receivePort = null;
    _isInitialized = false;
    _logger.i('🧹 EnterpriseBackgroundSyncWorker đã được cleanup');
  }
  
  /// Check if background sync is running
  Future<bool> isRunning() async {
    return _backgroundService.isRunning();
  }
  
  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_time');
    final syncInterval = prefs.getInt('background_sync_interval_minutes') ?? 
        defaultSyncInterval.inMinutes;
    
    return {
      'isRunning': await isRunning(),
      'lastSyncTime': lastSyncStr,
      'syncIntervalMinutes': syncInterval,
      'isInitialized': _isInitialized,
    };
  }
}
