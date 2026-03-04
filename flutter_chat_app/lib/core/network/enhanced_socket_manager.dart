import 'dart:async';

import 'package:flutter_chat_app/core/network/handlers/offline_message_handler.dart';
import 'package:flutter_chat_app/core/network/models/network_quality.dart' as models;
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/core/network/monitoring/network_quality_monitor.dart';
import 'package:flutter_chat_app/core/network/socket_analytics.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_chat_app/core/network/socket_rate_limiter.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

/// Manager nâng cao cho Socket.IO với các tính năng mở rộng
@lazySingleton
class EnhancedSocketManager {
  /// Logger
  final Logger _logger;
  
  /// Socket Manager gốc
  final SocketManager _socketManager;
  
  /// Socket Analytics để theo dõi hiệu suất
  final SocketAnalytics _analytics;
  
  /// Rate Limiter
  final SocketRateLimiter _rateLimiter;
  
  /// Handler xử lý tin nhắn offline
  late final OfflineMessageHandler _offlineHandler;
  
  /// Network Quality Monitor
  late final NetworkQualityMonitor _qualityMonitor;
  
  /// Danh sách subscription cần dọn dẹp
  final List<StreamSubscription> _subscriptions = [];

  /// Danh sách StreamController cần dọn dẹp
  final List<StreamController> _streamControllers = [];
  
  /// Controller theo dõi chất lượng mạng
  final BehaviorSubject<models.NetworkQuality> _networkQualityController = 
      BehaviorSubject<models.NetworkQuality>.seeded(models.NetworkQuality.unknown);
  
  /// Controller theo dõi các lỗi
  final PublishSubject<SocketError> _errorController = PublishSubject<SocketError>();
  
  /// Có đang ở chế độ offline-first không
  bool _offlineFirstMode = false;
  
  /// Constructor
  EnhancedSocketManager(
    this._socketManager,
    this._analytics,
    this._rateLimiter,
  ) : _logger = Logger() {
    _initialize();
  }
  
  /// Khởi tạo
  void _initialize() {
    // Khởi tạo các handlers
    _offlineHandler = OfflineMessageHandler(
      sendFunction: _sendOfflineMessage,
      logger: _logger,
    );
    
    _qualityMonitor = NetworkQualityMonitor(
      analytics: _analytics,
      onQualityChanged: _handleQualityChange,
      logger: _logger,
    );
    
    // Lắng nghe sự thay đổi trạng thái kết nối
    _subscriptions.add(
      _socketManager.connectionState.listen(_handleConnectionStateChange)
    );
    
    // Khởi động quality monitor
    _qualityMonitor.start();
  }
  
  /// Trả về stream theo dõi trạng thái kết nối
  Stream<SocketConnectionState> get connectionState => _socketManager.connectionState;
  
  /// Trả về trạng thái kết nối hiện tại
  SocketConnectionState get currentState => _socketManager.currentState;
  
  /// Trả về stream theo dõi chất lượng mạng
  Stream<models.NetworkQuality> get networkQuality => _networkQualityController.stream;
  
  /// Trả về chất lượng mạng hiện tại
  models.NetworkQuality get currentNetworkQuality => _networkQualityController.value;
  
  /// Trả về stream theo dõi lỗi
  Stream<SocketError> get errors => _errorController.stream;
  
  /// Xử lý thay đổi trạng thái kết nối
  void _handleConnectionStateChange(SocketConnectionState state) {
    if (state == SocketConnectionState.connected) {
      // Nếu kết nối lại sau khi disconnect, thử sync tin nhắn offline
      if (_offlineHandler.hasPendingMessages) {
        _syncOfflineMessages();
      }
    }
  }
  
  /// Xử lý thay đổi chất lượng mạng
  void _handleQualityChange(models.NetworkQuality quality) {
    _networkQualityController.add(quality);
  }
  
  /// Kết nối socket
  Future<void> connect() async {
    await _socketManager.connect();
  }
  
  /// Ngắt kết nối socket
  Future<void> disconnect() async {
    await _socketManager.disconnect();
  }
  
  /// Đăng ký lắng nghe một sự kiện
  Stream<T> on<T>(String event) {
    // Xử lý message received analytics
    final streamController = BehaviorSubject<T>();

    // Track StreamController để close sau này
    _streamControllers.add(streamController);

    final subscription = _socketManager.on<T>(event).listen((data) {
      if (!streamController.isClosed) {
        // Ghi nhận tin nhắn nhận được
        _analytics.recordMessageReceived();

        streamController.add(data);
      }
    });

    // Lưu subscription để dọn dẹp sau này
    _subscriptions.add(subscription);

    return streamController.stream;
  }
  
  /// Phát sự kiện với kiểm soát rate limit
  void emit(String event, [dynamic data]) {
    // Kiểm tra có đang offline không
    if (_socketManager.currentState != SocketConnectionState.connected) {
      if (_offlineFirstMode) {
        // Lưu tin nhắn để gửi sau
        _offlineHandler.enqueueEvent(event, data);
      } else {
        _logger.w('Socket không được kết nối, bỏ qua sự kiện: $event');
      }
      return;
    }
    
    // Kiểm tra rate limit
    final rateLimitResult = _rateLimiter.checkRateLimit(event);
    
    if (rateLimitResult.allowed) {
      // Gửi tin nhắn ngay
      _socketManager.emit(event, data);
      
      // Ghi nhận tin nhắn đã gửi
      _rateLimiter.recordMessage(event);
      _analytics.recordMessageSent();
    } else {
      // Queued message
      _rateLimiter.enqueueMessage(event, data, (d) {
        _socketManager.emit(event, d);
        _analytics.recordMessageSent();
      });
      
      // Thông báo lỗi rate limit
      _errorController.add(SocketError(
        type: SocketErrorType.rateLimited,
        message: 'Rate limit exceeded for event: $event',
        details: rateLimitResult.info,
      ));
    }
  }
  
  /// Phát sự kiện và đợi phản hồi
  Future<T?> emitWithAck<T>(String event, [dynamic data, Duration timeout = const Duration(seconds: 10)]) async {
    if (_socketManager.currentState != SocketConnectionState.connected) {
      _logger.w('Socket không được kết nối, không thể gửi sự kiện: $event');
      throw SocketError(
        type: SocketErrorType.networkError,
        message: 'Socket không được kết nối',
      );
    }
    
    // Kiểm tra rate limit
    final rateLimitResult = _rateLimiter.checkRateLimit(event);
    
    if (!rateLimitResult.allowed) {
      throw SocketError(
        type: SocketErrorType.rateLimited,
        message: 'Rate limit exceeded for event: $event',
        details: rateLimitResult.info,
      );
    }
    
    // Tạo completer
    final completer = Completer<T?>();
    
    // Tạo một ID duy nhất cho ack này
    final ackId = 'ack_${DateTime.now().millisecondsSinceEpoch}_${(data ?? '').hashCode}';
    
    late StreamSubscription subscription;
    
    // Lắng nghe sự kiện ack
    subscription = _socketManager.on<Map<String, dynamic>>('${event}_ack').listen((response) {
      if (response['id'] == ackId && !completer.isCompleted) {
        completer.complete(response['data'] as T?);
        subscription.cancel();
      }
    });
    
    // Thiết lập timeout
    final timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(SocketError(
          type: SocketErrorType.timeout,
          message: 'Timeout waiting for ack on event: $event',
        ));
        subscription.cancel();
      }
    });
    
    try {
      // Gửi sự kiện
      _socketManager.emit(event, {
        ...data is Map ? data : {'data': data},
        'ackId': ackId,
      });
      
      // Ghi nhận tin nhắn đã gửi
      _rateLimiter.recordMessage(event);
      _analytics.recordMessageSent();
      
      // Đợi kết quả
      return await completer.future;
    } catch (e) {
      if (e is SocketError) {
        rethrow;
      } else {
        throw SocketError(
          type: SocketErrorType.unknown,
          message: 'Error sending event $event: $e',
        );
      }
    } finally {
      timeoutTimer.cancel();
      subscription.cancel();
    }
  }
  
  /// Bật chế độ offline-first
  void enableOfflineFirstMode() {
    _offlineFirstMode = true;
    _logger.i('Đã bật chế độ offline-first');
  }
  
  /// Tắt chế độ offline-first
  void disableOfflineFirstMode() {
    _offlineFirstMode = false;
    _logger.i('Đã tắt chế độ offline-first');
  }
  
  /// Hàm callback để gửi tin nhắn offline
  Future<bool> _sendOfflineMessage(String event, dynamic data) async {
    if (_socketManager.currentState != SocketConnectionState.connected) {
      return false;
    }
    
    try {
      emit(event, data);
      return true;
    } catch (e) {
      _logger.e('Lỗi khi gửi tin nhắn offline: $e');
      return false;
    }
  }
  
  /// Đồng bộ tin nhắn đã gửi khi offline
  void _syncOfflineMessages() {
    _offlineHandler.syncMessages(
      isConnected: () => _socketManager.currentState == SocketConnectionState.connected,
      onProgress: (progress) {
        _logger.d('Tiến độ đồng bộ tin nhắn: $progress');
      },
      onComplete: (total) {
        _logger.i('Hoàn thành đồng bộ $total tin nhắn offline');
      },
    );
  }
  
  /// Kiểm tra hiệu suất kết nối
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    return _analytics.checkConnectionHealth();
  }

  /// Kiểm tra độ trễ kết nối
  Future<int?> checkLatency() async {
    return _analytics.checkLatency();
  }
  
  /// Lấy thông tin rate limit cho một event
  RateLimitInfo getRateLimitInfo(String eventType) {
    return _rateLimiter.getRateLimitInfo(eventType);
  }
  
  /// Đặt rate limit cho một event cụ thể
  void setEventRateLimit(String eventType, int limit) {
    _rateLimiter.setEventRateLimit(eventType, limit);
  }
  
  /// Chuyển sang chế độ background để tiết kiệm pin
  void enterBackgroundMode() {
    _socketManager.enterBackgroundMode();
    
    // Dừng các monitor không cần thiết khi ở background
    _qualityMonitor.stop();
  }
  
  /// Chuyển sang chế độ foreground
  void enterForegroundMode() {
    _socketManager.enterForegroundMode();
    
    // Khởi động lại các monitor
    _qualityMonitor.start();
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    // Dừng các monitor
    _qualityMonitor.stop();
    
    // Hủy đồng bộ offline
    _offlineHandler.dispose();
    
    // Hủy các subscription
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Đóng tất cả StreamController được tạo động
    for (final controller in _streamControllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _streamControllers.clear();

    // Đóng các controller chính
    _networkQualityController.close();
    _errorController.close();
    
    _logger.i('Enhanced Socket Manager đã được giải phóng');
  }
}

/// Class mô tả lỗi Socket.IO
class SocketError {
  /// Loại lỗi
  final SocketErrorType type;
  
  /// Thông báo lỗi
  final String message;
  
  /// Chi tiết bổ sung
  final dynamic details;
  
  /// Thời gian xảy ra lỗi
  final DateTime timestamp;
  
  /// Constructor
  SocketError({
    required this.type,
    required this.message,
    this.details,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() => 'SocketError($type): $message';
}

/// Enum định nghĩa các loại lỗi Socket.IO
enum SocketErrorType {
  /// Lỗi mạng
  networkError,
  
  /// Lỗi timeout
  timeout,
  
  /// Lỗi xác thực
  authError,
  
  /// Lỗi rate limit
  rateLimited,
  
  /// Lỗi từ server
  serverError,
  
  /// Lỗi không xác định
  unknown,
} 