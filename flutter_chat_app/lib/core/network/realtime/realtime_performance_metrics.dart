import 'dart:collection';

/// Class lưu trữ metrics cho RealtimeConnectionService
class RealtimePerformanceMetrics {
  /// Số lượng kết nối thành công
  int _successfulConnections = 0;
  
  /// Số lượng kết nối thất bại
  int _failedConnections = 0;
  
  /// Số lượng lần thử kết nối lại
  int _reconnectAttempts = 0;
  
  /// Số lượng tin nhắn đã gửi
  int _messagesSent = 0;
  
  /// Số lượng tin nhắn đã nhận
  int _messagesReceived = 0;
  
  /// Số lượng tin nhắn gửi thất bại
  int _failedMessages = 0;
  
  /// Thời gian kết nối (ms)
  int _connectionTime = 0;
  
  /// Thời gian bắt đầu kết nối gần nhất
  DateTime? _lastConnectionStartTime;
  
  /// Lịch sử độ trễ (ms)
  final Queue<LatencyRecord> _latencyHistory = Queue<LatencyRecord>();
  
  /// Số lượng các lỗi
  final Map<String, int> _errorCounts = {};
  
  /// Thời gian gián đoạn (ms)
  int _totalDowntime = 0;
  
  /// Thời gian bắt đầu gián đoạn gần nhất
  DateTime? _lastDisconnectTime;
  
  /// Số lượng record latency tối đa lưu trữ
  static const int _maxLatencyHistorySize = 50;
  
  /// Constructor
  RealtimePerformanceMetrics();
  
  /// Reset metrics
  void reset() {
    _successfulConnections = 0;
    _failedConnections = 0;
    _reconnectAttempts = 0;
    _messagesSent = 0;
    _messagesReceived = 0;
    _failedMessages = 0;
    _connectionTime = 0;
    _lastConnectionStartTime = null;
    _latencyHistory.clear();
    _errorCounts.clear();
    _totalDowntime = 0;
    _lastDisconnectTime = null;
  }
  
  /// Ghi nhận bắt đầu kết nối
  void recordConnectionStart() {
    _lastConnectionStartTime = DateTime.now();
  }
  
  /// Ghi nhận kết nối thành công
  void recordConnectionSuccess() {
    _successfulConnections++;
    _lastDisconnectTime = null;
  }
  
  /// Ghi nhận kết nối thất bại
  void recordConnectionFailure() {
    _failedConnections++;
    _lastConnectionStartTime = null;
    
    if (_lastDisconnectTime == null) {
      _lastDisconnectTime = DateTime.now();
    }
  }
  
  /// Ghi nhận thử kết nối lại
  void recordReconnectAttempt() {
    _reconnectAttempts++;
  }
  
  /// Ghi nhận ngắt kết nối
  void recordDisconnect() {
    final now = DateTime.now();
    
    // Cập nhật thời gian kết nối
    if (_lastConnectionStartTime != null) {
      _connectionTime += now.difference(_lastConnectionStartTime!).inMilliseconds;
      _lastConnectionStartTime = null;
    }
    
    // Bắt đầu tính thời gian gián đoạn
    _lastDisconnectTime = now;
  }
  
  /// Ghi nhận lỗi
  void recordError(String errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
  }
  
  /// Ghi nhận gửi tin nhắn
  void recordMessageSent() {
    _messagesSent++;
  }
  
  /// Ghi nhận nhận tin nhắn
  void recordMessageReceived() {
    _messagesReceived++;
  }
  
  /// Ghi nhận gửi tin nhắn thất bại
  void recordMessageFailed() {
    _failedMessages++;
  }
  
  /// Ghi nhận độ trễ
  void recordLatency(int latencyMs) {
    final record = LatencyRecord(
      timestamp: DateTime.now(),
      latencyMs: latencyMs,
    );
    
    _latencyHistory.add(record);
    
    // Giới hạn kích thước lịch sử
    if (_latencyHistory.length > _maxLatencyHistorySize) {
      _latencyHistory.removeFirst();
    }
  }
  
  /// Cập nhật thời gian gián đoạn nếu đang gián đoạn
  void updateDowntime() {
    if (_lastDisconnectTime != null) {
      final now = DateTime.now();
      _totalDowntime = now.difference(_lastDisconnectTime!).inMilliseconds;
    }
  }
  
  // Getters
  
  /// Số lượng kết nối thành công
  int get successfulConnections => _successfulConnections;
  
  /// Số lượng kết nối thất bại
  int get failedConnections => _failedConnections;
  
  /// Số lượng lần thử kết nối lại
  int get reconnectAttempts => _reconnectAttempts;
  
  /// Số lượng tin nhắn đã gửi
  int get messagesSent => _messagesSent;
  
  /// Số lượng tin nhắn đã nhận
  int get messagesReceived => _messagesReceived;
  
  /// Số lượng tin nhắn gửi thất bại
  int get failedMessages => _failedMessages;
  
  /// Thời gian kết nối (ms)
  int get connectionTime {
    int total = _connectionTime;
    
    // Nếu đang kết nối, thêm thời gian hiện tại
    if (_lastConnectionStartTime != null) {
      total += DateTime.now().difference(_lastConnectionStartTime!).inMilliseconds;
    }
    
    return total;
  }
  
  /// Thời gian kết nối theo phần trăm (uptime %)
  double get uptimePercentage {
    final total = connectionTime + _totalDowntime;
    if (total == 0) return 0;
    return (connectionTime / total) * 100;
  }
  
  /// Lịch sử độ trễ
  List<LatencyRecord> get latencyHistory => List.unmodifiable(_latencyHistory);
  
  /// Độ trễ trung bình (ms)
  double get averageLatency {
    if (_latencyHistory.isEmpty) return 0;
    final sum = _latencyHistory.fold<int>(0, (sum, record) => sum + record.latencyMs);
    return sum / _latencyHistory.length;
  }
  
  /// Độ trễ thấp nhất (ms)
  int get minLatency {
    if (_latencyHistory.isEmpty) return 0;
    return _latencyHistory.map((record) => record.latencyMs).reduce((min, value) => min < value ? min : value);
  }
  
  /// Độ trễ cao nhất (ms)
  int get maxLatency {
    if (_latencyHistory.isEmpty) return 0;
    return _latencyHistory.map((record) => record.latencyMs).reduce((max, value) => max > value ? max : value);
  }
  
  /// Thống kê lỗi
  Map<String, int> get errorCounts => Map.unmodifiable(_errorCounts);
  
  /// Tổng số lỗi
  int get totalErrors => _errorCounts.values.fold(0, (sum, count) => sum + count);
  
  /// Thời gian gián đoạn (ms)
  int get totalDowntime {
    updateDowntime();
    return _totalDowntime;
  }
  
  /// Tỷ lệ tin nhắn thành công
  double get messageSuccessRate {
    final total = _messagesSent + _failedMessages;
    if (total == 0) return 1.0;
    return _messagesSent / total;
  }
  
  /// Tỷ lệ kết nối thành công
  double get connectionSuccessRate {
    final total = _successfulConnections + _failedConnections;
    if (total == 0) return 1.0;
    return _successfulConnections / total;
  }
  
  /// Thông tin tóm tắt
  Map<String, dynamic> toJson() {
    updateDowntime();
    
    return {
      'connections': {
        'successful': _successfulConnections,
        'failed': _failedConnections,
        'reconnectAttempts': _reconnectAttempts,
        'successRate': connectionSuccessRate,
      },
      'messages': {
        'sent': _messagesSent,
        'received': _messagesReceived,
        'failed': _failedMessages,
        'successRate': messageSuccessRate,
      },
      'latency': {
        'average': averageLatency,
        'min': minLatency,
        'max': maxLatency,
      },
      'uptime': {
        'connectionTimeMs': connectionTime,
        'downtimeMs': _totalDowntime,
        'uptimePercentage': uptimePercentage,
      },
      'errors': _errorCounts,
      'totalErrors': totalErrors,
    };
  }
}

/// Record lưu thông tin về độ trễ
class LatencyRecord {
  /// Thời gian đo
  final DateTime timestamp;
  
  /// Độ trễ (ms)
  final int latencyMs;
  
  /// Constructor
  LatencyRecord({
    required this.timestamp,
    required this.latencyMs,
  });
} 