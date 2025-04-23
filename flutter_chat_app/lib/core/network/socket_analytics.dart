import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:injectable/injectable.dart';

import 'socket_manager.dart';
import '../monitoring/analytics_service.dart';

/// Loại metric theo dõi hiệu suất Socket.IO
enum SocketMetricType {
  /// Độ trễ của kết nối
  latency,
  
  /// Số lượng tin nhắn gửi đi
  messagesSent,
  
  /// Số lượng tin nhắn nhận được
  messagesReceived,
  
  /// Số lượng lần kết nối lại
  reconnections,
  
  /// Thời gian hoạt động
  uptime,
  
  /// Thời gian không hoạt động
  downtime,
  
  /// Tỷ lệ lỗi
  errorRate,
}

/// Loại lỗi kết nối Socket.IO
enum SocketErrorType {
  /// Lỗi kết nối mạng
  networkError,
  
  /// Lỗi timeout
  timeout,
  
  /// Lỗi xác thực
  authError,
  
  /// Lỗi từ server
  serverError,
  
  /// Lỗi transport
  transportError,
  
  /// Lỗi khi gửi tin nhắn
  messagingError,
  
  /// Lỗi không xác định
  unknown,
}

/// Class lưu trữ và phân tích dữ liệu về hiệu suất kết nối Socket.IO
@singleton
class SocketAnalytics {
  /// Logger
  final Logger _logger = Logger();
  
  /// SocketManager
  final SocketManager _socketManager;
  
  /// Thời gian bắt đầu kết nối gần nhất
  DateTime? _lastConnectionStartTime;
  
  /// Thời gian gián đoạn gần nhất
  DateTime? _lastDisconnectTime;
  
  /// Thời gian kết nối (ms)
  int _totalConnectionTime = 0;
  
  /// Thời gian gián đoạn (ms)
  int _totalDowntime = 0;
  
  /// Số lượng kết nối thành công
  int _successfulConnections = 0;
  
  /// Số lượng kết nối thất bại
  int _failedConnections = 0;
  
  /// Số lượng kết nối lại
  int _reconnectionCount = 0;
  
  /// Số lượng tin nhắn đã gửi
  int _messagesSent = 0;
  
  /// Số lượng tin nhắn đã nhận
  int _messagesReceived = 0;
  
  /// Số lượng lỗi
  final Map<SocketErrorType, int> _errorCounts = {};
  
  /// Lịch sử độ trễ (ms)
  final Queue<_LatencyRecord> _latencyHistory = Queue<_LatencyRecord>();
  
  /// Subscription theo dõi trạng thái kết nối
  StreamSubscription? _connectionStateSubscription;
  
  /// Thời gian của lần ping gần nhất
  DateTime? _lastPingSent;
  
  /// Thời gian ping-pong timeout (ms)
  static const int _pingPongTimeout = 5000;
  
  /// Số lượng record latency tối đa lưu trữ
  static const int _maxLatencyHistorySize = 50;
  
  final AnalyticsService _analytics;
  
  /// Lớp theo dõi và đo lường hiệu suất kết nối WebSocket
  WebSocketMetrics _webSocketMetrics;
  
  /// Constructor
  SocketAnalytics(this._socketManager, this._analytics) {
    _setupListeners();
    _webSocketMetrics = WebSocketMetrics(this._analytics);
  }
  
  /// Thiết lập các listeners
  void _setupListeners() {
    // Theo dõi trạng thái kết nối
    _connectionStateSubscription = _socketManager.connectionState.listen(_handleConnectionStateChange);
    
    // Đăng ký ping-pong
    _setupPingPongMonitoring();
  }
  
  /// Thiết lập theo dõi độ trễ qua ping-pong
  void _setupPingPongMonitoring() {
    // Đăng ký lắng nghe pong
    _socketManager.on<Map<String, dynamic>>('pong').listen((data) {
      if (_lastPingSent != null) {
        final now = DateTime.now();
        final latencyMs = now.difference(_lastPingSent!).inMilliseconds;
        recordLatency(latencyMs);
        _lastPingSent = null;
      }
    });
  }
  
  /// Xử lý thay đổi trạng thái kết nối
  void _handleConnectionStateChange(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connecting:
        _lastConnectionStartTime = DateTime.now();
        break;
        
      case SocketConnectionState.connected:
        _successfulConnections++;
        if (_lastDisconnectTime != null) {
          final downtime = DateTime.now().difference(_lastDisconnectTime!).inMilliseconds;
          _totalDowntime += downtime;
          _lastDisconnectTime = null;
        }
        break;
        
      case SocketConnectionState.disconnected:
      case SocketConnectionState.error:
        if (state == SocketConnectionState.error) {
          _failedConnections++;
          recordError(SocketErrorType.unknown);
        }
        
        if (_lastConnectionStartTime != null) {
          final connectionTime = DateTime.now().difference(_lastConnectionStartTime!).inMilliseconds;
          _totalConnectionTime += connectionTime;
          _lastConnectionStartTime = null;
        }
        
        _lastDisconnectTime = DateTime.now();
        break;
        
      case SocketConnectionState.reconnecting:
        _reconnectionCount++;
        if (_lastConnectionStartTime != null) {
          final connectionTime = DateTime.now().difference(_lastConnectionStartTime!).inMilliseconds;
          _totalConnectionTime += connectionTime;
        }
        _lastConnectionStartTime = DateTime.now();
        break;
    }
  }
  
  /// Ghi nhận một tin nhắn đã gửi
  void recordMessageSent() {
    _messagesSent++;
    _webSocketMetrics.recordMessageSent();
  }
  
  /// Ghi nhận một tin nhắn đã nhận
  void recordMessageReceived() {
    _messagesReceived++;
    _webSocketMetrics.recordMessageReceived();
  }
  
  /// Ghi nhận một lỗi
  void recordError(SocketErrorType errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    _webSocketMetrics.recordError(errorType.toString());
  }
  
  /// Ghi nhận độ trễ
  void recordLatency(int latencyMs) {
    final record = _LatencyRecord(
      timestamp: DateTime.now(),
      latencyMs: latencyMs,
    );
    
    _latencyHistory.add(record);
    
    // Giới hạn kích thước lịch sử
    if (_latencyHistory.length > _maxLatencyHistorySize) {
      _latencyHistory.removeFirst();
    }
    
    _logger.d('Socket latency: ${latencyMs}ms');
  }
  
  /// Kiểm tra độ trễ bằng cách gửi ping
  Future<int?> checkLatency() async {
    if (_socketManager.currentState != SocketConnectionState.connected) {
      return null;
    }
    
    _lastPingSent = DateTime.now();
    
    final completer = Completer<int?>();
    
    // Thiết lập timeout
    final timeoutTimer = Timer(_pingPongTimeout, () {
      if (!completer.isCompleted) {
        _logger.w('Ping timeout sau ${_pingPongTimeout}ms');
        completer.complete(null);
        recordError(SocketErrorType.timeout);
      }
    });
    
    // Đăng ký one-time handler cho pong
    final subscription = _socketManager.on<Map<String, dynamic>>('pong').listen((data) {
      if (!completer.isCompleted && _lastPingSent != null) {
        final now = DateTime.now();
        final latencyMs = now.difference(_lastPingSent!).inMilliseconds;
        
        timeoutTimer.cancel();
        recordLatency(latencyMs);
        completer.complete(latencyMs);
        
        // Hủy subscription này
        subscription.cancel();
      }
    });
    
    // Gửi ping
    _socketManager.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
    
    return completer.future;
  }
  
  /// Lấy độ trễ trung bình (ms)
  double get averageLatency {
    if (_latencyHistory.isEmpty) return 0;
    final sum = _latencyHistory.fold<int>(0, (sum, record) => sum + record.latencyMs);
    return sum / _latencyHistory.length;
  }
  
  /// Lấy độ trễ thấp nhất (ms)
  int get minLatency {
    if (_latencyHistory.isEmpty) return 0;
    return _latencyHistory.map((record) => record.latencyMs).reduce((min, value) => min < value ? min : value);
  }
  
  /// Lấy độ trễ cao nhất (ms)
  int get maxLatency {
    if (_latencyHistory.isEmpty) return 0;
    return _latencyHistory.map((record) => record.latencyMs).reduce((max, value) => max > value ? max : value);
  }
  
  /// Lấy tỷ lệ uptime (%)
  double get uptimePercentage {
    final totalTime = _totalConnectionTime + _totalDowntime;
    if (totalTime == 0) return 0;
    return (_totalConnectionTime / totalTime) * 100;
  }
  
  /// Lấy tổng số lỗi
  int get totalErrors => _errorCounts.values.fold(0, (sum, count) => sum + count);
  
  /// Lấy tỷ lệ kết nối thành công
  double get connectionSuccessRate {
    final totalConnections = _successfulConnections + _failedConnections;
    if (totalConnections == 0) return 1.0;
    return _successfulConnections / totalConnections;
  }
  
  /// Kiểm tra sức khỏe kết nối
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    // Kiểm tra độ trễ
    final latency = await checkLatency();
    
    // Đánh giá chất lượng kết nối
    String quality = 'unknown';
    if (latency != null) {
      if (latency < 100) {
        quality = 'excellent';
      } else if (latency < 200) {
        quality = 'good';
      } else if (latency < 500) {
        quality = 'fair';
      } else {
        quality = 'poor';
      }
    }
    
    // Cập nhật thời gian kết nối và gián đoạn
    int currentConnectionTime = _totalConnectionTime;
    if (_lastConnectionStartTime != null) {
      currentConnectionTime += DateTime.now().difference(_lastConnectionStartTime!).inMilliseconds;
    }
    
    int currentDowntime = _totalDowntime;
    if (_lastDisconnectTime != null) {
      currentDowntime += DateTime.now().difference(_lastDisconnectTime!).inMilliseconds;
    }
    
    return {
      'connectionState': _socketManager.currentState.toString(),
      'latency': {
        'current': latency,
        'average': averageLatency,
        'min': minLatency,
        'max': maxLatency,
      },
      'quality': quality,
      'connections': {
        'successful': _successfulConnections,
        'failed': _failedConnections,
        'reconnections': _reconnectionCount,
        'successRate': connectionSuccessRate,
      },
      'messages': {
        'sent': _messagesSent,
        'received': _messagesReceived,
      },
      'uptime': {
        'connectionTimeMs': currentConnectionTime,
        'downtimeMs': currentDowntime,
        'uptimePercentage': uptimePercentage,
      },
      'errors': {
        'total': totalErrors,
        'byType': _errorCounts,
      },
    };
  }
  
  /// Reset metrics
  void reset() {
    _lastConnectionStartTime = null;
    _lastDisconnectTime = null;
    _totalConnectionTime = 0;
    _totalDowntime = 0;
    _successfulConnections = 0;
    _failedConnections = 0;
    _reconnectionCount = 0;
    _messagesSent = 0;
    _messagesReceived = 0;
    _errorCounts.clear();
    _latencyHistory.clear();
    _webSocketMetrics.reset();
  }
  
  /// Dispose
  void dispose() {
    _connectionStateSubscription?.cancel();
  }
}

/// Class lưu thông tin về một lần đo độ trễ
class _LatencyRecord {
  /// Thời gian đo
  final DateTime timestamp;
  
  /// Độ trễ (ms)
  final int latencyMs;
  
  /// Constructor
  _LatencyRecord({
    required this.timestamp,
    required this.latencyMs,
  });
}

/// Lớp theo dõi và đo lường hiệu suất kết nối WebSocket
class WebSocketMetrics {
  final AnalyticsService _analytics;
  
  // Các chỉ số theo dõi
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _reconnectAttempts = 0;
  int _errors = 0;
  int _droppedMessages = 0;
  
  // Thời gian kết nối
  final List<int> _connectionTimes = [];
  
  // Độ trễ tin nhắn
  final List<int> _messageLagTimes = [];
  
  // Thời điểm hoạt động cuối cùng
  int _lastActivityTime = 0;
  
  WebSocketMetrics(this._analytics);
  
  /// Ghi nhận thời gian kết nối WebSocket
  void recordConnectionTime(int milliseconds) {
    _connectionTimes.add(milliseconds);
    if (_connectionTimes.length > 10) {
      _connectionTimes.removeAt(0);
    }
    
    _analytics.logEvent(
      AnalyticsEvent.socketConnection, 
      {
        'connection_time_ms': milliseconds,
        'avg_connection_time_ms': averageConnectionTime,
      },
    );
  }
  
  /// Ghi nhận tin nhắn đã gửi
  void recordMessageSent() {
    _messagesSent++;
    _lastActivityTime = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Ghi nhận tin nhắn đã nhận
  void recordMessageReceived({int? size}) {
    _messagesReceived++;
    _lastActivityTime = DateTime.now().millisecondsSinceEpoch;
    
    if (size != null && size > 0) {
      _analytics.logEvent(
        AnalyticsEvent.socketDataReceived,
        {'size_bytes': size},
      );
    }
  }
  
  /// Ghi nhận độ trễ tin nhắn (ping/pong)
  void recordMessageLag(int milliseconds) {
    _messageLagTimes.add(milliseconds);
    if (_messageLagTimes.length > 50) {
      _messageLagTimes.removeAt(0);
    }
    
    if (milliseconds > 1000) {
      _analytics.logEvent(
        AnalyticsEvent.socketHighLatency,
        {'latency_ms': milliseconds},
      );
    }
  }
  
  /// Ghi nhận lỗi WebSocket
  void recordError(String error) {
    _errors++;
    _analytics.logEvent(
      AnalyticsEvent.socketError,
      {'error_message': error},
    );
  }
  
  /// Ghi nhận nỗ lực kết nối lại
  void recordReconnectAttempt() {
    _reconnectAttempts++;
    _analytics.logEvent(
      AnalyticsEvent.socketReconnect,
      {'attempt_count': _reconnectAttempts},
    );
  }
  
  /// Ghi nhận tin nhắn bị hủy
  void recordDroppedMessage() {
    _droppedMessages++;
  }
  
  /// Thời gian trung bình để kết nối
  int get averageConnectionTime {
    if (_connectionTimes.isEmpty) {
      return 0;
    }
    return _connectionTimes.reduce((a, b) => a + b) ~/ _connectionTimes.length;
  }
  
  /// Độ trễ tin nhắn trung bình
  int get averageMessageLag {
    if (_messageLagTimes.isEmpty) {
      return 0;
    }
    return _messageLagTimes.reduce((a, b) => a + b) ~/ _messageLagTimes.length;
  }
  
  /// Kiểm tra xem kết nối có ổn định không
  bool get isConnectionStable {
    // Kết nối được coi là ổn định nếu độ trễ trung bình < 300ms
    return averageMessageLag < 300 && _errors == 0;
  }
  
  /// Lấy thời gian kể từ hoạt động cuối cùng
  int get timeSinceLastActivity {
    if (_lastActivityTime == 0) {
      return 0;
    }
    return DateTime.now().millisecondsSinceEpoch - _lastActivityTime;
  }
  
  /// Tính phần trăm tin nhắn bị mất
  double get packetLossPercentage {
    if (_messagesSent == 0) {
      return 0.0;
    }
    return (_droppedMessages / _messagesSent) * 100;
  }
  
  /// Đặt lại tất cả các chỉ số
  void reset() {
    _messagesSent = 0;
    _messagesReceived = 0;
    _reconnectAttempts = 0;
    _errors = 0;
    _droppedMessages = 0;
    _connectionTimes.clear();
    _messageLagTimes.clear();
    _lastActivityTime = 0;
  }
  
  /// Gửi báo cáo về chỉ số hiệu suất
  void reportMetrics() {
    if (!kReleaseMode) {
      return;
    }
    
    _analytics.logEvent(
      AnalyticsEvent.socketStats,
      {
        'messages_sent': _messagesSent,
        'messages_received': _messagesReceived,
        'reconnect_attempts': _reconnectAttempts,
        'errors': _errors,
        'dropped_messages': _droppedMessages,
        'avg_connection_time_ms': averageConnectionTime,
        'avg_message_lag_ms': averageMessageLag,
        'packet_loss_pct': packetLossPercentage,
      },
    );
  }
} 