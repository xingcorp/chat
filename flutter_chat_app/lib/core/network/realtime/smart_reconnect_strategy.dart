import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/core/network/realtime/backoff_strategy.dart';

/// Chiến lược kết nối lại thông minh với các tối ưu hiệu suất
class SmartReconnectStrategy {
  /// Analytics service để ghi nhận các sự kiện
  final IAnalyticsService _analyticsService;
  
  /// Chiến lược backoff
  final SmartBackoffStrategy _backoffStrategy;
  
  /// Số lần thử kết nối lại tối đa
  final int maxReconnectAttempts;
  
  /// Có tự động kết nối lại khi gặp lỗi hoặc mất kết nối không
  final bool autoReconnect;
  
  /// Callback khi trạng thái kết nối thay đổi
  final void Function(SocketConnectionState state, String reason)? onConnectionStateChanged;
  
  /// Số lần đã thử kết nối lại
  int _reconnectAttempts = 0;
  
  /// Timer kết nối lại
  Timer? _reconnectTimer;
  
  /// Nguyên nhân ngắt kết nối gần nhất
  String? _lastDisconnectReason;
  
  /// Thời gian ngắt kết nối gần nhất
  DateTime? _lastDisconnectTime;
  
  /// Trạng thái kết nối hiện tại
  SocketConnectionState _connectionState = SocketConnectionState.disconnected;
  
  /// Constructor
  SmartReconnectStrategy({
    required IAnalyticsService analyticsService,
    SmartBackoffStrategy? backoffStrategy,
    this.maxReconnectAttempts = 15,
    this.autoReconnect = true,
    this.onConnectionStateChanged,
  }) : 
    _analyticsService = analyticsService,
    _backoffStrategy = backoffStrategy ?? BackoffStrategyFactory.createForWebSocketReconnect();
  
  /// Kết nối thành công
  void onConnected() {
    _updateConnectionState(SocketConnectionState.connected, 'Kết nối thành công');
    _resetReconnectState();
  }
  
  /// Ngắt kết nối
  void onDisconnected(String reason, {bool byUser = false, bool byServer = false, bool error = false}) {
    // Lưu thông tin về lần ngắt kết nối này
    _lastDisconnectReason = reason;
    _lastDisconnectTime = DateTime.now();
    
    // Xác định trạng thái dựa trên nguồn ngắt kết nối
    SocketConnectionState newState;
    if (byUser) {
      newState = SocketConnectionState.disconnectedByUser;
    } else if (byServer) {
      newState = SocketConnectionState.disconnectedByServer;
    } else if (error) {
      newState = SocketConnectionState.error;
    } else {
      newState = SocketConnectionState.disconnected;
    }
    
    _updateConnectionState(newState, reason);
    
    // Ghi nhận event analytics
    _analyticsService.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_disconnected',
      parameters: {
        'reason': reason,
        'by_user': byUser,
        'by_server': byServer,
        'error': error,
        'reconnect_attempts': _reconnectAttempts,
      },
    );
    
    // Tự động kết nối lại nếu được cấu hình và không phải ngắt kết nối chủ động
    if (autoReconnect && !byUser) {
      scheduleReconnect();
    }
  }
  
  /// Bắt đầu kết nối
  void onConnecting() {
    _updateConnectionState(SocketConnectionState.connecting, 'Đang kết nối');
  }
  
  /// Hủy tất cả timer kết nối lại
  void cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Lên lịch kết nối lại
  void scheduleReconnect() {
    // Hủy timer hiện tại nếu có
    cancelReconnect();
    
    // Kiểm tra xem đã vượt quá số lần thử tối đa chưa
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('Đã vượt quá số lần thử kết nối lại tối đa: $_reconnectAttempts');
      _updateConnectionState(SocketConnectionState.disconnected, 'Quá nhiều lần thử kết nối không thành công');
      
      // Ghi nhận event analytics
      _analyticsService.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_max_reconnect_attempts',
        parameters: {
          'max_attempts': maxReconnectAttempts,
          'last_disconnect_reason': _lastDisconnectReason ?? 'unknown',
        },
      );
      
      return;
    }
    
    // Tăng số lần thử
    _reconnectAttempts++;
    
    // Tính toán thời gian chờ dựa trên backoff strategy
    final delayMs = _backoffStrategy.nextDelay();
    
    debugPrint('Lên lịch kết nối lại sau ${delayMs}ms (lần thử số $_reconnectAttempts)');
    _updateConnectionState(SocketConnectionState.reconnecting, 'Lên lịch kết nối lại sau ${delayMs}ms');
    
    // Lên lịch kết nối lại
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      _reconnectTimer = null;
      
      // Báo trạng thái đang kết nối
      _updateConnectionState(SocketConnectionState.connecting, 'Đang thử kết nối lại (lần $_reconnectAttempts)');
      
      // Callback thông báo cần kết nối lại
      onReconnectNow();
    });
  }
  
  /// Callback khi cần thực hiện kết nối lại ngay lập tức
  void onReconnectNow() {
    // Phương thức này nên được override bởi lớp cha
    // Nó sẽ được gọi khi cần thực hiện việc kết nối thực tế
  }
  
  /// Reset trạng thái kết nối lại
  void _resetReconnectState() {
    _reconnectAttempts = 0;
    _backoffStrategy.reset();
    cancelReconnect();
  }
  
  /// Cập nhật trạng thái kết nối
  void _updateConnectionState(SocketConnectionState newState, String reason) {
    if (_connectionState != newState) {
      _connectionState = newState;
      onConnectionStateChanged?.call(newState, reason);
    }
  }
  
  /// Lấy trạng thái kết nối hiện tại
  SocketConnectionState get connectionState => _connectionState;
  
  /// Số lần thử kết nối hiện tại
  int get reconnectAttempts => _reconnectAttempts;
  
  /// Thời gian từ lần ngắt kết nối gần nhất (ms)
  int get timeSinceLastDisconnectMs => 
      _lastDisconnectTime != null ? 
      DateTime.now().difference(_lastDisconnectTime!).inMilliseconds : 
      0;
  
  /// Kiểm tra kết nối có đang ở trạng thái ổn định
  bool get isConnected => _connectionState == SocketConnectionState.connected;
  
  /// Kiểm tra xem có đang thử kết nối lại
  bool get isReconnecting => _connectionState == SocketConnectionState.reconnecting ||
                            _connectionState == SocketConnectionState.connecting;
} 