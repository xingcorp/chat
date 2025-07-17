import 'dart:async';

import 'package:flutter/foundation.dart';

/// Cấu hình cho connection health monitor
class ConnectionHealthConfig {
  /// Tần suất gửi ping (ms)
  final int pingIntervalMs;
  
  /// Thời gian timeout cho pong (ms) 
  final int pongTimeoutMs;
  
  /// Số lần ping fails liên tục trước khi báo kết nối có vấn đề
  final int consecutiveFailsThreshold;
  
  /// Có nên tự động đóng kết nối khi phát hiện zombie
  final bool autoCloseZombieConnections;
  
  /// Gửi ping khi idle quá lâu (thay vì chỉ định kỳ)
  final bool pingOnlyWhenIdle;
  
  /// Thời gian idle tối đa trước khi gửi ping (ms)
  final int maxIdleTimeMs;
  
  /// Constructor
  const ConnectionHealthConfig({
    this.pingIntervalMs = 30000,          // 30s
    this.pongTimeoutMs = 10000,           // 10s
    this.consecutiveFailsThreshold = 3,
    this.autoCloseZombieConnections = true,
    this.pingOnlyWhenIdle = true,
    this.maxIdleTimeMs = 45000,           // 45s
  });
}

/// Trạng thái sức khỏe kết nối
enum ConnectionHealthState {
  /// Kết nối khỏe mạnh
  healthy,
  
  /// Kết nối bị chậm
  slow,
  
  /// Kết nối không đáng tin cậy (nhiều ping fails)
  degraded,
  
  /// Kết nối nghi ngờ đã chết (zombie)
  zombie,
  
  /// Kết nối đã ngắt
  disconnected,
}

/// Kết quả đo lường độ trễ
class LatencyMeasurement {
  /// Thời gian đo (ms)
  final int latencyMs;
  
  /// Thời điểm đo
  final DateTime timestamp;
  
  /// Constructor
  LatencyMeasurement({
    required this.latencyMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Lớp quản lý sức khỏe kết nối WebSocket
class ConnectionHealthMonitor {
  /// Cấu hình
  final ConnectionHealthConfig _config;
  
  /// Hàm callback để gửi ping message
  final Future<bool> Function(Map<String, dynamic> pingData) _sendPingFunction;
  
  /// Hàm callback khi trạng thái sức khỏe thay đổi
  final void Function(ConnectionHealthState state, String reason)? onHealthStateChanged;
  
  /// Hàm callback khi phát hiện zombie connection
  final void Function()? onZombieConnectionDetected;
  
  /// Trạng thái sức khỏe kết nối hiện tại
  ConnectionHealthState _healthState = ConnectionHealthState.healthy;
  
  /// Timer cho việc gửi ping
  Timer? _pingTimer;
  
  /// Timer cho việc timeout pong
  Timer? _pongTimeoutTimer;
  
  /// Thời gian gửi ping gần nhất
  DateTime? _lastPingSent;
  
  /// Thời gian nhận pong gần nhất
  DateTime? _lastPongReceived;
  
  /// Thời gian hoạt động cuối cùng (gửi/nhận tin)
  DateTime _lastActivityTime = DateTime.now();
  
  /// ID ping gần nhất
  String? _lastPingId;
  
  /// Số lần ping fails liên tiếp
  int _consecutivePingFails = 0;
  
  /// Lịch sử độ trễ gần đây
  final List<LatencyMeasurement> _recentLatencies = [];
  
  /// Completer cho lần đo độ trễ hiện tại
  Completer<int?>? _latencyCompleter;
  
  /// Constructor
  ConnectionHealthMonitor({
    required Future<bool> Function(Map<String, dynamic> pingData) sendPingFunction,
    ConnectionHealthConfig? config,
    this.onHealthStateChanged,
    this.onZombieConnectionDetected,
  }) : 
    _sendPingFunction = sendPingFunction,
    _config = config ?? const ConnectionHealthConfig();
  
  /// Bắt đầu monitor
  void start() {
    _schedulePingTimer();
  }
  
  /// Dừng monitor
  void stop() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    _lastPingId = null;
  }
  
  /// Lên lịch timer gửi ping
  void _schedulePingTimer() {
    _pingTimer?.cancel();
    
    // Nếu chỉ ping khi idle và đã có hoạt động gần đây, dùng thời gian idle tối đa
    final pingInterval = _config.pingOnlyWhenIdle &&
                          DateTime.now().difference(_lastActivityTime).inMilliseconds < _config.pingIntervalMs
        ? _config.maxIdleTimeMs
        : _config.pingIntervalMs;
    
    _pingTimer = Timer(Duration(milliseconds: pingInterval), _sendPing);
  }
  
  /// Gửi ping
  Future<void> _sendPing() async {
    // Tạo ping id ngẫu nhiên
    _lastPingId = DateTime.now().millisecondsSinceEpoch.toString();
    _lastPingSent = DateTime.now();
    
    // Chuẩn bị data ping
    final pingData = {
      'type': 'ping',
      'id': _lastPingId,
      'timestamp': _lastPingSent!.millisecondsSinceEpoch,
    };
    
    try {
      // Gửi ping
      final success = await _sendPingFunction(pingData);
      
      if (!success) {
        _handlePingFailure('Không thể gửi ping');
      } else {
        // Đặt timer cho pong timeout
        _pongTimeoutTimer?.cancel();
        _pongTimeoutTimer = Timer(
          Duration(milliseconds: _config.pongTimeoutMs),
          () => _handlePongTimeout(_lastPingId!),
        );
      }
    } catch (e) {
      _handlePingFailure('Lỗi khi gửi ping: $e');
    }
    
    // Lên lịch ping tiếp theo
    _schedulePingTimer();
  }
  
  /// Xử lý ping failure
  void _handlePingFailure(String reason) {
    debugPrint('Ping failure: $reason');
    _consecutivePingFails++;
    
    // Nếu vượt quá ngưỡng, cập nhật health state
    if (_consecutivePingFails >= _config.consecutiveFailsThreshold) {
      _updateHealthState(ConnectionHealthState.degraded, 'Nhiều ping thất bại liên tiếp');
      
      // Kiểm tra xem có phải zombie không
      final now = DateTime.now();
      if (_lastPongReceived != null) {
        final timeSinceLastPong = now.difference(_lastPongReceived!).inMilliseconds;
        if (timeSinceLastPong > _config.pingIntervalMs * 2) {
          _updateHealthState(ConnectionHealthState.zombie, 'Kết nối nghi ngờ đã chết');
          
          if (_config.autoCloseZombieConnections) {
            onZombieConnectionDetected?.call();
          }
        }
      }
    }
  }
  
  /// Xử lý pong timeout
  void _handlePongTimeout(String pingId) {
    // Chỉ xử lý nếu timeout trùng với ping ID hiện tại
    if (pingId == _lastPingId) {
      _handlePingFailure('Pong timeout');
    }
  }
  
  /// Xử lý pong được nhận
  void handlePongReceived(Map<String, dynamic> pongData) {
    final pingId = pongData['id'] as String?;
    
    // Bỏ qua nếu không phải ping ID hiện tại
    if (pingId != _lastPingId) {
      return;
    }
    
    // Hủy timeout timer
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    
    // Cập nhật thời gian nhận pong
    _lastPongReceived = DateTime.now();
    _lastActivityTime = _lastPongReceived!;
    
    // Reset số lần fails
    _consecutivePingFails = 0;
    
    // Tính toán độ trễ
    if (_lastPingSent != null) {
      final latencyMs = _lastPongReceived!.difference(_lastPingSent!).inMilliseconds;
      _recordLatency(latencyMs);
      
      // Hoàn thành latency completer nếu có
      if (_latencyCompleter != null && !_latencyCompleter!.isCompleted) {
        _latencyCompleter!.complete(latencyMs);
      }
      
      // Cập nhật health state dựa trên độ trễ
      if (latencyMs > 1000) {
        _updateHealthState(ConnectionHealthState.slow, 'Độ trễ cao: ${latencyMs}ms');
      } else if (_healthState != ConnectionHealthState.healthy) {
        _updateHealthState(ConnectionHealthState.healthy, 'Độ trễ trở về bình thường');
      }
    }
  }
  
  /// Ghi nhận độ trễ
  void _recordLatency(int latencyMs) {
    _recentLatencies.add(LatencyMeasurement(latencyMs: latencyMs));
    
    // Giới hạn số lượng bản ghi gần đây
    if (_recentLatencies.length > 50) {
      _recentLatencies.removeAt(0);
    }
  }
  
  /// Đo độ trễ hiện tại chủ động
  Future<int?> measureLatency({int timeoutMs = 5000}) {
    // Nếu đang đo, trả về kết quả hiện tại
    if (_latencyCompleter != null && !_latencyCompleter!.isCompleted) {
      return _latencyCompleter!.future;
    }
    
    // Tạo completer mới
    _latencyCompleter = Completer<int?>();
    
    // Gửi ping ngay lập tức
    _sendPing();
    
    // Đặt timeout
    Timer(Duration(milliseconds: timeoutMs), () {
      if (_latencyCompleter != null && !_latencyCompleter!.isCompleted) {
        _latencyCompleter!.complete(null);
      }
    });
    
    return _latencyCompleter!.future;
  }
  
  /// Đánh dấu có hoạt động
  void markActivity() {
    _lastActivityTime = DateTime.now();
  }
  
  /// Cập nhật trạng thái sức khỏe kết nối
  void _updateHealthState(ConnectionHealthState newState, String reason) {
    if (_healthState != newState) {
      _healthState = newState;
      onHealthStateChanged?.call(newState, reason);
    }
  }
  
  /// Kết nối đã ngắt
  void markDisconnected(String reason) {
    _updateHealthState(ConnectionHealthState.disconnected, reason);
    stop();
  }
  
  /// Kết nối đã khôi phục
  void markReconnected() {
    _updateHealthState(ConnectionHealthState.healthy, 'Kết nối đã khôi phục');
    _consecutivePingFails = 0;
    _lastActivityTime = DateTime.now();
    start();
  }
  
  /// Lấy trạng thái sức khỏe hiện tại
  ConnectionHealthState get healthState => _healthState;
  
  /// Lấy độ trễ trung bình gần đây
  double get averageLatency {
    if (_recentLatencies.isEmpty) return 0;
    
    final sum = _recentLatencies.fold<int>(
      0, (sum, measurement) => sum + measurement.latencyMs
    );
    
    return sum / _recentLatencies.length;
  }
  
  /// Lấy độ trễ nhỏ nhất gần đây
  int get minLatency {
    if (_recentLatencies.isEmpty) return 0;
    return _recentLatencies.map((m) => m.latencyMs).reduce(
      (value, element) => value < element ? value : element
    );
  }
  
  /// Lấy độ trễ lớn nhất gần đây
  int get maxLatency {
    if (_recentLatencies.isEmpty) return 0;
    return _recentLatencies.map((m) => m.latencyMs).reduce(
      (value, element) => value > element ? value : element
    );
  }
  
  /// Thời gian từ hoạt động cuối cùng (ms)
  int get timeSinceLastActivityMs {
    return DateTime.now().difference(_lastActivityTime).inMilliseconds;
  }
  
  /// Kiểm tra xem kết nối có ổn định không
  bool get isConnectionStable {
    return _healthState == ConnectionHealthState.healthy || 
           _healthState == ConnectionHealthState.slow;
  }
} 