import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'socket_analytics.dart';
import 'socket_manager.dart';
import 'socket_rate_limiter.dart';

/// Manager nâng cao cho Socket.IO với các tính năng mở rộng
@singleton
class EnhancedSocketManager {
  /// Logger
  final Logger _logger = Logger();
  
  /// Socket Manager gốc
  final SocketManager _socketManager;
  
  /// Socket Analytics để theo dõi hiệu suất
  final SocketAnalytics _analytics;
  
  /// Rate Limiter
  final SocketRateLimiter _rateLimiter;
  
  /// Danh sách subscription cần dọn dẹp
  final List<StreamSubscription> _subscriptions = [];
  
  /// Controller theo dõi chất lượng mạng
  final BehaviorSubject<NetworkQuality> _networkQualityController = 
      BehaviorSubject<NetworkQuality>.seeded(NetworkQuality.unknown);
  
  /// Controller theo dõi các lỗi
  final PublishSubject<SocketError> _errorController = PublishSubject<SocketError>();
  
  /// Timer kiểm tra chất lượng kết nối định kỳ
  Timer? _qualityCheckTimer;
  
  /// Timer cho việc sync offline message
  Timer? _offlineSyncTimer;
  
  /// Danh sách tin nhắn đã gửi trong khi offline
  final List<_OfflineMessage> _offlineMessages = [];
  
  /// Có đang ở chế độ offline-first không
  bool _offlineFirstMode = false;
  
  /// Constructor
  EnhancedSocketManager(
    this._socketManager,
    this._analytics,
    this._rateLimiter,
  ) {
    _initialize();
  }
  
  /// Trả về stream theo dõi trạng thái kết nối
  Stream<SocketConnectionState> get connectionState => _socketManager.connectionState;
  
  /// Trả về trạng thái kết nối hiện tại
  SocketConnectionState get currentState => _socketManager.currentState;
  
  /// Trả về stream theo dõi chất lượng mạng
  Stream<NetworkQuality> get networkQuality => _networkQualityController.stream;
  
  /// Trả về chất lượng mạng hiện tại
  NetworkQuality get currentNetworkQuality => _networkQualityController.value;
  
  /// Trả về stream theo dõi lỗi
  Stream<SocketError> get errors => _errorController.stream;
  
  /// Khởi tạo
  void _initialize() {
    // Lắng nghe sự thay đổi trạng thái kết nối
    _subscriptions.add(
      _socketManager.connectionState.listen(_handleConnectionStateChange)
    );
    
    // Khởi động timer kiểm tra chất lượng kết nối
    _startQualityCheck();
  }
  
  /// Xử lý thay đổi trạng thái kết nối
  void _handleConnectionStateChange(SocketConnectionState state) {
    if (state == SocketConnectionState.connected) {
      // Nếu kết nối lại sau khi disconnect, thử sync tin nhắn offline
      _syncOfflineMessages();
    }
  }
  
  /// Khởi động timer kiểm tra chất lượng kết nối
  void _startQualityCheck() {
    _qualityCheckTimer?.cancel();
    
    // Kiểm tra mỗi 30 giây
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final health = await _analytics.checkConnectionHealth();
        
        // Cập nhật chất lượng mạng
        final quality = _mapQualityFromHealth(health);
        if (quality != _networkQualityController.value) {
          _networkQualityController.add(quality);
          
          _logger.i('Chất lượng mạng: $quality (latency: ${health['latency']['current']}ms)');
        }
      } catch (e) {
        _logger.e('Lỗi khi kiểm tra chất lượng kết nối: $e');
      }
    });
    
    // Thực hiện kiểm tra ngay lập tức
    _checkNetworkQuality();
  }
  
  /// Kiểm tra chất lượng mạng
  Future<void> _checkNetworkQuality() async {
    try {
      final health = await _analytics.checkConnectionHealth();
      
      // Cập nhật chất lượng mạng
      final quality = _mapQualityFromHealth(health);
      _networkQualityController.add(quality);
      
      _logger.i('Chất lượng mạng: $quality (latency: ${health['latency']['current']}ms)');
    } catch (e) {
      _logger.e('Lỗi khi kiểm tra chất lượng kết nối: $e');
    }
  }
  
  /// Chuyển đổi từ health data sang NetworkQuality
  NetworkQuality _mapQualityFromHealth(Map<String, dynamic> health) {
    final quality = health['quality'] as String;
    
    switch (quality) {
      case 'excellent':
        return NetworkQuality.excellent;
      case 'good':
        return NetworkQuality.good;
      case 'fair':
        return NetworkQuality.fair;
      case 'poor':
        return NetworkQuality.poor;
      default:
        return NetworkQuality.unknown;
    }
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
        _offlineMessages.add(_OfflineMessage(
          event: event,
          data: data,
          timestamp: DateTime.now(),
        ));
        
        _logger.i('Đã lưu tin nhắn $event để gửi khi online');
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
    
    // Lắng nghe sự kiện ack
    final subscription = _socketManager.on<Map<String, dynamic>>('${event}_ack').listen((response) {
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
        ...data is Map ? data as Map : {'data': data},
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
  
  /// Đồng bộ tin nhắn đã gửi khi offline
  void _syncOfflineMessages() {
    if (_offlineMessages.isEmpty) return;
    
    _logger.i('Bắt đầu đồng bộ ${_offlineMessages.length} tin nhắn offline');
    
    _offlineSyncTimer?.cancel();
    _offlineSyncTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_offlineMessages.isEmpty) {
        timer.cancel();
        _logger.i('Đã đồng bộ xong tin nhắn offline');
        return;
      }
      
      if (_socketManager.currentState == SocketConnectionState.connected) {
        final message = _offlineMessages.removeAt(0);
        
        _logger.d('Đồng bộ tin nhắn offline: ${message.event} (${_offlineMessages.length} còn lại)');
        
        try {
          emit(message.event, message.data);
        } catch (e) {
          _logger.e('Lỗi khi đồng bộ tin nhắn offline: $e');
        }
      } else {
        timer.cancel();
        _logger.w('Kết nối bị mất, dừng đồng bộ tin nhắn offline');
      }
    });
  }
  
  /// Kiểm tra hiệu suất kết nối
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    return await _analytics.checkConnectionHealth();
  }
  
  /// Kiểm tra độ trễ kết nối
  Future<int?> checkLatency() async {
    return await _analytics.checkLatency();
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
    
    // Dừng các timer không cần thiết khi ở background
    _qualityCheckTimer?.cancel();
  }
  
  /// Chuyển sang chế độ foreground
  void enterForegroundMode() {
    _socketManager.enterForegroundMode();
    
    // Khởi động lại các timer
    _startQualityCheck();
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    // Hủy các timer
    _qualityCheckTimer?.cancel();
    _offlineSyncTimer?.cancel();
    
    // Hủy các subscription
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Đóng các controller
    _networkQualityController.close();
    _errorController.close();
    
    _logger.i('Enhanced Socket Manager đã được giải phóng');
  }
}

/// Enum định nghĩa chất lượng mạng
enum NetworkQuality {
  /// Chất lượng rất tốt (độ trễ < 100ms)
  excellent,
  
  /// Chất lượng tốt (độ trễ < 200ms)
  good,
  
  /// Chất lượng trung bình (độ trễ < 500ms)
  fair,
  
  /// Chất lượng kém (độ trễ >= 500ms)
  poor,
  
  /// Không xác định
  unknown,
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

/// Class lưu trữ tin nhắn để gửi khi offline
class _OfflineMessage {
  /// Loại sự kiện
  final String event;
  
  /// Dữ liệu sự kiện
  final dynamic data;
  
  /// Thời gian tạo
  final DateTime timestamp;
  
  /// Constructor
  _OfflineMessage({
    required this.event,
    required this.data,
    required this.timestamp,
  });
} 