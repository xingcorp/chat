import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Manager xử lý đồng bộ dữ liệu trong nền
class BackgroundSyncWorker {
  /// Singleton instance
  static final BackgroundSyncWorker _instance = BackgroundSyncWorker._internal();
  
  /// Factory constructor
  factory BackgroundSyncWorker() => _instance;
  
  /// Logger
  final _logger = Logger();
  
  /// Dependencies
  final CacheSyncStrategy _cacheSyncStrategy = CacheSyncStrategy();
  late final ConnectivityService _connectivityService;
  
  /// Đã khởi tạo chưa
  bool _isInitialized = false;
  
  /// Port để giao tiếp giữa main isolate và background tasks
  ReceivePort? _receivePort;
  
  /// Các hằng số
  static const String BACKGROUND_SYNC_TASK = 'com.flutter_chat_app.BACKGROUND_SYNC';
  static const String PERIODIC_SYNC_TASK = 'com.flutter_chat_app.PERIODIC_SYNC';
  static const Duration MIN_SYNC_INTERVAL = Duration(minutes: 15);
  static const Duration DEFAULT_SYNC_INTERVAL = Duration(hours: 1);
  static const int MAX_BACKGROUND_TASKS = 3; // Số lượng tối đa task chạy song song
  
  /// Private constructor
  BackgroundSyncWorker._internal();
  
  /// Khởi tạo worker
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('Khởi tạo BackgroundSyncWorker');
      
      // Khởi tạo dependencies
      _connectivityService = await ConnectivityService.create();
      
      // Khởi tạo Workmanager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
      
      // Register port
      _registerPort();
      
      // Đặt lịch cho đồng bộ định kỳ
      await _schedulePeriodicSync();
      
      _isInitialized = true;
      _logger.i('BackgroundSyncWorker đã được khởi tạo');
    } catch (e) {
      _logger.e('Lỗi khi khởi tạo BackgroundSyncWorker: $e');
    }
  }
  
  /// Đăng ký port
  void _registerPort() {
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      'background_sync_port',
    );
    
    _receivePort!.listen((dynamic message) {
      _logger.i('Nhận thông báo từ background task: $message');
    });
  }
  
  /// Đặt lịch cho đồng bộ định kỳ
  Future<void> _schedulePeriodicSync() async {
    final prefs = await SharedPreferences.getInstance();
    final intervalMinutes = prefs.getInt('background_sync_interval_minutes') ?? 
        DEFAULT_SYNC_INTERVAL.inMinutes;
    
    await Workmanager().registerPeriodicTask(
      PERIODIC_SYNC_TASK,
      PERIODIC_SYNC_TASK,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
    );
    
    _logger.i('Đã đặt lịch đồng bộ định kỳ mỗi $intervalMinutes phút');
  }
  
  /// Thay đổi khoảng thời gian đồng bộ
  Future<void> setSyncInterval(Duration interval) async {
    if (interval < MIN_SYNC_INTERVAL) {
      interval = MIN_SYNC_INTERVAL;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('background_sync_interval_minutes', interval.inMinutes);
    
    // Cập nhật lịch đồng bộ
    await _schedulePeriodicSync();
    
    _logger.i('Đã cập nhật khoảng thời gian đồng bộ: ${interval.inMinutes} phút');
  }
  
  /// Yêu cầu đồng bộ ngay lập tức (one-time)
  Future<void> requestImmediateSync({
    List<String>? priorityDataTypes,
    Map<String, dynamic>? inputData,
  }) async {
    // Kiểm tra xem có kết nối mạng không
    if (!await _connectivityService.checkConnected()) {
      _logger.w('Không thể đồng bộ ngay lập tức: Không có kết nối mạng');
      return;
    }
    
    final taskData = <String, dynamic>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'priority': true,
    };
    
    if (priorityDataTypes != null) {
      taskData['priorityDataTypes'] = priorityDataTypes;
    }
    
    if (inputData != null) {
      taskData.addAll(inputData);
    }
    
    await Workmanager().registerOneOffTask(
      'immediate_sync_${DateTime.now().millisecondsSinceEpoch}',
      BACKGROUND_SYNC_TASK,
      inputData: taskData,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.append,
    );
    
    _logger.i('Đã yêu cầu đồng bộ ngay lập tức');
  }
  
  /// Đồng bộ các loại dữ liệu cụ thể
  Future<void> syncSpecificData(List<String> dataTypes) async {
    final inputData = <String, dynamic>{
      'dataTypes': dataTypes,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await requestImmediateSync(inputData: inputData);
  }
  
  /// Hủy tất cả các task đồng bộ
  Future<void> cancelAllSyncTasks() async {
    await Workmanager().cancelAll();
    _logger.i('Đã hủy tất cả các task đồng bộ nền');
  }
  
  /// Đánh thức các background tasks đang ngủ
  Future<void> wakeUpBackgroundSync() async {
    // Workmanager không hỗ trợ trực tiếp đánh thức các task,
    // nhưng chúng ta có thể tạo một task mới với độ ưu tiên cao
    await requestImmediateSync(
      priorityDataTypes: ['user_data', 'chat_list', 'important_messages'],
      inputData: {'wakeup': true},
    );
  }
}

/// Callback chính cho Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final logger = Logger();
    logger.i('Đang thực hiện task: $taskName');
    
    // Gửi thông báo về main isolate nếu có thể
    final sendPort = IsolateNameServer.lookupPortByName('background_sync_port');
    sendPort?.send('Bắt đầu task: $taskName');
    
    try {
      if (taskName == BackgroundSyncWorker.BACKGROUND_SYNC_TASK ||
          taskName == BackgroundSyncWorker.PERIODIC_SYNC_TASK) {
        await _performBackgroundSync(logger, inputData);
      }
      
      logger.i('Task $taskName hoàn thành thành công');
      sendPort?.send('Task $taskName hoàn thành');
      return true;
    } catch (e) {
      logger.e('Lỗi khi thực hiện task $taskName: $e');
      sendPort?.send('Task $taskName thất bại: $e');
      return false;
    }
  });
}

/// Thực hiện đồng bộ trong nền
Future<void> _performBackgroundSync(Logger logger, Map<String, dynamic>? inputData) async {
  try {
    logger.i('Bắt đầu đồng bộ dữ liệu trong nền');
    
    // Khởi tạo các dependencies cần thiết
    final prefs = await SharedPreferences.getInstance();
    final appCacheManager = AppCacheManager();
    await appCacheManager.initialize();
    
    // Xác định các loại dữ liệu cần đồng bộ
    final List<String> dataTypes = [];
    
    if (inputData != null && inputData.containsKey('dataTypes')) {
      dataTypes.addAll(List<String>.from(inputData['dataTypes']));
    } else {
      // Đồng bộ mặc định
      final lastSyncTime = prefs.getInt('last_background_sync_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastSync = now - lastSyncTime;
      
      if (timeSinceLastSync > const Duration(hours: 1).inMilliseconds) {
        // Đồng bộ tất cả dữ liệu
        dataTypes.addAll(['user_data', 'chat_list', 'chat_messages', 'media']);
      } else {
        // Đồng bộ chỉ dữ liệu quan trọng
        dataTypes.addAll(['user_data', 'chat_list']);
      }
    }
    
    // Thực hiện đồng bộ cho từng loại dữ liệu
    logger.i('Đồng bộ các loại dữ liệu: $dataTypes');
    
    // Giả lập đồng bộ (trong thực tế sẽ gọi APIs thực)
    await Future.delayed(const Duration(seconds: 2));
    
    // Cập nhật thời gian đồng bộ cuối cùng
    await prefs.setInt('last_background_sync_time', DateTime.now().millisecondsSinceEpoch);
    
    logger.i('Đồng bộ dữ liệu trong nền hoàn tất');
  } catch (e) {
    logger.e('Lỗi khi đồng bộ dữ liệu trong nền: $e');
    rethrow;
  }
} 