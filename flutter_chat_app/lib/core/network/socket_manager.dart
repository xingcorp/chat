import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Trạng thái kết nối của socket
enum SocketConnectionState {
  /// Chưa kết nối
  disconnected,
  
  /// Đang kết nối
  connecting,
  
  /// Đã kết nối
  connected,
  
  /// Đang kết nối lại
  reconnecting,
  
  /// Lỗi kết nối
  error
}

/// Quản lý kết nối socket với cơ chế reconnection và heartbeat
class SocketManager {
  /// Singleton instance
  static final SocketManager _instance = SocketManager._internal();
  
  /// Factory constructor
  factory SocketManager() => _instance;
  
  /// Logger instance
  final Logger _logger = Logger();
  
  /// Socket instance
  late io.Socket _socket;
  
  /// Timer cho heartbeat
  Timer? _heartbeatTimer;
  
  /// Số lần thử kết nối lại
  int _reconnectAttempts = 0;
  
  /// Thời gian delay tối đa cho việc kết nối lại (30 giây)
  final int _maxReconnectDelay = 30;
  
  /// Chỉ ra ứng dụng có đang ở background mode không
  bool _isInBackgroundMode = false;
  
  /// Chỉ ra kết nối có được yêu cầu hay không
  bool _isConnectionRequested = false;
  
  /// Stream controller cho trạng thái kết nối
  final BehaviorSubject<SocketConnectionState> _connectionStateController = 
      BehaviorSubject<SocketConnectionState>.seeded(SocketConnectionState.disconnected);
  
  /// Private constructor
  SocketManager._internal();
  
  /// Trả về stream theo dõi trạng thái kết nối
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  
  /// Trả về trạng thái kết nối hiện tại
  SocketConnectionState get currentState => _connectionStateController.value;
  
  /// Khởi tạo Socket Manager với instance Socket.IO từ DI
  void initialize(io.Socket socket) {
    _socket = socket;
    
    // Thiết lập các event handlers
    _setupSocketEventHandlers();
    
    // Khởi tạo heartbeat timer
    _setupHeartbeat();
    
    _logger.i('Socket Manager đã được khởi tạo');
  }
  
  /// Thiết lập các event handlers cho socket
  void _setupSocketEventHandlers() {
    _socket.onConnect((_) {
      _logger.i('Socket đã kết nối');
      _reconnectAttempts = 0;
      _notifyConnectionState(SocketConnectionState.connected);
      _setupHeartbeat();
    });
    
    _socket.on('connecting', (_) {
      _logger.i('Socket đang kết nối');
      _notifyConnectionState(SocketConnectionState.connecting);
    });
    
    _socket.onDisconnect((_) {
      _logger.w('Socket đã ngắt kết nối');
      _heartbeatTimer?.cancel();
      
      if (_isConnectionRequested) {
        _notifyConnectionState(SocketConnectionState.reconnecting);
        _scheduleReconnect();
      } else {
        _notifyConnectionState(SocketConnectionState.disconnected);
      }
    });
    
    _socket.onError((error) {
      _logger.e('Socket gặp lỗi: $error');
      _notifyConnectionState(SocketConnectionState.error);
      
      if (_isConnectionRequested) {
        _scheduleReconnect();
      }
    });
    
    _socket.onReconnect((_) {
      _logger.i('Socket đã kết nối lại');
      _reconnectAttempts = 0;
      _notifyConnectionState(SocketConnectionState.connected);
    });
    
    _socket.onReconnectAttempt((_) {
      _logger.i('Socket đang thử kết nối lại (lần ${_reconnectAttempts + 1})');
      _notifyConnectionState(SocketConnectionState.reconnecting);
    });
    
    _socket.onReconnectFailed((_) {
      _logger.e('Socket kết nối lại thất bại');
      _notifyConnectionState(SocketConnectionState.error);
      
      // Thử kết nối lại với backoff strategy
      _scheduleReconnect();
    });
  }
  
  /// Kết nối socket
  Future<void> connect() async {
    if (_socket.connected) {
      _logger.i('Socket đã được kết nối');
      return;
    }
    
    _isConnectionRequested = true;
    _logger.i('Yêu cầu kết nối socket');
    _notifyConnectionState(SocketConnectionState.connecting);
    
    try {
      _socket.connect();
    } catch (e) {
      _logger.e('Lỗi khi kết nối socket: $e');
      _notifyConnectionState(SocketConnectionState.error);
      _scheduleReconnect();
    }
  }
  
  /// Ngắt kết nối socket
  Future<void> disconnect() async {
    _isConnectionRequested = false;
    _heartbeatTimer?.cancel();
    
    _logger.i('Ngắt kết nối socket');
    _notifyConnectionState(SocketConnectionState.disconnected);
    
    try {
      _socket.disconnect();
    } catch (e) {
      _logger.e('Lỗi khi ngắt kết nối socket: $e');
    }
  }
  
  /// Lên lịch kết nối lại với exponential backoff và jitter
  void _scheduleReconnect() {
    if (!_isConnectionRequested) return;
    
    // Tính toán delay với exponential backoff và jitter
    final baseDelay = min(_maxReconnectDelay, pow(2, _reconnectAttempts));
    final jitter = Random().nextInt(1000) / 1000; // 0-1 giây random jitter
    final delay = baseDelay + jitter;
    
    _logger.i('Lên lịch kết nối lại sau ${delay.toStringAsFixed(1)}s');
    
    Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
      if (!_socket.connected && _isConnectionRequested) {
        _reconnectAttempts++;
        
        try {
          _socket.connect();
        } catch (e) {
          _logger.e('Lỗi khi thử kết nối lại: $e');
          _scheduleReconnect(); // Thử lại
        }
      }
    });
  }
  
  /// Thiết lập heartbeat timer
  void _setupHeartbeat() {
    _heartbeatTimer?.cancel();
    
    // Sử dụng interval khác nhau cho foreground và background
    final interval = _isInBackgroundMode 
        ? const Duration(minutes: 5)  // 5 phút khi ở background
        : const Duration(seconds: 30); // 30 giây khi ở foreground
    
    _heartbeatTimer = Timer.periodic(interval, (_) {
      if (_socket.connected) {
        _logger.v('Gửi heartbeat');
        _socket.emit('heartbeat', {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'client': 'flutter_app',
        });
      }
    });
  }
  
  /// Thông báo sự thay đổi trạng thái kết nối
  void _notifyConnectionState(SocketConnectionState state) {
    if (!_connectionStateController.isClosed && 
        _connectionStateController.value != state) {
      _connectionStateController.add(state);
    }
  }
  
  /// Đăng ký lắng nghe một sự kiện
  Stream<T> on<T>(String event) {
    final streamController = BehaviorSubject<T>();
    
    _socket.on(event, (data) {
      if (!streamController.isClosed) {
        streamController.add(data as T);
      }
    });
    
    return streamController.stream;
  }
  
  /// Phát sự kiện
  void emit(String event, [dynamic data]) {
    if (!_socket.connected) {
      _logger.w('Socket không được kết nối, không thể phát sự kiện: $event');
      return;
    }
    
    _logger.v('Phát sự kiện: $event');
    _socket.emit(event, data);
  }
  
  /// Chuyển sang chế độ background để tiết kiệm pin
  void enterBackgroundMode() {
    _isInBackgroundMode = true;
    _logger.i('Chuyển sang chế độ background');
    
    // Cập nhật heartbeat interval
    _setupHeartbeat();
  }
  
  /// Chuyển sang chế độ foreground
  void enterForegroundMode() {
    _isInBackgroundMode = false;
    _logger.i('Chuyển sang chế độ foreground');
    
    // Cập nhật heartbeat interval
    _setupHeartbeat();
    
    // Đảm bảo kết nối nếu cần
    if (_isConnectionRequested && !_socket.connected) {
      connect();
    }
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _heartbeatTimer?.cancel();
    _connectionStateController.close();
    _socket.dispose();
    _logger.i('Socket Manager đã được giải phóng');
  }
} 