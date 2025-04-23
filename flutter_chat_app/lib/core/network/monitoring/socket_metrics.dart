import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../monitoring/analytics_service.dart';
import 'package:logger/logger.dart';

/// Class theo dõi các chỉ số hiệu suất cho kết nối WebSocket
class WebSocketMetrics {
  final AnalyticsService _analytics;
  final Logger _logger;
  
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
  
  // Kích thước tối đa cho mảng thời gian kết nối
  static const int _maxConnectionTimesSize = 10;
  
  // Kích thước tối đa cho mảng độ trễ tin nhắn
  static const int _maxLagTimesSize = 50;
  
  /// Constructor
  WebSocketMetrics(this._analytics, {Logger? logger}) 
    : _logger = logger ?? Logger();

  /// Getter để lấy tổng số tin nhắn đã gửi
  int get totalSentMessages => _messagesSent;
  
  /// Getter để lấy tổng số tin nhắn đã nhận
  int get totalReceivedMessages => _messagesReceived;
  
  /// Getter để lấy tổng số lần kết nối lại
  int get reconnectAttempts => _reconnectAttempts;
  
  /// Getter để lấy tổng số lỗi
  int get totalErrors => _errors;
  
  /// Getter để lấy tổng số tin nhắn bị mất
  int get droppedMessages => _droppedMessages;

  /// Ghi nhận thời gian kết nối WebSocket
  void recordConnectionTime(int milliseconds) {
    _connectionTimes.add(milliseconds);
    if (_connectionTimes.length > _maxConnectionTimesSize) {
      _connectionTimes.removeAt(0);
    }
    
    _analytics.logEvent(
      name: 'socket_connection_time',
      parameters: {
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
        name: 'socket_data_received',
        parameters: {
          'size_bytes': size
        },
      );
    }
  }
  
  /// Ghi nhận độ trễ tin nhắn (ping/pong)
  void recordMessageLag(int milliseconds) {
    _messageLagTimes.add(milliseconds);
    if (_messageLagTimes.length > _maxLagTimesSize) {
      _messageLagTimes.removeAt(0);
    }
    
    if (milliseconds > 1000) {
      _analytics.logEvent(
        name: 'socket_high_latency',
        parameters: {
          'latency_ms': milliseconds
        },
      );
    }
  }
  
  /// Ghi nhận lỗi WebSocket
  void recordError(String error) {
    _errors++;
    _logger.e('WebSocket error: $error');
    _analytics.logEvent(
      name: 'socket_error',
      parameters: {
        'error_message': error
      },
    );
  }
  
  /// Ghi nhận nỗ lực kết nối lại
  void recordReconnectAttempt() {
    _reconnectAttempts++;
    _analytics.logEvent(
      name: 'socket_reconnect_attempt',
      parameters: {
        'attempt_count': _reconnectAttempts
      },
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
    // Kết nối được coi là ổn định nếu độ trễ trung bình < 300ms và không có lỗi gần đây
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
    final totalSent = _messagesSent + _droppedMessages;
    if (totalSent == 0) {
      return 0.0;
    }
    return (_droppedMessages / totalSent) * 100;
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
      name: 'socket_performance_stats',
      parameters: {
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
    
    _logger.d('WebSocket performance metrics reported');
  }
} 