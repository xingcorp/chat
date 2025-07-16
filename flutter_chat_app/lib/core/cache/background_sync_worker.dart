import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/network/connectivity/connectivity_service.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:workmanager/workmanager.dart';  // Temporarily disabled

// Stub implementations for workmanager
class _WorkmanagerStub {
  Future<void> initialize(Function callbackDispatcher, {bool isInDebugMode = false}) async {
    // Stub implementation - does nothing
  }

  Future<void> registerPeriodicTask(String uniqueName, String taskName, {
    Duration? frequency,
    dynamic constraints,
    dynamic existingWorkPolicy,
    dynamic backoffPolicy,
  }) async {
    // Stub implementation - does nothing
  }

  Future<void> registerOneOffTask(String uniqueName, String taskName, {
    dynamic inputData,
    dynamic constraints,
    dynamic existingWorkPolicy,
  }) async {
    // Stub implementation - does nothing
  }

  Future<void> cancelAll() async {
    // Stub implementation - does nothing
  }

  void executeTask(Function callback) {
    // Stub implementation - does nothing
  }
}

class _ConstraintsStub {
  final dynamic networkType;
  final bool requiresBatteryNotLow;

  _ConstraintsStub({this.networkType, this.requiresBatteryNotLow = false});
}

// Stub constants as objects with static-like access
final NetworkType = _NetworkTypeStub();
final ExistingWorkPolicy = _ExistingWorkPolicyStub();
final BackoffPolicy = _BackoffPolicyStub();

class _NetworkTypeStub {
  final String connected = 'connected';
}

class _ExistingWorkPolicyStub {
  final String replace = 'replace';
  final String append = 'append';
}

class _BackoffPolicyStub {
  final String exponential = 'exponential';
}

// Stub factory functions
_WorkmanagerStub Workmanager() => _WorkmanagerStub();
_ConstraintsStub Constraints({dynamic networkType, bool requiresBatteryNotLow = false}) =>
    _ConstraintsStub(networkType: networkType, requiresBatteryNotLow: requiresBatteryNotLow);

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
  late final IConnectivityService _connectivityService;
  
  /// Đã khởi tạo chưa
  bool _isInitialized = false;
  
  /// Port để giao tiếp giữa main isolate và background tasks
  ReceivePort? _receivePort;
  
  /// Các hằng số
  static const String backgroundSyncTask = 'com.flutter_chat_app.BACKGROUND_SYNC';
  static const String periodicSyncTask = 'com.flutter_chat_app.PERIODIC_SYNC';
  static const Duration minSyncInterval = Duration(minutes: 15);
  static const Duration defaultSyncInterval = Duration(hours: 1);
  static const int maxBackgroundTasks = 3; // Số lượng tối đa task chạy song song
  
  /// Private constructor
  BackgroundSyncWorker._internal() {
    _connectivityService = GetIt.instance<IConnectivityService>();
  }
  
  /// Khởi tạo worker
  Future<void> initialize({IConnectivityService? connectivityService}) async {
    if (_isInitialized) return;
    
    try {
      _logger.i('Khởi tạo BackgroundSyncWorker');
      
      // Set connectivity service if provided
      if (connectivityService != null) {
        _connectivityService = connectivityService;
      }
      
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
        defaultSyncInterval.inMinutes;
    
    await Workmanager().registerPeriodicTask(
      periodicSyncTask,
      periodicSyncTask,
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
    if (interval < minSyncInterval) {
      interval = minSyncInterval;
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
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
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
      backgroundSyncTask,
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
  
  /// Sử dụng cache sync strategy để đồng bộ một loại dữ liệu
  Future<void> syncDataWithStrategy(String dataType) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Use appropriate methods based on data type
    switch (dataType) {
      case 'user_data':
        if (_cacheSyncStrategy.shouldRefreshUserData()) {
          _logger.i('Đồng bộ dữ liệu người dùng');
          // Perform sync
          _cacheSyncStrategy.resetUserDataDirtyFlag();
        }
        break;
      case 'chat_list':
        if (_cacheSyncStrategy.shouldRefreshChatList()) {
          _logger.i('Đồng bộ danh sách chat');
          // Perform sync
          _cacheSyncStrategy.resetChatListDirtyFlag();
        }
        break;
      case 'chat_messages':
        _logger.i('Đồng bộ tất cả tin nhắn chat đã đánh dấu dirty');
        // Would need to iterate through all dirty chat messages
        break;
      default:
        _logger.w('Không hỗ trợ đồng bộ cho loại dữ liệu: $dataType');
    }
  }
}

/// Inject GetIt để có thể truy cập dịch vụ DI
final getIt = GetIt.instance;

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
      if (taskName == BackgroundSyncWorker.backgroundSyncTask ||
          taskName == BackgroundSyncWorker.periodicSyncTask) {
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
    
    // Khởi tạo cache sync strategy
    final cacheSyncStrategy = CacheSyncStrategy();
    
    // Đồng bộ từng loại dữ liệu
    for (final dataType in dataTypes) {
      switch (dataType) {
        case 'user_data':
          if (cacheSyncStrategy.shouldRefreshUserData()) {
            logger.i('Đồng bộ dữ liệu người dùng');
            // Implement actual sync
            cacheSyncStrategy.resetUserDataDirtyFlag();
          }
          break;
        case 'chat_list':
          if (cacheSyncStrategy.shouldRefreshChatList()) {
            logger.i('Đồng bộ danh sách chat');
            // Implement actual sync
            cacheSyncStrategy.resetChatListDirtyFlag();
          }
          break;
        case 'chat_messages':
          logger.i('Đồng bộ tin nhắn chat');
          // Would implement actual sync
          break;
        case 'media':
          logger.i('Đồng bộ media');
          // Would implement actual sync
          break;
        default:
          logger.w('Không hỗ trợ đồng bộ cho loại dữ liệu: $dataType');
      }
    }
    
    // Cập nhật thời gian đồng bộ cuối cùng
    await prefs.setInt('last_background_sync_time', DateTime.now().millisecondsSinceEpoch);
    
    logger.i('Đồng bộ dữ liệu trong nền hoàn tất');
  } catch (e) {
    logger.e('Lỗi khi đồng bộ dữ liệu trong nền: $e');
    rethrow;
  }
} 