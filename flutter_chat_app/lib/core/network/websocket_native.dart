import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../monitoring/analytics_service.dart';
import '../services/auth_service.dart';
import 'monitoring/socket_metrics.dart';
import 'models/socket_connection_state.dart';

/// Cấu hình cho WebSocketNative
class WebSocketConfig {
  /// URL của WebSocket server
  final String url;
  
  /// Khoảng thời gian giữa các ping (giữ kết nối)
  final Duration pingInterval;
  
  /// Thời gian chờ kết nối tối đa
  final Duration connectionTimeout;
  
  /// Số lần thử kết nối lại tối đa
  final int maxReconnectAttempts;
  
  /// Thời gian chờ ban đầu giữa các lần thử kết nối lại
  final Duration initialBackoff;
  
  /// Thời gian chờ tối đa giữa các lần thử kết nối lại
  final Duration maxBackoff;
  
  /// Tự động kết nối lại khi mất kết nối
  final bool autoReconnect;

  /// Constructor
  WebSocketConfig({
    required this.url,
    this.pingInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 10),
    this.maxReconnectAttempts = 5,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 30),
    this.autoReconnect = true,
  });
}

/// Trạng thái kết nối WebSocket
enum ConnectionState {
  /// Chưa kết nối
  disconnected,
  
  /// Đang kết nối
  connecting,
  
  /// Đã kết nối
  connected,
  
  /// Đang kết nối lại
  reconnecting,
  
  /// Lỗi kết nối
  error,
}

/// Quản lý kết nối và truyền tin qua WebSocket native
@injectable
class WebSocketNative {
  /// Cấu hình WebSocket
  final WebSocketConfig _config;
  
  /// Logger
  final Logger _logger;
  
  /// Analytics service
  final AnalyticsService _analytics;
  
  /// Auth service
  final AuthService _authService;
  
  /// Metrics tracking
  final WebSocketMetrics _metrics;

  /// Kết nối WebSocket
  WebSocket? _socket;
  
  /// Timer gửi ping định kỳ
  Timer? _pingTimer;
  
  /// Timer kết nối lại
  Timer? _reconnectTimer;
  
  /// Trạng thái kết nối hiện tại
  ConnectionState _state = ConnectionState.disconnected;
  
  /// Số lần thử kết nối lại
  int _reconnectAttempts = 0;
  
  /// Cố tình ngắt kết nối bởi người dùng
  bool _manuallyDisconnected = false;
  
  /// Random generator cho jitter
  final Random _random = Random();

  // Các luồng sự kiện
  /// Stream controller cho tin nhắn đến
  final _onMessageController = StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream controller cho thay đổi trạng thái kết nối
  final _onConnectionStateController = StreamController<ConnectionState>.broadcast();
  
  /// Stream controller cho lỗi
  final _onErrorController = StreamController<dynamic>.broadcast();

  // Getter cho các luồng
  /// Stream tin nhắn đến
  Stream<Map<String, dynamic>> get onMessage => _onMessageController.stream;
  
  /// Stream thay đổi trạng thái kết nối
  Stream<ConnectionState> get onConnectionState => _onConnectionStateController.stream;
  
  /// Stream lỗi
  Stream<dynamic> get onError => _onErrorController.stream;

  /// Constructor
  WebSocketNative({
    required WebSocketConfig config,
    required Logger logger,
    required AnalyticsService analytics,
    required AuthService authService,
  })  : _config = config,
        _logger = logger,
        _analytics = analytics,
        _authService = authService,
        _metrics = WebSocketMetrics(analytics, logger: logger);

  /// Kết nối tới WebSocket server
  Future<bool> connect() async {
    if (_state == ConnectionState.connected || _state == ConnectionState.connecting) {
      _logger.i('WebSocket: Đã kết nối hoặc đang kết nối');
      return true;
    }

    _manuallyDisconnected = false;
    return _createNewSocket();
  }

  /// Ngắt kết nối khỏi WebSocket server
  Future<void> disconnect({bool manualDisconnect = true}) async {
    _manuallyDisconnected = manualDisconnect;
    _cancelReconnect();
    _cancelPingTimer();
    
    if (_socket != null) {
      try {
        await _socket!.close(WebSocketStatus.normalClosure, 'Đóng kết nối bình thường');
      } catch (e) {
        _logger.e('WebSocket: Lỗi khi đóng: $e');
      } finally {
        _socket = null;
        _updateState(ConnectionState.disconnected);
      }
    }
  }

  /// Gửi tin nhắn qua WebSocket
  Future<bool> send(Map<String, dynamic> message) async {
    if (_state != ConnectionState.connected || _socket == null) {
      _logger.w('WebSocket: Không thể gửi tin nhắn - không kết nối.');
      _metrics.recordDroppedMessage();
      return false;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _socket!.add(jsonMessage);
      _metrics.recordMessageSent();
      return true;
    } catch (e) {
      _logger.e('WebSocket: Lỗi khi gửi tin nhắn: $e');
      _metrics.recordError('Error sending message: $e');
      return false;
    }
  }

  /// Gửi tin nhắn ping để kiểm tra kết nối
  void _sendPing() {
    if (_state != ConnectionState.connected || _socket == null) {
      return;
    }
    
    final pingTime = DateTime.now().millisecondsSinceEpoch;
    final pingMessage = {
      'type': 'ping',
      'timestamp': pingTime,
    };

    send(pingMessage);

    // Thiết lập timeout để báo hiệu nếu không nhận được phản hồi
    Future.delayed(_config.pingInterval ~/ 2).then((_) {
      if (_state == ConnectionState.connected) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final lag = currentTime - pingTime;
        _metrics.recordMessageLag(lag);
      }
    });
  }

  /// Xử lý tin nhắn đến
  void _handleMessage(dynamic data) {
    try {
      if (data is String) {
        final message = jsonDecode(data) as Map<String, dynamic>;
        _metrics.recordMessageReceived(size: data.length);

        // Xử lý tin nhắn pong
        if (message['type'] == 'pong' && message.containsKey('pingTimestamp')) {
          final pingTime = message['pingTimestamp'] as int;
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          final lag = currentTime - pingTime;
          _metrics.recordMessageLag(lag);
          return;
        }

        _onMessageController.add(message);
      } else if (data != null) {
        _logger.w('WebSocket: Nhận được dữ liệu không phải chuỗi: $data');
      }
    } catch (e) {
      _logger.e('WebSocket: Lỗi khi xử lý tin nhắn: $e');
      _metrics.recordError('Error processing message: $e');
    }
  }

  /// Xử lý lỗi WebSocket
  void _handleError(dynamic error) {
    _logger.e('WebSocket: Lỗi: $error');
    _metrics.recordError(error.toString());
    _onErrorController.add(error);
    _updateState(ConnectionState.error);

    if (_config.autoReconnect && !_manuallyDisconnected) {
      _scheduleReconnect();
    }
  }
  
  /// Xử lý khi kết nối WebSocket đóng
  void _handleDone() {
    _logger.i('WebSocket: Kết nối đóng');
    _socket = null;
    _updateState(ConnectionState.disconnected);

    if (_config.autoReconnect && !_manuallyDisconnected) {
      _scheduleReconnect();
    }
  }

  /// Cập nhật trạng thái kết nối
  void _updateState(ConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _onConnectionStateController.add(_state);

      // Ghi nhận sự kiện phân tích
      switch (_state) {
        case ConnectionState.connected:
          _analytics.logEvent(
            AnalyticsEvent.custom,
            customEventName: 'socket_connected',
            parameters: {'type': 'websocket_native'},
          );
          break;
        case ConnectionState.disconnected:
          _analytics.logEvent(
            AnalyticsEvent.custom,
            customEventName: 'socket_disconnected',
            parameters: {'type': 'websocket_native'},
          );
          break;
        case ConnectionState.error:
          _analytics.logEvent(
            AnalyticsEvent.custom,
            customEventName: 'socket_error',
            parameters: {'type': 'websocket_native'},
          );
          break;
        default:
          break;
      }
    }
  }

  /// Thiết lập timer gửi ping định kỳ
  void _startPingTimer() {
    _cancelPingTimer();
    _pingTimer = Timer.periodic(_config.pingInterval, (timer) {
      _sendPing();
    });
  }

  /// Hủy timer gửi ping
  void _cancelPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Lên lịch kết nối lại
  void _scheduleReconnect() {
    if (_reconnectTimer != null || _manuallyDisconnected) {
      return;
    }

    _reconnectAttempts++;
    _metrics.recordReconnectAttempt();
    
    if (_reconnectAttempts > _config.maxReconnectAttempts) {
      _logger.w('WebSocket: Đã vượt quá số lần thử kết nối lại tối đa');
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_max_reconnect_exceeded',
        parameters: {'type': 'websocket_native'},
      );
      return;
    }

    final backoffTime = _getBackoffDuration(_reconnectAttempts);
    _logger.i('WebSocket: Lên lịch kết nối lại sau ${backoffTime.inMilliseconds}ms');
    
    _updateState(ConnectionState.reconnecting);
    _reconnectTimer = Timer(backoffTime, () {
      _reconnectTimer = null;
      _createNewSocket();
    });
  }

  /// Hủy timer kết nối lại
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  /// Tính thời gian chờ giữa các lần thử kết nối lại (exponential backoff with jitter)
  Duration _getBackoffDuration(int attempt) {
    final maxMs = min(
      _config.initialBackoff.inMilliseconds * pow(2, attempt).toInt(),
      _config.maxBackoff.inMilliseconds,
    );
    
    // Thêm jitter để tránh hiệu ứng 'thundering herd'
    final jitter = _random.nextInt(maxMs ~/ 4);
    return Duration(milliseconds: maxMs + jitter);
  }

  /// Tạo kết nối WebSocket mới
  Future<bool> _createNewSocket() async {
    if (_state == ConnectionState.connecting) {
      return false;
    }

    _updateState(ConnectionState.connecting);
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    try {
      final uri = await _buildSocketUri();
      final headers = await _getAuthHeaders();
      
      _logger.i('WebSocket: Đang kết nối tới $uri');
      
      _socket = await WebSocket.connect(
        uri.toString(),
        headers: headers,
      ).timeout(_config.connectionTimeout);
      
      _socket!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
      
      final connectionTime = DateTime.now().millisecondsSinceEpoch - startTime;
      _metrics.recordConnectionTime(connectionTime);
      
      _logger.i('WebSocket: Đã kết nối thành công sau ${connectionTime}ms');
      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();
      
      return true;
    } catch (e) {
      final errorTime = DateTime.now().millisecondsSinceEpoch - startTime;
      _logger.e('WebSocket: Lỗi khi kết nối sau ${errorTime}ms: $e');
      _metrics.recordError('Connection failed: $e');
      _updateState(ConnectionState.error);
      
      if (_config.autoReconnect && !_manuallyDisconnected) {
        _scheduleReconnect();
      }
      
      return false;
    }
  }

  /// Xây dựng WebSocket URI với các tham số cần thiết
  Future<Uri> _buildSocketUri() async {
    final baseUri = Uri.parse(_config.url);
    
    // Thêm tham số cần thiết
    return baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'client': 'mobile',
        'version': '1.0.0',
        'platform': Platform.isIOS ? 'ios' : 'android',
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  /// Lấy headers xác thực cho kết nối WebSocket
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Báo cáo các số liệu kết nối định kỳ
  void reportMetrics() {
    _metrics.reportMetrics();
  }

  /// Trạng thái kết nối hiện tại
  ConnectionState get state => _state;

  /// Kiểm tra xem hiện có kết nối không
  bool get isConnected => _state == ConnectionState.connected;

  /// Kiểm tra xem kết nối có ổn định không
  bool get isConnectionStable => _metrics.isConnectionStable;

  /// Đóng tất cả các luồng và tài nguyên
  void dispose() {
    disconnect(manualDisconnect: true);
    _onMessageController.close();
    _onConnectionStateController.close();
    _onErrorController.close();
  }
} 