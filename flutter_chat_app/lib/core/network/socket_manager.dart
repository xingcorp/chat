import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../monitoring/analytics_service.dart';
import '../monitoring/logger.dart';
import '../services/auth_service.dart';
import 'models/socket_connection_state.dart';
import 'models/socket_error.dart';
import 'monitoring/socket_metrics.dart';

/// Cấu hình cho WebSocketManager
class WebSocketConfig {
  final String url;
  final Duration pingInterval;
  final Duration connectionTimeout;
  final int maxReconnectAttempts;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final bool autoReconnect;

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
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Quản lý kết nối và truyền tin qua WebSocket
class WebSocketManager {
  final WebSocketConfig _config;
  final AppLogger _logger;
  final AnalyticsService _analytics;
  final AuthService _authService;
  final WebSocketMetrics _metrics;

  WebSocket? _socket;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  ConnectionState _state = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  bool _manuallyDisconnected = false;
  final Random _random = Random();

  // Các luồng sự kiện
  final _onMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _onConnectionStateController = StreamController<ConnectionState>.broadcast();
  final _onErrorController = StreamController<dynamic>.broadcast();

  // Getter cho các luồng
  Stream<Map<String, dynamic>> get onMessage => _onMessageController.stream;
  Stream<ConnectionState> get onConnectionState => _onConnectionStateController.stream;
  Stream<dynamic> get onError => _onErrorController.stream;

  WebSocketManager({
    required WebSocketConfig config,
    required AppLogger logger,
    required AnalyticsService analytics,
    required AuthService authService,
  })  : _config = config,
        _logger = logger,
        _analytics = analytics,
        _authService = authService,
        _metrics = WebSocketMetrics(analytics);

  /// Kết nối tới WebSocket server
  Future<bool> connect() async {
    if (_state == ConnectionState.connected || _state == ConnectionState.connecting) {
      _logger.info('WebSocket: Đã kết nối hoặc đang kết nối');
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
        _logger.error('WebSocket: Lỗi khi đóng: $e');
      } finally {
        _socket = null;
        _updateState(ConnectionState.disconnected);
      }
    }
  }

  /// Gửi tin nhắn qua WebSocket
  Future<bool> send(Map<String, dynamic> message) async {
    if (_state != ConnectionState.connected || _socket == null) {
      _logger.warn('WebSocket: Không thể gửi tin nhắn - không kết nối.');
      _metrics.recordDroppedMessage();
      return false;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _socket!.add(jsonMessage);
      _metrics.recordMessageSent();
      return true;
    } catch (e) {
      _logger.error('WebSocket: Lỗi khi gửi tin nhắn: $e');
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
        _logger.warn('WebSocket: Nhận được dữ liệu không phải chuỗi: $data');
      }
    } catch (e) {
      _logger.error('WebSocket: Lỗi khi xử lý tin nhắn: $e');
      _metrics.recordError('Error processing message: $e');
    }
  }

  /// Xử lý lỗi WebSocket
  void _handleError(dynamic error) {
    _logger.error('WebSocket: Lỗi: $error');
    _metrics.recordError(error.toString());
    _onErrorController.add(error);
    _updateState(ConnectionState.error);

    if (_config.autoReconnect && !_manuallyDisconnected) {
      _scheduleReconnect();
    }
  }
  
  /// Xử lý khi kết nối WebSocket đóng
  void _handleDone() {
    _logger.info('WebSocket: Kết nối đóng');
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
          _analytics.logEvent(AnalyticsEvent.socketConnected, {});
          break;
        case ConnectionState.disconnected:
          _analytics.logEvent(AnalyticsEvent.socketDisconnected, {});
          break;
        case ConnectionState.error:
          _analytics.logEvent(AnalyticsEvent.socketError, {});
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
      _logger.warn('WebSocket: Đã vượt quá số lần thử kết nối lại tối đa');
      _analytics.logEvent(AnalyticsEvent.socketMaxReconnectExceeded, {});
      return;
    }

    final backoffTime = _getBackoffDuration(_reconnectAttempts);
    _logger.info('WebSocket: Lên lịch kết nối lại sau ${backoffTime.inMilliseconds}ms');
    
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
      _config.initialBackoff.inMilliseconds * pow(2, attempt),
      _config.maxBackoff.inMilliseconds,
    ).toInt();
    
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
      
      _logger.info('WebSocket: Đang kết nối tới $uri');
      
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
      
      _logger.info('WebSocket: Đã kết nối thành công sau ${connectionTime}ms');
      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();
      
      return true;
    } catch (e) {
      final errorTime = DateTime.now().millisecondsSinceEpoch - startTime;
      _logger.error('WebSocket: Lỗi khi kết nối sau ${errorTime}ms: $e');
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

/// Base Socket Manager that handles Socket.IO connections
@injectable
class SocketManager {
  /// Socket.IO client instance
  io.Socket? _socket;
  
  /// Server URL for WebSocket connection
  final String _serverUrl;
  
  /// Connection options for Socket.IO
  final Map<String, dynamic> _options;

  /// Logger instance
  final Logger _logger;
  
  /// Analytics service for tracking performance
  final AnalyticsService? _analytics;
  
  /// Current connection state
  final BehaviorSubject<SocketConnectionState> _connectionStateController = 
      BehaviorSubject<SocketConnectionState>.seeded(SocketConnectionState.disconnected);
  
  /// Stream of connection state changes
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  
  /// Stream của trạng thái kết nối để tương thích ngược
  Stream<SocketConnectionState> get connectionStateStream => connectionState;
  
  /// Current connection state
  SocketConnectionState get currentState => _connectionStateController.value;
  
  /// Whether the socket is connected
  bool get isConnected => currentState == SocketConnectionState.connected;
  
  /// Whether the socket is connecting
  bool get isConnecting => currentState == SocketConnectionState.connecting;
  
  /// Whether the socket is disconnected
  bool get isDisconnected => 
      currentState == SocketConnectionState.disconnected || 
      currentState == SocketConnectionState.disconnectedByUser || 
      currentState == SocketConnectionState.disconnectedByServer || 
      currentState == SocketConnectionState.error;

  /// Connected getter for backwards compatibility
  bool get connected => isConnected;
  
  /// Constructor
  SocketManager({
    required String serverUrl,
    Map<String, dynamic> options = const {},
    Logger? logger,
    AnalyticsService? analytics,
  }) : _serverUrl = serverUrl,
       _options = options,
       _logger = logger ?? Logger(),
      _analytics = analytics;
  
  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_socket != null) {
      _logger.d('Socket already exists, disconnecting first');
      await disconnect();
    }
    
    _updateConnectionState(SocketConnectionState.connecting);
    
    try {
      // Default connection options
      final defaultOptions = {
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'timeout': 10000,
      };
      
      // Merge with custom options
      final mergedOptions = {...defaultOptions, ..._options};
      
      // Create Socket.IO instance
      _socket = io.io(_serverUrl, mergedOptions);
      
      // Set up event handlers
      _setupEventHandlers();
      
      // Connect
      _socket!.connect();

      _logger.i('Socket.IO connecting to $_serverUrl');
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom, 
          {'type': 'socket_connect_attempt', 'url': _serverUrl}
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Error connecting to socket: $e', stackTrace);
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logError(
          'socket_connect_error',
          {'error': e.toString(), 'url': _serverUrl}
        );
      }
      
      rethrow;
    }
  }
  
  /// Disconnect from the WebSocket server
  Future<void> disconnect() async {
    if (_socket != null) {
      _logger.d('Disconnecting socket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _updateConnectionState(SocketConnectionState.disconnectedByUser);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          {'type': 'socket_disconnect', 'reason': 'user_request'}
        );
      }
    }
  }
  
  /// Set up Socket.IO event handlers
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      _logger.i('Socket connected');
      _updateConnectionState(SocketConnectionState.connected);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          {'type': 'socket_connected', 'url': _serverUrl}
        );
      }
    });
    
    _socket?.onDisconnect((_) {
      _logger.i('Socket disconnected');
      if (currentState != SocketConnectionState.disconnectedByUser) {
        _updateConnectionState(SocketConnectionState.disconnectedByServer);
        
        if (_analytics != null) {
          _analytics!.logEvent(
            AnalyticsEvent.custom,
            {'type': 'socket_disconnected', 'reason': 'server_disconnect'}
          );
        }
      }
    });
    
    _socket?.onConnectError((error) {
      _logger.e('Socket connect error: $error');
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logError(
          'socket_connect_error',
          {'error': error.toString(), 'url': _serverUrl}
        );
      }
    });
    
    _socket?.onError((error) {
      _logger.e('Socket error: $error');
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logError(
          'socket_error',
          {'error': error.toString()}
        );
      }
    });
    
    _socket?.onReconnect((_) {
      _logger.i('Socket reconnected');
      _updateConnectionState(SocketConnectionState.connected);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          {'type': 'socket_reconnected'}
        );
      }
    });
    
    _socket?.onReconnecting((_) {
      _logger.i('Socket reconnecting');
      _updateConnectionState(SocketConnectionState.reconnecting);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          {'type': 'socket_reconnecting'}
        );
      }
    });
    
    _socket?.onReconnectFailed((_) {
      _logger.e('Socket reconnect failed');
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          {'type': 'socket_reconnect_failed'}
        );
      }
    });
  }
  
  /// Update connection state
  void _updateConnectionState(SocketConnectionState state) {
    if (!_connectionStateController.isClosed && currentState != state) {
      _logger.d('Socket state changed: $state');
      _connectionStateController.add(state);
    }
  }
  
  /// Register a listener for socket events
  Stream<T> on<T>(String event) {
    final controller = StreamController<T>.broadcast();
    
    if (_socket != null) {
      _socket!.on(event, (data) {
        if (!controller.isClosed) {
          controller.add(data as T);
        }
      });
    }
    
    controller.onCancel = () {
      _socket?.off(event);
    };
    
    return controller.stream;
  }
  
  /// Emit an event to the server
  void emit(String event, [dynamic data]) {
    if (_socket != null && isConnected) {
      _logger.d('Emitting event: $event');
      _socket!.emit(event, data);
    } else {
      _logger.w('Cannot emit event: $event - Socket not connected');
    }
  }
  
  /// Emit an event and wait for an acknowledgment
  void emitWithAck(String event, dynamic data, {Function? ack}) {
    if (_socket != null && isConnected) {
      _logger.d('Emitting event with ack: $event');
      _socket!.emitWithAck(event, data, ack: ack);
    } else {
      _logger.w('Cannot emit event with ack: $event - Socket not connected');
    }
  }
  
  /// Enter background mode to reduce resource usage
  void enterBackgroundMode() {
    _logger.d('Entering background mode');
    // Implement background mode behavior if needed
    // Có thể giảm tần suất ping, ngắt kết nối, hoặc chuyển sang chế độ tiết kiệm năng lượng
  }
  
  /// Enter foreground mode to restore normal operation
  void enterForegroundMode() {
    _logger.d('Entering foreground mode');
    // Implement foreground mode behavior if needed
    // Phục hồi tần suất ping bình thường, kết nối lại nếu cần thiết
  }
  
  /// Dispose resources
  void dispose() {
    _logger.d('Disposing SocketManager');
    disconnect();
    _connectionStateController.close();
  }
} 