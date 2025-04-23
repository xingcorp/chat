import 'dart:collection';
import 'dart:math' as math;

/// Class lưu trữ metrics cho RealtimeConnectionService
/// Tối ưu bộ nhớ, hiệu suất tính toán và khả năng phân tích dữ liệu
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
  
  /// Lịch sử độ trễ (ms) lưu theo sliding window để tối ưu bộ nhớ
  final Queue<LatencyRecord> _latencyHistory = Queue<LatencyRecord>();
  
  /// Số lượng các lỗi
  final Map<String, int> _errorCounts = {};
  
  /// Thời gian gián đoạn (ms)
  int _totalDowntime = 0;
  
  /// Thời gian bắt đầu gián đoạn gần nhất
  DateTime? _lastDisconnectTime;
  
  /// Số lượng record latency tối đa lưu trữ
  static const int _maxLatencyHistorySize = 50;
  
  /// Kích thước cửa sổ thời gian để tính toán thống kê gần đây (ms)
  static const int _recentWindowSize = 5 * 60 * 1000; // 5 phút
  
  /// Danh sách thời gian gửi tin nhắn để tính tốc độ
  final List<DateTime> _messageSendTimes = [];
  
  /// Danh sách thời gian nhận tin nhắn để tính tốc độ
  final List<DateTime> _messageReceiveTimes = [];
  
  /// Độ trễ tích lũy cho tính toán p50, p90, p95, p99
  final List<int> _sortedLatencies = [];
  
  /// Thống kê chia theo khoảng thời gian (1 phút)
  final Map<String, _TimeWindowStats> _timeWindowStats = {};
  
  /// Thời điểm tracking bắt đầu
  final DateTime _trackingStartedAt = DateTime.now();
  
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
    _messageSendTimes.clear();
    _messageReceiveTimes.clear();
    _sortedLatencies.clear();
    _timeWindowStats.clear();
  }
  
  /// Ghi nhận bắt đầu kết nối
  void recordConnectionStart() {
    _lastConnectionStartTime = DateTime.now();
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận kết nối thành công
  void recordConnectionSuccess() {
    _successfulConnections++;
    _lastDisconnectTime = null;
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận kết nối thất bại
  void recordConnectionFailure() {
    _failedConnections++;
    _lastConnectionStartTime = null;
    
    if (_lastDisconnectTime == null) {
      _lastDisconnectTime = DateTime.now();
    }
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận thử kết nối lại
  void recordReconnectAttempt() {
    _reconnectAttempts++;
    _updateCurrentWindowStats();
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
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận lỗi
  void recordError(String errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận gửi tin nhắn
  void recordMessageSent() {
    _messagesSent++;
    _messageSendTimes.add(DateTime.now());
    
    // Giới hạn số lượng thời gian lưu trữ để tính tốc độ
    if (_messageSendTimes.length > 100) {
      _messageSendTimes.removeAt(0);
    }
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận nhận tin nhắn
  void recordMessageReceived() {
    _messagesReceived++;
    _messageReceiveTimes.add(DateTime.now());
    
    // Giới hạn số lượng thời gian lưu trữ để tính tốc độ
    if (_messageReceiveTimes.length > 100) {
      _messageReceiveTimes.removeAt(0);
    }
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận gửi tin nhắn thất bại
  void recordMessageFailed() {
    _failedMessages++;
    _updateCurrentWindowStats();
  }
  
  /// Ghi nhận độ trễ
  void recordLatency(int latencyMs) {
    final record = LatencyRecord(
      timestamp: DateTime.now(),
      latencyMs: latencyMs,
    );
    
    _latencyHistory.add(record);
    
    // Thêm vào danh sách đã sắp xếp để tính percentiles
    _updateSortedLatencies(latencyMs);
    
    // Giới hạn kích thước lịch sử
    if (_latencyHistory.length > _maxLatencyHistorySize) {
      _latencyHistory.removeFirst();
    }
    
    _updateCurrentWindowStats();
  }
  
  /// Cập nhật danh sách độ trễ đã sắp xếp cho việc tính percentiles
  void _updateSortedLatencies(int latencyMs) {
    // Tìm vị trí để chèn giá trị mới (binary search)
    int low = 0;
    int high = _sortedLatencies.length - 1;
    
    // Tìm vị trí chèn
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (_sortedLatencies[mid] < latencyMs) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    
    // Chèn vào vị trí đã tìm được
    _sortedLatencies.insert(low, latencyMs);
    
    // Giới hạn kích thước để tiết kiệm bộ nhớ
    if (_sortedLatencies.length > 1000) {
      _sortedLatencies.removeAt(0);
    }
  }
  
  /// Cập nhật thời gian gián đoạn nếu đang gián đoạn
  void updateDowntime() {
    if (_lastDisconnectTime != null) {
      final now = DateTime.now();
      _totalDowntime = now.difference(_lastDisconnectTime!).inMilliseconds;
    }
  }
  
  /// Cập nhật thống kê cho cửa sổ thời gian hiện tại
  void _updateCurrentWindowStats() {
    final now = DateTime.now();
    final windowKey = _getTimeWindowKey(now);
    
    // Lấy hoặc tạo thống kê cửa sổ
    final windowStats = _timeWindowStats[windowKey] ?? _TimeWindowStats();
    
    // Cập nhật thống kê
    windowStats.messagesSent = _messagesSent;
    windowStats.messagesReceived = _messagesReceived;
    windowStats.reconnectAttempts = _reconnectAttempts;
    windowStats.errors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    
    // Cập nhật latency nếu có
    if (_latencyHistory.isNotEmpty) {
      final recentLatencies = _latencyHistory
          .where((record) => now.difference(record.timestamp).inMilliseconds < _recentWindowSize)
          .map((record) => record.latencyMs)
          .toList();
          
      if (recentLatencies.isNotEmpty) {
        final avg = recentLatencies.reduce((a, b) => a + b) / recentLatencies.length;
        windowStats.avgLatency = avg;
      }
    }
    
    // Tính tốc độ tin nhắn
    final messageRate = _calculateMessageRate(now);
    windowStats.messageRate = messageRate;
    
    // Lưu lại thống kê
    _timeWindowStats[windowKey] = windowStats;
    
    // Dọn dẹp cửa sổ thời gian cũ (giữ lại tối đa 60 phút)
    _cleanupOldTimeWindows(now);
  }
  
  /// Tính tốc độ tin nhắn (tin nhắn / giây)
  double _calculateMessageRate(DateTime now) {
    // Chỉ tính tin nhắn trong 10 giây gần nhất
    final cutoff = now.subtract(Duration(seconds: 10));
    final recentMessages = _messageSendTimes.where((time) => time.isAfter(cutoff)).length;
    
    if (recentMessages == 0) return 0.0;
    
    // Tìm thời gian tin nhắn đầu tiên trong khoảng 10s
    DateTime? firstTime;
    for (int i = _messageSendTimes.length - 1; i >= 0; i--) {
      if (_messageSendTimes[i].isAfter(cutoff)) {
        firstTime = _messageSendTimes[i];
      } else {
        break;
      }
    }
    
    if (firstTime == null) return 0.0;
    
    // Tính khoảng thời gian (giây)
    final durationSeconds = now.difference(firstTime).inMilliseconds / 1000;
    if (durationSeconds <= 0) return 0.0;
    
    return recentMessages / durationSeconds;
  }
  
  /// Tạo key cho cửa sổ thời gian (định dạng: yyyy-MM-dd_HH:mm)
  String _getTimeWindowKey(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}_'
           '${time.hour.toString().padLeft(2, '0')}:${(time.minute ~/ 1).toString().padLeft(2, '0')}';
  }
  
  /// Dọn dẹp các cửa sổ thời gian cũ
  void _cleanupOldTimeWindows(DateTime now) {
    // Giữ lại 60 phút gần nhất
    final cutoff = now.subtract(Duration(minutes: 60));
    
    final keysToRemove = <String>[];
    for (final entry in _timeWindowStats.entries) {
      final key = entry.key;
      try {
        // Parse key để lấy thời gian
        final parts = key.split('_');
        final dateParts = parts[0].split('-').map(int.parse).toList();
        final timeParts = parts[1].split(':').map(int.parse).toList();
        
        final keyTime = DateTime(
          dateParts[0], dateParts[1], dateParts[2], 
          timeParts[0], timeParts[1]
        );
        
        if (keyTime.isBefore(cutoff)) {
          keysToRemove.add(key);
        }
      } catch (e) {
        // Nếu không parse được, giữ lại để an toàn
      }
    }
    
    // Xóa các key cũ
    for (final key in keysToRemove) {
      _timeWindowStats.remove(key);
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
  
  /// Độ trễ trung bình gần đây (ms) - dựa trên cửa sổ thời gian gần nhất
  double get recentAverageLatency {
    final now = DateTime.now();
    final windowKey = _getTimeWindowKey(now);
    final stats = _timeWindowStats[windowKey];
    
    if (stats != null && stats.avgLatency != null) {
      return stats.avgLatency!;
    }
    
    // Tính nếu không có trong cache
    final recentLatencies = _latencyHistory
        .where((record) => now.difference(record.timestamp).inMilliseconds < _recentWindowSize)
        .map((record) => record.latencyMs)
        .toList();
        
    if (recentLatencies.isEmpty) return 0;
    return recentLatencies.reduce((a, b) => a + b) / recentLatencies.length;
  }
  
  /// Độ trễ thấp nhất (ms)
  int get minLatency {
    if (_sortedLatencies.isEmpty) return 0;
    return _sortedLatencies.first;
  }
  
  /// Độ trễ cao nhất (ms)
  int get maxLatency {
    if (_sortedLatencies.isEmpty) return 0;
    return _sortedLatencies.last;
  }
  
  /// Lấy độ trễ ở phân vị 50 (trung vị)
  int get p50Latency => _getPercentileLatency(0.5);
  
  /// Lấy độ trễ ở phân vị 90
  int get p90Latency => _getPercentileLatency(0.9);
  
  /// Lấy độ trễ ở phân vị 95
  int get p95Latency => _getPercentileLatency(0.95);
  
  /// Lấy độ trễ ở phân vị 99
  int get p99Latency => _getPercentileLatency(0.99);
  
  /// Tính độ trễ ở phân vị cụ thể
  int _getPercentileLatency(double percentile) {
    if (_sortedLatencies.isEmpty) return 0;
    
    final idx = (percentile * (_sortedLatencies.length - 1)).round();
    return _sortedLatencies[idx];
  }
  
  /// Độ lệch chuẩn của độ trễ
  double get latencyStdDev {
    if (_latencyHistory.length < 2) return 0;
    
    final mean = averageLatency;
    final sumSquaredDiff = _latencyHistory.fold<double>(
      0,
      (sum, record) => sum + math.pow(record.latencyMs - mean, 2)
    );
    
    return math.sqrt(sumSquaredDiff / (_latencyHistory.length - 1));
  }
  
  /// Tốc độ tin nhắn gần đây (tin nhắn / giây)
  double get currentMessageRate {
    return _calculateMessageRate(DateTime.now());
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
  
  /// Thống kê theo khoảng thời gian
  Map<String, Map<String, dynamic>> get timeWindowStatsMap {
    final result = <String, Map<String, dynamic>>{};
    
    for (final entry in _timeWindowStats.entries) {
      result[entry.key] = entry.value.toJson();
    }
    
    return result;
  }
  
  /// Tổng thời gian theo dõi (ms)
  int get totalTrackingTimeMs {
    return DateTime.now().difference(_trackingStartedAt).inMilliseconds;
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
        'currentRate': currentMessageRate,
      },
      'latency': {
        'average': averageLatency,
        'recentAverage': recentAverageLatency,
        'min': minLatency,
        'max': maxLatency,
        'p50': p50Latency,
        'p90': p90Latency,
        'p95': p95Latency,
        'p99': p99Latency,
        'stdDev': latencyStdDev,
      },
      'uptime': {
        'connectionTimeMs': connectionTime,
        'downtimeMs': _totalDowntime,
        'uptimePercentage': uptimePercentage,
        'totalTrackingTimeMs': totalTrackingTimeMs,
      },
      'errors': _errorCounts,
      'totalErrors': totalErrors,
      'timeWindowsCount': _timeWindowStats.length,
    };
  }
  
  /// Trả về dữ liệu cho biểu đồ timeseries
  Map<String, List<Map<String, dynamic>>> getTimeSeriesData() {
    final result = <String, List<Map<String, dynamic>>>{
      'messageRate': <Map<String, dynamic>>[],
      'latency': <Map<String, dynamic>>[],
      'errors': <Map<String, dynamic>>[],
    };
    
    // Sắp xếp các key theo thời gian
    final sortedKeys = _timeWindowStats.keys.toList()
      ..sort();
    
    for (final key in sortedKeys) {
      final stats = _timeWindowStats[key]!;
      
      // Parse thời gian từ key
      DateTime? timestamp;
      try {
        final parts = key.split('_');
        final dateParts = parts[0].split('-').map(int.parse).toList();
        final timeParts = parts[1].split(':').map(int.parse).toList();
        
        timestamp = DateTime(
          dateParts[0], dateParts[1], dateParts[2], 
          timeParts[0], timeParts[1]
        );
      } catch (e) {
        continue;
      }
      
      // Thêm dữ liệu tốc độ tin nhắn
      result['messageRate']!.add({
        'timestamp': timestamp.millisecondsSinceEpoch,
        'value': stats.messageRate ?? 0,
      });
      
      // Thêm dữ liệu độ trễ
      if (stats.avgLatency != null) {
        result['latency']!.add({
          'timestamp': timestamp.millisecondsSinceEpoch,
          'value': stats.avgLatency!,
        });
      }
      
      // Thêm dữ liệu lỗi
      result['errors']!.add({
        'timestamp': timestamp.millisecondsSinceEpoch,
        'value': stats.errors,
      });
    }
    
    return result;
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
  
  /// Chuyển đổi thành Map
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'latency_ms': latencyMs,
    };
  }
}

/// Thống kê cho một cửa sổ thời gian
class _TimeWindowStats {
  /// Số tin nhắn đã gửi
  int messagesSent = 0;
  
  /// Số tin nhắn đã nhận
  int messagesReceived = 0;
  
  /// Số lần thử kết nối lại
  int reconnectAttempts = 0;
  
  /// Số lỗi
  int errors = 0;
  
  /// Độ trễ trung bình
  double? avgLatency;
  
  /// Tốc độ tin nhắn (tin nhắn / giây)
  double? messageRate;
  
  /// Chuyển đổi thành Map
  Map<String, dynamic> toJson() {
    return {
      'messages_sent': messagesSent,
      'messages_received': messagesReceived,
      'reconnect_attempts': reconnectAttempts,
      'errors': errors,
      'avg_latency': avgLatency,
      'message_rate': messageRate,
    };
  }
} 