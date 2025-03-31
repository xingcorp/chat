import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Các loại kết nối thời gian thực
enum ConnectionType {
  /// WebSocket
  webSocket,
  
  /// Long Polling
  longPolling,
  
  /// Không kết nối
  none,
}

/// Các trạng thái kết nối
enum ConnectionState {
  /// Chưa kết nối
  disconnected,
  
  /// Đang kết nối
  connecting,
  
  /// Đã kết nối
  connected,
  
  /// Đang thử kết nối lại
  reconnecting,
  
  /// Đã đóng (không thể kết nối lại)
  closed,
}

/// Dữ liệu tin nhắn nhận được từ server
class RealtimeMessage {
  /// ID tin nhắn
  final String id;
  
  /// Loại tin nhắn
  final String type;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// Thời gian nhận
  final DateTime receivedAt;
  
  /// Constructor
  RealtimeMessage({
    required this.id,
    required this.type,
    required this.data,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
  
  /// Tạo từ JSON
  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      id: json['id'] as String? ?? _generateRandomId(),
      type: json['type'] as String? ?? 'unknown',
      data: json['data'],
      receivedAt: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
  
  /// Chuyển thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': receivedAt.toIso8601String(),
    };
  }
  
  /// Tạo ID ngẫu nhiên
  static String _generateRandomId() {
    final random = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           random.nextInt(9999).toString().padLeft(4, '0');
  }
}

/// Quản lý kết nối WebSocket và Long Polling với server
@lazySingleton
class RealtimeConnectionService {
  /// URL WebSocket server
  final String _webSocketUrl;
  
  /// URL HTTP server cho long polling
  final String _httpUrl;
  
  /// Auth token
  final String _authToken;
  
  /// HTTP client cho long polling
  final Dio _dio;
  
  /// Connectivity analyzer service
  final ConnectivityAnalyzerService _connectivityAnalyzer;
  
  /// Kênh WebSocket hiện tại
  WebSocketChannel? _webSocketChannel;
  
  /// Loại kết nối hiện tại
  ConnectionType _connectionType = ConnectionType.none;
  
  /// Trạng thái kết nối hiện tại
  ConnectionState _connectionState = ConnectionState.disconnected;
  
  /// Stream controller cho tin nhắn
  final _messageController = BehaviorSubject<RealtimeMessage>();
  
  /// Stream controller cho trạng thái kết nối
  final _connectionStateController = BehaviorSubject<ConnectionState>();
  
  /// Stream controller cho loại kết nối
  final _connectionTypeController = BehaviorSubject<ConnectionType>();
  
  /// Danh sách tin nhắn đã nhận (để quản lý trùng lặp)
  final Set<String> _receivedMessageIds = {};
  
  /// Số lần thử kết nối lại
  int _reconnectAttempts = 0;
  
  /// Số lần thử kết nối lại tối đa
  static const int _maxReconnectAttempts = 10;
  
  /// Khoảng thời gian giữa các lần thử kết nối lại (ms)
  static const int _initialReconnectDelay = 1000;
  
  /// Thời gian timeout cho long polling (ms)
  static const int _longPollingTimeout = 30000;
  
  /// Thời gian giữa các lần long polling (ms)
  static const int _longPollingInterval = 1000;
  
  /// Timer cho keep-alive
  Timer? _keepAliveTimer;
  
  /// Timer cho long polling
  Timer? _longPollingTimer;
  
  /// Timer cho reconnect
  Timer? _reconnectTimer;
  
  /// Thời gian ping cuối cùng
  DateTime? _lastPingTime;
  
  /// Thời gian pong cuối cùng
  DateTime? _lastPongTime;
  
  /// Constructor
  RealtimeConnectionService({
    required String webSocketUrl,
    required String httpUrl,
    required String authToken,
    required ConnectivityAnalyzerService connectivityAnalyzer,
  }) : _webSocketUrl = webSocketUrl,
       _httpUrl = httpUrl,
       _authToken = authToken,
       _connectivityAnalyzer = connectivityAnalyzer,
       _dio = Dio() {
    // Thiết lập timeout cho Dio
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Thêm auth token vào header
    _dio.options.headers = {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
    
    // Thêm interceptor để xử lý lỗi
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          debugPrint('Long polling error: ${error.message}');
          // Tiếp tục xử lý lỗi
          handler.next(error);
        },
      ),
    );
    
    // Khởi tạo các stream
    _connectionStateController.add(_connectionState);
    _connectionTypeController.add(_connectionType);
    
    // Lắng nghe sự thay đổi kết nối
    _connectivityAnalyzer.connectivityStream.listen(_handleConnectivityChange);
  }
  
  /// Stream theo dõi tin nhắn
  Stream<RealtimeMessage> get messageStream => _messageController.stream;
  
  /// Stream theo dõi trạng thái kết nối
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// Stream theo dõi loại kết nối
  Stream<ConnectionType> get connectionTypeStream => _connectionTypeController.stream;
  
  /// Getter cho trạng thái kết nối hiện tại
  ConnectionState get connectionState => _connectionState;
  
  /// Getter cho loại kết nối hiện tại
  ConnectionType get connectionType => _connectionType;
  
  /// Kiểm tra có đang kết nối không
  bool get isConnected => _connectionState == ConnectionState.connected;
  
  /// Kết nối đến server
  Future<void> connect() async {
    if (_connectionState == ConnectionState.connecting || 
        _connectionState == ConnectionState.connected ||
        _connectionState == ConnectionState.reconnecting) {
      debugPrint('Đã kết nối hoặc đang kết nối, bỏ qua yêu cầu kết nối mới');
      return;
    }
    
    // Đặt trạng thái kết nối
    _updateConnectionState(ConnectionState.connecting);
    
    try {
      // Kiểm tra kết nối mạng
      if (_connectivityAnalyzer.isOffline) {
        throw Exception('Không có kết nối mạng');
      }
      
      // Thử kết nối WebSocket trước
      await _connectWebSocket();
    } catch (e) {
      debugPrint('Lỗi kết nối WebSocket: $e');
      // Nếu không thể kết nối WebSocket, sử dụng Long Polling
      _fallbackToLongPolling();
    }
  }
  
  /// Ngắt kết nối từ server
  Future<void> disconnect() async {
    _updateConnectionState(ConnectionState.disconnected);
    _updateConnectionType(ConnectionType.none);
    
    // Hủy bỏ các timer
    _keepAliveTimer?.cancel();
    _longPollingTimer?.cancel();
    _reconnectTimer?.cancel();
    
    // Đóng kết nối WebSocket
    if (_webSocketChannel != null) {
      await _webSocketChannel?.sink.close(status.normalClosure);
      _webSocketChannel = null;
    }
    
    debugPrint('Đã ngắt kết nối từ server');
  }
  
  /// Đóng kết nối và giải phóng tài nguyên
  Future<void> dispose() async {
    await disconnect();
    
    // Đóng các controller
    await _messageController.close();
    await _connectionStateController.close();
    await _connectionTypeController.close();
    
    debugPrint('Đã giải phóng RealtimeConnectionService');
  }
  
  /// Gửi tin nhắn đến server
  Future<bool> sendMessage(String type, dynamic data) async {
    if (_connectionState != ConnectionState.connected) {
      debugPrint('Không thể gửi tin nhắn khi chưa kết nối');
      return false;
    }
    
    final message = RealtimeMessage(
      id: RealtimeMessage._generateRandomId(),
      type: type,
      data: data,
    );
    
    try {
      switch (_connectionType) {
        case ConnectionType.webSocket:
          _webSocketChannel?.sink.add(jsonEncode(message.toJson()));
          break;
          
        case ConnectionType.longPolling:
          await _dio.post(
            '$_httpUrl/messages',
            data: message.toJson(),
          );
          break;
          
        case ConnectionType.none:
          return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn: $e');
      return false;
    }
  }
  
  /// Xử lý sự thay đổi kết nối
  void _handleConnectivityChange(dynamic connectivityResult) {
    if (_connectivityAnalyzer.isOffline) {
      if (_connectionState == ConnectionState.connected) {
        _updateConnectionState(ConnectionState.disconnected);
        _updateConnectionType(ConnectionType.none);
      }
    } else {
      if (_connectionState == ConnectionState.disconnected) {
        // Kết nối lại khi có mạng
        connect();
      }
    }
  }
  
  /// Kết nối WebSocket
  Future<void> _connectWebSocket() async {
    try {
      // Tạo URL WebSocket với token
      final wsUrl = Uri.parse('$_webSocketUrl?token=$_authToken');
      
      // Tạo kết nối WebSocket
      _webSocketChannel = IOWebSocketChannel.connect(
        wsUrl,
        pingInterval: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      // Xóa các timer cũ nếu có
      _keepAliveTimer?.cancel();
      _longPollingTimer?.cancel();
      
      // Lắng nghe tin nhắn từ WebSocket
      _webSocketChannel?.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
        cancelOnError: false,
      );
      
      // Thiết lập keep-alive
      _startKeepAliveTimer();
      
      // Cập nhật trạng thái
      _reconnectAttempts = 0;
      _updateConnectionState(ConnectionState.connected);
      _updateConnectionType(ConnectionType.webSocket);
      
      debugPrint('Đã kết nối WebSocket thành công');
    } catch (e) {
      debugPrint('Lỗi kết nối WebSocket: $e');
      throw Exception('Không thể kết nối WebSocket: $e');
    }
  }
  
  /// Xử lý tin nhắn từ WebSocket
  void _handleWebSocketMessage(dynamic data) {
    try {
      final jsonData = jsonDecode(data as String);
      
      // Xử lý tin nhắn ping/pong
      if (jsonData['type'] == 'ping') {
        _lastPingTime = DateTime.now();
        // Gửi pong về server
        _webSocketChannel?.sink.add(jsonEncode({
          'type': 'pong',
          'id': jsonData['id'],
          'timestamp': DateTime.now().toIso8601String(),
        }));
        return;
      } else if (jsonData['type'] == 'pong') {
        _lastPongTime = DateTime.now();
        return;
      }
      
      // Tạo tin nhắn
      final message = RealtimeMessage.fromJson(jsonData);
      
      // Kiểm tra trùng lặp
      if (_receivedMessageIds.contains(message.id)) {
        debugPrint('Bỏ qua tin nhắn trùng lặp: ${message.id}');
        return;
      }
      
      // Lưu ID tin nhắn
      _receivedMessageIds.add(message.id);
      
      // Giới hạn số lượng ID tin nhắn lưu trữ
      if (_receivedMessageIds.length > 1000) {
        _receivedMessageIds.remove(_receivedMessageIds.first);
      }
      
      // Gửi tin nhắn vào stream
      _messageController.add(message);
    } catch (e) {
      debugPrint('Lỗi xử lý tin nhắn WebSocket: $e');
    }
  }
  
  /// Xử lý lỗi WebSocket
  void _handleWebSocketError(dynamic error) {
    debugPrint('Lỗi WebSocket: $error');
    
    if (_connectionState == ConnectionState.connected) {
      _tryReconnect();
    }
  }
  
  /// Xử lý đóng kết nối WebSocket
  void _handleWebSocketDone() {
    debugPrint('Kết nối WebSocket đã đóng');
    
    if (_connectionState != ConnectionState.disconnected && 
        _connectionState != ConnectionState.closed) {
      _tryReconnect();
    }
  }
  
  /// Thử kết nối lại
  void _tryReconnect() {
    if (_connectionState == ConnectionState.reconnecting) {
      return;
    }
    
    _updateConnectionState(ConnectionState.reconnecting);
    
    // Hủy bỏ timer cũ nếu có
    _reconnectTimer?.cancel();
    
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Đã vượt quá số lần thử kết nối lại, chuyển sang long polling');
      _fallbackToLongPolling();
      return;
    }
    
    // Tính toán thời gian chờ (exponential backoff)
    final delay = min(
      _initialReconnectDelay * pow(1.5, _reconnectAttempts).toInt(),
      30000, // Tối đa 30 giây
    );
    
    debugPrint('Thử kết nối lại sau $delay ms (lần thử ${_reconnectAttempts + 1})');
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      _reconnectAttempts++;
      
      try {
        // Thử kết nối WebSocket lại
        await _connectWebSocket();
      } catch (e) {
        debugPrint('Không thể kết nối lại WebSocket: $e');
        
        if (_reconnectAttempts >= _maxReconnectAttempts) {
          _fallbackToLongPolling();
        } else {
          _tryReconnect();
        }
      }
    });
  }
  
  /// Chuyển sang long polling
  void _fallbackToLongPolling() {
    debugPrint('Chuyển sang sử dụng Long Polling');
    
    // Đóng kết nối WebSocket nếu có
    if (_webSocketChannel != null) {
      _webSocketChannel?.sink.close();
      _webSocketChannel = null;
    }
    
    // Hủy bỏ timer WebSocket
    _keepAliveTimer?.cancel();
    
    // Cập nhật trạng thái
    _updateConnectionType(ConnectionType.longPolling);
    _updateConnectionState(ConnectionState.connected);
    
    // Bắt đầu long polling
    _startLongPolling();
  }
  
  /// Bắt đầu long polling
  void _startLongPolling() {
    // Hủy timer cũ nếu có
    _longPollingTimer?.cancel();
    
    // Thực hiện long polling ngay lập tức
    _performLongPolling();
    
    // Thiết lập timer cho các lần poll tiếp theo
    _longPollingTimer = Timer.periodic(
      const Duration(milliseconds: _longPollingInterval),
      (_) => _performLongPolling(),
    );
  }
  
  /// Thực hiện long polling
  Future<void> _performLongPolling() async {
    if (_connectionState != ConnectionState.connected || 
        _connectionType != ConnectionType.longPolling) {
      return;
    }
    
    try {
      // Lấy ID tin nhắn cuối cùng (nếu có)
      final lastMsgId = _receivedMessageIds.isNotEmpty 
          ? _receivedMessageIds.last 
          : null;
      
      // Gửi yêu cầu long polling
      final response = await _dio.get(
        '$_httpUrl/messages',
        queryParameters: {
          'lastMessageId': lastMsgId,
          'timeout': _longPollingTimeout,
        },
        options: Options(
          receiveTimeout: Duration(milliseconds: _longPollingTimeout + 5000),
        ),
      );
      
      // Xử lý dữ liệu
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> messages = response.data as List<dynamic>;
        
        for (final msgData in messages) {
          final message = RealtimeMessage.fromJson(msgData as Map<String, dynamic>);
          
          // Kiểm tra trùng lặp
          if (_receivedMessageIds.contains(message.id)) {
            continue;
          }
          
          // Lưu ID tin nhắn
          _receivedMessageIds.add(message.id);
          
          // Giới hạn số lượng ID tin nhắn lưu trữ
          if (_receivedMessageIds.length > 1000) {
            _receivedMessageIds.remove(_receivedMessageIds.first);
          }
          
          // Gửi tin nhắn vào stream
          _messageController.add(message);
        }
      }
      
      // Kiểm tra xem có thể kết nối lại WebSocket không
      _checkWebSocketAvailability();
    } catch (e) {
      debugPrint('Lỗi long polling: $e');
      
      // Nếu mất kết nối
      if (e is DioException && 
          (e.type == DioExceptionType.connectionTimeout || 
           e.type == DioExceptionType.receiveTimeout)) {
        // Tiếp tục long polling
      }
    }
  }
  
  /// Kiểm tra xem có thể kết nối lại WebSocket không
  Future<void> _checkWebSocketAvailability() async {
    // Kiểm tra sau mỗi 5 phút
    if (DateTime.now().minute % 5 != 0 || DateTime.now().second != 0) {
      return;
    }
    
    try {
      // Thử kết nối WebSocket
      await _dio.get('$_httpUrl/status');
      
      // Nếu kết nối thành công, thử chuyển lại WebSocket
      if (_connectionType == ConnectionType.longPolling) {
        _reconnectAttempts = 0;
        _switchToWebSocket();
      }
    } catch (e) {
      debugPrint('Không thể kết nối WebSocket: $e');
    }
  }
  
  /// Chuyển từ long polling sang WebSocket
  Future<void> _switchToWebSocket() async {
    debugPrint('Chuyển từ Long Polling sang WebSocket');
    
    // Hủy timer long polling
    _longPollingTimer?.cancel();
    
    try {
      // Kết nối WebSocket
      await _connectWebSocket();
    } catch (e) {
      debugPrint('Không thể chuyển sang WebSocket: $e');
      // Tiếp tục sử dụng long polling
      _startLongPolling();
    }
  }
  
  /// Bắt đầu timer keep-alive
  void _startKeepAliveTimer() {
    // Hủy timer cũ nếu có
    _keepAliveTimer?.cancel();
    
    // Thiết lập timer mới
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _sendPing();
    });
    
    // Gửi ping ngay lập tức
    _sendPing();
  }
  
  /// Gửi ping để duy trì kết nối
  void _sendPing() {
    if (_connectionType != ConnectionType.webSocket || 
        _connectionState != ConnectionState.connected ||
        _webSocketChannel == null) {
      return;
    }
    
    try {
      // Gửi tin nhắn ping
      final pingMessage = {
        'type': 'ping',
        'id': RealtimeMessage._generateRandomId(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _webSocketChannel?.sink.add(jsonEncode(pingMessage));
      
      // Kiểm tra timeout ping/pong
      _checkPingPongTimeout();
    } catch (e) {
      debugPrint('Lỗi gửi ping: $e');
    }
  }
  
  /// Kiểm tra timeout ping/pong
  void _checkPingPongTimeout() {
    if (_lastPingTime == null || _lastPongTime == null) {
      return;
    }
    
    // Nếu không nhận được pong sau 30 giây kể từ ping cuối cùng
    if (_lastPingTime != null && 
        _lastPongTime!.isBefore(_lastPingTime!) && 
        DateTime.now().difference(_lastPingTime!).inSeconds > 30) {
      debugPrint('Timeout ping/pong, thử kết nối lại');
      _tryReconnect();
    }
  }
  
  /// Cập nhật trạng thái kết nối
  void _updateConnectionState(ConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }
  
  /// Cập nhật loại kết nối
  void _updateConnectionType(ConnectionType type) {
    _connectionType = type;
    _connectionTypeController.add(type);
  }
} 