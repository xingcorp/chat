import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:flutter_chat_app/core/config/app_config.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Định nghĩa các loại kết nối realtime
enum ConnectionType {
  /// Kết nối WebSocket
  webSocket,
  
  /// Kết nối dựa trên long polling
  longPolling,
  
  /// Không có kết nối
  none,
}

/// Định nghĩa các trạng thái kết nối
enum ConnectionState {
  /// Chưa kết nối
  disconnected,
  
  /// Đang kết nối
  connecting,
  
  /// Đã kết nối
  connected,
  
  /// Kết nối bị lỗi
  error,
  
  /// Kết nối bị đóng
  closed,
}

/// Service quản lý kết nối realtime
@lazySingleton
class RealtimeConnectionService {
  /// WebSocket channel
  WebSocketChannel? _webSocketChannel;
  
  /// Kiểu kết nối hiện tại
  ConnectionType _connectionType = ConnectionType.none;
  
  /// Trạng thái kết nối hiện tại
  ConnectionState _connectionState = ConnectionState.disconnected;
  
  /// Controller cho stream kết nối
  final _connectionStateController = BehaviorSubject<ConnectionState>.seeded(ConnectionState.disconnected);
  
  /// Controller cho stream tin nhắn
  final _messageController = BehaviorSubject<RealtimeMessage>();
  
  /// Controller cho stream kiểu kết nối
  final _connectionTypeController = BehaviorSubject<ConnectionType>.seeded(ConnectionType.none);
  
  /// Flag đánh dấu đã khởi tạo
  bool _initialized = false;
  
  /// URL cho WebSocket
  final String _webSocketUrl;
  
  /// URL cho HTTP
  final String _httpUrl;
  
  /// Token xác thực
  final String _authToken;
  
  /// Số lần thử kết nối lại
  int _reconnectAttempts = 0;
  
  /// Thời gian đợi giữa các lần thử kết nối
  static const _initialReconnectDelay = 1000; // ms
  
  /// Số lần thử kết nối tối đa
  static const _maxReconnectAttempts = 10;
  
  /// Thời gian giữa các lần ping
  static const _pingInterval = 30000; // ms
  
  /// Thời gian timeout cho ping
  static const _pingTimeout = 10000; // ms
  
  /// Thời gian giữa các lần poll
  static const _longPollingInterval = 1000; // ms
  
  /// Thời gian giữa các lần kiểm tra WebSocket
  static const _checkWebSocketInterval = 300000; // ms (5 phút)
  
  /// Client Dio cho HTTP requests
  final Dio _dio;
  
  /// Service phân tích kết nối
  final ConnectivityAnalyzerService _connectivityAnalyzer;
  
  /// Timer cho việc thử kết nối lại
  Timer? _reconnectTimer;
  
  /// Timer cho việc poll định kỳ
  Timer? _longPollingTimer;
  
  /// Timer cho việc gửi ping
  Timer? _keepAliveTimer;
  
  /// Timer cho việc kiểm tra timeout ping
  Timer? _pingPongTimer;
  
  /// Timer cho việc kiểm tra WebSocket
  Timer? _checkWebSocketTimer;
  
  /// Thời gian ping gần nhất
  DateTime? _lastPingSent;
  
  /// Thời gian pong gần nhất
  DateTime? _lastPongReceived;
  
  /// Hàng đợi tin nhắn chờ gửi
  final List<_PendingMessage> _pendingMessages = [];
  
  /// Đăng ký lắng nghe kết nối
  StreamSubscription? _connectivitySubscription;
  
  /// Service kiểm tra kết nối
  final ConnectivityService _connectivityService;
  
  /// HTTP Client
  final http.Client _httpClient;
  
  /// ID phiên hiện tại
  String? _sessionId;
  
  /// Constructor
  RealtimeConnectionService({
    required String webSocketUrl,
    required String httpUrl,
    required String authToken,
    required ConnectivityAnalyzerService connectivityAnalyzer,
    required ConnectivityService connectivityService,
  })  : _webSocketUrl = webSocketUrl,
       _httpUrl = httpUrl,
       _authToken = authToken,
       _connectivityAnalyzer = connectivityAnalyzer,
       _dio = Dio(),
       _connectivityService = connectivityService,
       _httpClient = http.Client() {
    // Thiết lập timeout cho Dio
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Thiết lập interceptor cho Dio
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Log lỗi
          debugPrint('Dio error: ${error.message}');
          
          // Xử lý lỗi authentication
          if (error.response?.statusCode == 401) {
            // TODO: Xử lý refresh token
          }
          
          return handler.next(error);
        },
      ),
    );
    
    // Lắng nghe sự thay đổi kết nối
    _connectivityAnalyzer.connectivityStream.listen((results) {
      _handleConnectivityChange(results.isNotEmpty);
    });
  }
  
  /// Stream theo dõi tin nhắn
  Stream<RealtimeMessage> get messageStream => _messageController.stream;
  
  /// Stream theo dõi trạng thái kết nối
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// Stream theo dõi loại kết nối
  Stream<ConnectionType> get connectionTypeStream => _connectionTypeController.stream;
  
  /// Trạng thái kết nối hiện tại
  ConnectionState get connectionState => _connectionState;
  
  /// Kiểu kết nối hiện tại
  ConnectionType get connectionType => _connectionType;
  
  /// Kiểm tra kết nối đã được thiết lập chưa
  bool get isConnected => _connectionState == ConnectionState.connected;
  
  /// Kiểm tra đang trong quá trình kết nối
  bool get isConnecting => _connectionState == ConnectionState.connecting;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Tạo ID phiên mới
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    
    // Đăng ký lắng nghe thay đổi kết nối
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((results) {
          _handleConnectivityChange(results.isNotEmpty);
        });
    
    _initialized = true;
  }
  
  /// Kết nối đến server
  Future<bool> connect() async {
    if (_connectionState == ConnectionState.connected || 
        _connectionState == ConnectionState.connecting) {
      return isConnected;
    }
    
    _updateConnectionState(ConnectionState.connecting);
    
    // Kiểm tra kết nối mạng
    final isNetworkConnected = await _connectivityService.isConnected;
    if (!isNetworkConnected) {
      _updateConnectionState(ConnectionState.error);
      return false;
    }
    
    // Thử kết nối WebSocket
    final success = await _connectWebSocket();
    
    // Nếu không thành công, thử long polling
    if (!success && _connectionType != ConnectionType.longPolling) {
      await _startLongPolling();
    }
    
    return isConnected;
  }
  
  /// Ngắt kết nối
  Future<void> disconnect() async {
    _updateConnectionState(ConnectionState.disconnected);
    
    // Hủy các timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    _longPollingTimer?.cancel();
    _longPollingTimer = null;
    
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    
    _pingPongTimer?.cancel();
    _pingPongTimer = null;
    
    _checkWebSocketTimer?.cancel();
    _checkWebSocketTimer = null;
    
    // Đóng WebSocket
    await _webSocketChannel?.sink.close(1000);
    _webSocketChannel = null;
    
    _updateConnectionType(ConnectionType.none);
  }
  
  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await disconnect();
    
    // Hủy đăng ký lắng nghe thay đổi kết nối
    await _connectivitySubscription?.cancel();
    
    // Đóng các controller
    await _connectionStateController.close();
    await _messageController.close();
    await _connectionTypeController.close();
    
    // Đóng HTTP client
    _httpClient.close();
    
    _initialized = false;
  }
  
  /// Gửi tin nhắn đến server
  Future<bool> sendMessage(
    String type,
    dynamic data, {
    bool queueIfDisconnected = true,
  }) async {
    // Nếu đang kết nối, gửi ngay
    if (isConnected) {
      final message = RealtimeMessage(type: type, data: data);
      
      try {
        switch (_connectionType) {
          case ConnectionType.webSocket:
            _webSocketChannel?.sink.add(jsonEncode(message.toJson()));
            return true;
            
          case ConnectionType.longPolling:
            final response = await _httpClient
                .post(
                  Uri.parse('${_httpUrl}/realtime/send'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(message),
                )
                .timeout(const Duration(seconds: 30));
            
            return response.statusCode >= 200 && response.statusCode < 300;
            
          case ConnectionType.none:
            // Không có kết nối
            if (queueIfDisconnected) {
              _pendingMessages.add(_PendingMessage(type, data));
            }
            return false;
        }
      } catch (e) {
        debugPrint('Error sending message: $e');
        
        if (queueIfDisconnected) {
          _pendingMessages.add(_PendingMessage(type, data));
        }
        
        return false;
      }
    } else if (queueIfDisconnected) {
      // Thêm vào hàng đợi
      _pendingMessages.add(_PendingMessage(type, data));
      
      // Cố gắng kết nối nếu chưa kết nối
      if (_connectionState == ConnectionState.disconnected) {
        connect();
      }
      
      return false;
    }
    
    return false;
  }
  
  /// Xử lý sự thay đổi kết nối
  void _handleConnectivityChange(bool isConnected) {
    if (isConnected) {
      // Nếu đang mất kết nối, thử kết nối lại
      if (_connectionState == ConnectionState.disconnected ||
          _connectionState == ConnectionState.error) {
        connect();
      }
    } else {
      // Nếu đang kết nối, cập nhật trạng thái
      if (_connectionState == ConnectionState.connected) {
        _updateConnectionState(ConnectionState.disconnected);
      }
    }
  }
  
  /// Kết nối WebSocket
  Future<bool> _connectWebSocket() async {
    try {
      // Tạo WebSocket URL với token
      final wsUrl = _buildWebSocketUrl();
      
      // Đóng kết nối cũ nếu có
      await _webSocketChannel?.sink.close(1000);
      
      // Tạo kết nối mới
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Lắng nghe sự kiện từ WebSocket
      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );
      
      // Cập nhật trạng thái
      _updateConnectionState(ConnectionState.connected);
      _updateConnectionType(ConnectionType.webSocket);
      
      // Thiết lập ping/pong
      _startKeepAliveTimer();
      
      // Gửi các tin nhắn đang chờ
      _sendPendingMessages();
      
      return true;
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _tryReconnect();
      return false;
    }
  }
  
  /// Xử lý tin nhắn từ WebSocket
  void _handleWebSocketMessage(dynamic message) {
    try {
      // Cập nhật thời gian nhận pong gần nhất
      _lastPongReceived = DateTime.now();
      
      // Parse tin nhắn
      final data = jsonDecode(message as String);
      
      // Xử lý tin nhắn ping/pong
      if (data['type'] == 'ping') {
        _webSocketChannel?.sink.add(jsonEncode({'type': 'pong'}));
        return;
      } else if (data['type'] == 'pong') {
        return;
      }
      
      // Chuyển tiếp tin nhắn
      final realtimeMessage = RealtimeMessage.fromJson(data);
      _messageController.add(realtimeMessage);
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }
  
  /// Xử lý lỗi WebSocket
  void _handleWebSocketError(Object error) {
    debugPrint('WebSocket error: $error');
    _tryReconnect();
  }
  
  /// Xử lý sự kiện đóng WebSocket
  void _handleWebSocketDone() {
    debugPrint('WebSocket connection closed');
    
    // Nếu đang kết nối, thử kết nối lại
    if (_connectionState == ConnectionState.connected) {
      _tryReconnect();
    }
  }
  
  /// Thử kết nối lại
  void _tryReconnect() {
    if (_reconnectTimer != null) return;
    
    // Cập nhật trạng thái
    _updateConnectionState(ConnectionState.connecting);
    
    // Tính thời gian chờ với exponential backoff
    final delay = _initialReconnectDelay * (1 << _reconnectAttempts);
    _reconnectAttempts++;
    
    debugPrint('Trying to reconnect in ${delay}ms (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      // Kiểm tra kết nối mạng trước khi thử lại
      final isNetworkConnected = await _connectivityService.isConnected;
      if (isNetworkConnected) {
        _connectWebSocket();
      } else {
        _updateConnectionState(ConnectionState.disconnected);
      }
      
      _reconnectTimer = null;
      
      // Nếu vượt quá số lần thử, chuyển sang long polling
      if (_reconnectAttempts >= _maxReconnectAttempts && 
          _connectionType != ConnectionType.longPolling) {
        _startLongPolling();
      }
    });
  }
  
  /// Bắt đầu long polling
  Future<void> _startLongPolling() async {
    // Cập nhật trạng thái
    _updateConnectionType(ConnectionType.longPolling);
    _updateConnectionState(ConnectionState.connected);
    
    // Hủy timer hiện tại nếu có
    _longPollingTimer?.cancel();
    
    // Bắt đầu polling
    _performLongPolling();
    
    // Thiết lập timer cho long polling
    _longPollingTimer = Timer.periodic(
      const Duration(milliseconds: _longPollingInterval),
      (_) => _performLongPolling(),
    );
    
    // Tạo timer kiểm tra WebSocket
    _checkWebSocketTimer = Timer.periodic(
      const Duration(milliseconds: _checkWebSocketInterval),
      (_) => _checkWebSocketAvailability(),
    );
    
    // Gửi các tin nhắn đang chờ
    _sendPendingMessages();
  }
  
  /// Thực hiện long polling
  Future<bool> _performLongPolling() async {
    if (_connectionType != ConnectionType.longPolling) return false;
    
    try {
      // Kiểm tra kết nối mạng
      final isNetworkConnected = await _connectivityService.isConnected;
      if (!isNetworkConnected) {
        return false;
      }
      
      // Lấy tin nhắn từ server
      final response = await _httpClient
          .get(
            Uri.parse(
              '${_httpUrl}/realtime/poll?session_id=$_sessionId&client=flutter&last_id=${_messageController.value?.id ?? ""}',
            ),
          )
          .timeout(const Duration(seconds: 30));
      
      // Kiểm tra response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        
        // Chuyển tiếp tin nhắn
        if (data['messages'] != null && data['messages'] is List) {
          for (final message in data['messages']) {
            final realtimeMessage = RealtimeMessage.fromJson(message);
            _messageController.add(realtimeMessage);
          }
        }
        
        // Kiểm tra WebSocket status
        if (data['websocket_available'] == true) {
          _checkWebSocketAvailability();
        }
      }
      return true;
    } catch (e) {
      debugPrint('Long polling error: $e');
      return false;
    }
  }
  
  /// Kiểm tra kết nối WebSocket
  Future<void> _checkWebSocketAvailability() async {
    if (_connectionType != ConnectionType.longPolling) return;
    
    try {
      // Kiểm tra kết nối mạng
      final isNetworkConnected = await _connectivityService.isConnected;
      if (!isNetworkConnected) {
        return;
      }
      
      // Gửi request kiểm tra
      final response = await _httpClient
          .get(Uri.parse('${_httpUrl}/realtime/check'))
          .timeout(const Duration(seconds: 5));
      
      // Kiểm tra kết quả
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        
        if (data['websocket_available'] == true) {
          _switchToWebSocket();
        }
      }
    } catch (e) {
      debugPrint('WebSocket availability check error: $e');
    }
  }
  
  /// Chuyển sang WebSocket
  Future<void> _switchToWebSocket() async {
    // Hủy timer long polling
    _longPollingTimer?.cancel();
    _longPollingTimer = null;
    
    // Hủy timer kiểm tra WebSocket
    _checkWebSocketTimer?.cancel();
    _checkWebSocketTimer = null;
    
    // Reset retry counter
    _reconnectAttempts = 0;
    
    // Kết nối WebSocket
    await _connectWebSocket();
  }
  
  /// Gửi các tin nhắn đang chờ
  Future<void> _sendPendingMessages() async {
    if (_pendingMessages.isEmpty) return;
    
    // Sao chép danh sách để tránh xung đột khi gửi
    final messagesToSend = List<_PendingMessage>.from(_pendingMessages);
    _pendingMessages.clear();
    
    // Gửi từng tin nhắn
    for (final message in messagesToSend) {
      await sendMessage(message.type, message.data);
    }
  }
  
  /// Bắt đầu timer giữ kết nối
  void _startKeepAliveTimer() {
    // Hủy timer hiện tại nếu có
    _keepAliveTimer?.cancel();
    _pingPongTimer?.cancel();
    
    // Thiết lập thời gian ban đầu
    _lastPingSent = DateTime.now();
    _lastPongReceived = DateTime.now();
    
    // Tạo timer mới
    _keepAliveTimer = Timer.periodic(
      const Duration(milliseconds: _pingInterval),
      (_) => _sendPing(),
    );
  }
  
  /// Gửi ping
  void _sendPing() {
    if (_connectionType != ConnectionType.webSocket || 
        _connectionState != ConnectionState.connected) return;
    
    try {
      // Gửi ping
      _webSocketChannel?.sink.add(jsonEncode({'type': 'ping'}));
      _lastPingSent = DateTime.now();
      
      // Kiểm tra timeout
      _checkPingPongTimeout();
    } catch (e) {
      debugPrint('Error sending ping: $e');
    }
  }
  
  /// Kiểm tra timeout ping/pong
  void _checkPingPongTimeout() {
    // Hủy timer hiện tại nếu có
    _pingPongTimer?.cancel();
    
    // Tạo timer mới
    _pingPongTimer = Timer(const Duration(milliseconds: _pingTimeout), () {
      if (_lastPingSent != null && _lastPongReceived != null) {
        final pingDuration = DateTime.now().difference(_lastPingSent!).inMilliseconds;
        final pongAge = DateTime.now().difference(_lastPongReceived!).inMilliseconds;
        
        // Nếu quá thời gian timeout, thử kết nối lại
        if (pingDuration > _pingTimeout && pongAge > _pingTimeout) {
          debugPrint('Ping/Pong timeout: reconnecting...');
          _tryReconnect();
        }
      }
    });
  }
  
  /// Tạo URL WebSocket
  String _buildWebSocketUrl() {
    return '${_webSocketUrl}?session_id=$_sessionId&client=flutter&version=1.0.0';
  }
  
  /// Xử lý tin nhắn
  void _handleMessage(RealtimeMessage message) {
    _messageController.add(message);
  }
  
  /// Cập nhật trạng thái kết nối
  void _updateConnectionState(ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }
  
  /// Cập nhật loại kết nối
  void _updateConnectionType(ConnectionType type) {
    if (_connectionType != type) {
      _connectionType = type;
      _connectionTypeController.add(type);
    }
  }
}

/// Class đại diện cho một tin nhắn realtime
class RealtimeMessage {
  /// Loại tin nhắn
  final String type;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// ID tin nhắn
  final String id;
  
  /// Thời gian nhận tin nhắn
  final DateTime receivedAt;
  
  /// Constructor
  RealtimeMessage({
    required this.type,
    this.data,
    String? id,
  })  : id = id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}_${(10000 * Random().nextDouble()).floor()}',
        receivedAt = DateTime.now();
  
  /// Tạo từ JSON
  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      type: json['type'] as String,
      data: json['data'],
      id: json['id'] as String?,
    );
  }
  
  /// Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'id': id,
    };
  }
}

/// Class đại diện cho một tin nhắn đang chờ gửi
class _PendingMessage {
  /// Loại tin nhắn
  final String type;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Constructor
  _PendingMessage(this.type, this.data) : createdAt = DateTime.now();
} 