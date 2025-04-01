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
import 'package:uuid/uuid.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/config/app_config.dart';

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
  
  /// Lỗi
  error,
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
      id: json['id'] as String? ?? const Uuid().v4(),
      type: json['type'] as String? ?? 'unknown',
      data: json['data'],
      receivedAt: json['receivedAt'] != null 
          ? DateTime.parse(json['receivedAt'] as String) 
          : DateTime.now(),
    );
  }
  
  /// Chuyển thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
    };
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
  
  /// Thời gian chờ tối đa cho mỗi lần thử kết nối (ms)
  static const int _connectionTimeout = 10000;
  
  /// Thời gian chờ tối đa cho ping-pong (ms)
  static const int _pingPongTimeout = 10000;
  
  /// Khoảng thời gian cơ bản giữa các lần kết nối lại (ms)
  static const int _baseReconnectDelay = 1000;
  
  /// Khoảng thời gian tối đa giữa các lần kết nối lại (ms)
  static const int _maxReconnectDelay = 30000;
  
  /// Khoảng thời gian giữa các lần gửi ping (ms)
  static const int _keepAliveInterval = 30000;
  
  /// Thời gian kiểm tra WebSocket sau khi long polling (ms)
  static const int _checkWebSocketInterval = 300000; // 5 phút
  
  /// ConnectivityService để kiểm tra kết nối mạng
  final ConnectivityService _connectivityService;
  
  /// HTTP Client
  final http.Client _httpClient;
  
  /// ID phiên hiện tại
  String? _sessionId;
  
  /// Đang đóng kết nối
  bool _isClosing = false;
  
  /// Đã khởi tạo
  bool _initialized = false;
  
  /// Hàng đợi tin nhắn đang chờ kết nối
  final List<_PendingMessage> _pendingMessages = [];

  /// Subscription theo dõi kết nối
  StreamSubscription? _connectivitySubscription;
  
  /// Constructor
  RealtimeConnectionService({
    required String webSocketUrl,
    required String httpUrl,
    required String authToken,
    required ConnectivityAnalyzerService connectivityAnalyzer,
    required ConnectivityService connectivityService,
  }) : _webSocketUrl = webSocketUrl,
       _httpUrl = httpUrl,
       _authToken = authToken,
       _connectivityAnalyzer = connectivityAnalyzer,
       _dio = Dio(),
       _connectivityService = connectivityService,
       _httpClient = http.Client() {
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
  
  /// Đang kết nối
  bool get isConnecting => _connectionState == ConnectionState.connecting || 
                          _connectionState == ConnectionState.reconnecting;
  
  /// Khởi tạo dịch vụ
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Đăng ký lắng nghe thay đổi kết nối
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_handleConnectivityChange);
    
    _initialized = true;
  }
  
  /// Kết nối tới server
  Future<bool> connect() async {
    // Kiểm tra đã được khởi tạo chưa
    if (!_initialized) {
      await initialize();
    }
    
    // Kiểm tra nếu đang kết nối hoặc đã kết nối
    if (isConnecting || isConnected) {
      return isConnected;
    }
    
    // Kiểm tra kết nối mạng
    if (!await _connectivityService.isConnected()) {
      _updateConnectionState(ConnectionState.error);
      return false;
    }
    
    _isClosing = false;
    _reconnectAttempts = 0;
    
    // Tạo session ID mới
    _sessionId = const Uuid().v4();
    
    // Thử kết nối WebSocket
    return _connectWebSocket();
  }
  
  /// Ngắt kết nối
  Future<void> disconnect() async {
    _isClosing = true;
    
    // Hủy các timer
    _cancelTimers();
    
    // Cập nhật trạng thái
    _updateConnectionState(ConnectionState.disconnected);
    _updateConnectionType(ConnectionType.none);
    
    // Đóng kênh WebSocket
    await _closeWebSocketChannel();
  }
  
  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await disconnect();
    
    // Đóng các controller
    await _messageController.close();
    await _connectionStateController.close();
    await _connectionTypeController.close();
    
    // Hủy subscription
    _connectivitySubscription?.cancel();
    
    // Đóng HTTP client
    _httpClient.close();
  }
  
  /// Gửi tin nhắn đến server
  Future<bool> sendMessage(
    String type,
    dynamic data, {
    Duration timeout = const Duration(seconds: 10),
    bool queueIfDisconnected = true,
  }) async {
    // Tạo tin nhắn
    final message = {
      'type': type,
      'data': data,
      'session_id': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    // Kiểm tra trạng thái kết nối
    if (!isConnected) {
      if (queueIfDisconnected) {
        // Thêm vào hàng đợi để gửi sau khi kết nối lại
        _pendingMessages.add(_PendingMessage(type, data));
        
        // Cố gắng kết nối lại nếu chưa đang kết nối
        if (!isConnecting && !_isClosing) {
          _tryReconnect();
        }
        
        return false;
      } else {
        return false;
      }
    }
    
    try {
      switch (_connectionType) {
        case ConnectionType.webSocket:
          // Gửi qua WebSocket
          _webSocketChannel!.sink.add(jsonEncode(message));
          return true;
          
        case ConnectionType.longPolling:
          // Gửi qua HTTP POST
          final response = await _httpClient
              .post(
                Uri.parse('${AppConfig.apiUrl}/realtime/send'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(message),
              )
              .timeout(timeout);
          
          return response.statusCode == 200;
          
        case ConnectionType.none:
          if (queueIfDisconnected) {
            // Thêm vào hàng đợi
            _pendingMessages.add(_PendingMessage(type, data));
            
            // Cố gắng kết nối lại
            if (!isConnecting && !_isClosing) {
              _tryReconnect();
            }
          }
          return false;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      if (queueIfDisconnected) {
        // Thêm vào hàng đợi
        _pendingMessages.add(_PendingMessage(type, data));
      }
      
      // Xử lý lỗi kết nối
      _handleConnectionError(e);
      return false;
    }
  }
  
  /// Xử lý thay đổi kết nối
  void _handleConnectivityChange(bool isConnected) {
    if (isConnected) {
      // Có kết nối mạng, thử kết nối lại nếu chưa kết nối
      if (_connectionState != ConnectionState.connected && 
          _connectionState != ConnectionState.connecting &&
          _connectionState != ConnectionState.reconnecting && 
          !_isClosing) {
        _tryReconnect();
      }
    } else {
      // Mất kết nối mạng, cập nhật trạng thái
      if (isConnected || isConnecting) {
        _updateConnectionState(ConnectionState.disconnected);
        _cancelTimers();
      }
    }
  }
  
  /// Kết nối WebSocket
  Future<bool> _connectWebSocket() async {
    _updateConnectionState(
      _reconnectAttempts > 0 
          ? ConnectionState.reconnecting 
          : ConnectionState.connecting
    );
    
    try {
      // Đóng kênh hiện tại nếu có
      await _closeWebSocketChannel();
      
      // Tạo URL kết nối với thông tin phiên
      final wsUrl = _buildWebSocketUrl();
      
      // Tạo kênh WebSocket
      _webSocketChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Đăng ký timeout
      final connectionCompleter = Completer<bool>();
      Timer? timeoutTimer;
      
      // Timeout handler
      timeoutTimer = Timer(const Duration(milliseconds: _connectionTimeout), () {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.complete(false);
        }
      });
      
      // Lắng nghe sự kiện kết nối
      final subscription = _webSocketChannel!.stream.listen(
        (dynamic data) {
          // Hủy timer timeout nếu chưa hoàn thành
          if (!connectionCompleter.isCompleted) {
            timeoutTimer?.cancel();
            connectionCompleter.complete(true);
          }
          
          // Xử lý tin nhắn
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          // Hủy timer timeout nếu chưa hoàn thành
          if (!connectionCompleter.isCompleted) {
            timeoutTimer?.cancel();
            connectionCompleter.complete(false);
          }
          
          // Xử lý lỗi
          _handleWebSocketError(error);
        },
        onDone: () {
          // Hủy timer timeout nếu chưa hoàn thành
          if (!connectionCompleter.isCompleted) {
            timeoutTimer?.cancel();
            connectionCompleter.complete(false);
          }
          
          // Xử lý đóng kết nối
          _handleWebSocketDone();
        },
      );
      
      // Chờ kết nối hoặc timeout
      final connected = await connectionCompleter.future;
      
      // Nếu không kết nối được, đóng kênh
      if (!connected) {
        subscription.cancel();
        await _closeWebSocketChannel();
        
        // Thử long polling nếu đã thử WebSocket quá nhiều lần
        if (_reconnectAttempts >= _maxReconnectAttempts) {
          return _startLongPolling();
        } else {
          _tryReconnect();
          return false;
        }
      }
      
      // Kết nối thành công
      _updateConnectionState(ConnectionState.connected);
      _updateConnectionType(ConnectionType.webSocket);
      _reconnectAttempts = 0;
      
      // Bắt đầu timer keep-alive
      _startKeepAliveTimer();
      
      // Gửi các tin nhắn đang chờ
      _sendPendingMessages();
      
      return true;
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _handleConnectionError(e);
      return false;
    }
  }
  
  /// Tạo URL WebSocket
  String _buildWebSocketUrl() {
    final wsBase = AppConfig.apiUrl.replaceFirst('http', 'ws');
    return '$wsBase/realtime/ws?session_id=$_sessionId&client=flutter&version=${AppConfig.appVersion}';
  }
  
  /// Xử lý tin nhắn WebSocket
  void _handleWebSocketMessage(dynamic data) {
    try {
      // Phân tích dữ liệu JSON
      final jsonData = json.decode(data.toString());
      
      // Xử lý tin nhắn ping-pong
      if (jsonData['type'] == 'pong') {
        _lastPongTime = DateTime.now();
        return;
      }
      
      // Tạo đối tượng tin nhắn
      final message = RealtimeMessage.fromJson(jsonData);
      
      // Phát tin nhắn
      _messageController.add(message);
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
      _handleConnectionError(e);
    }
  }
  
  /// Xử lý lỗi WebSocket
  void _handleWebSocketError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _handleConnectionError(error);
  }
  
  /// Xử lý đóng kết nối WebSocket
  void _handleWebSocketDone() {
    // Kiểm tra không phải đang đóng chủ động
    if (!_isClosing) {
      debugPrint('WebSocket connection closed unexpectedly');
      _updateConnectionState(ConnectionState.disconnected);
      _updateConnectionType(ConnectionType.none);
      
      // Thử kết nối lại
      _tryReconnect();
    } else {
      _updateConnectionState(ConnectionState.closed);
      _updateConnectionType(ConnectionType.none);
    }
  }
  
  /// Đóng kênh WebSocket
  Future<void> _closeWebSocketChannel() async {
    if (_webSocketChannel != null) {
      try {
        await _webSocketChannel!.sink.close();
        _webSocketChannel = null;
      } catch (e) {
        debugPrint('Error closing WebSocket channel: $e');
      }
    }
  }
  
  /// Hủy các timer
  void _cancelTimers() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    
    _longPollingTimer?.cancel();
    _longPollingTimer = null;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Xử lý lỗi kết nối
  void _handleConnectionError(dynamic error) {
    if (_connectionState != ConnectionState.error) {
      _updateConnectionState(ConnectionState.error);
      
      // Thử kết nối lại
      _tryReconnect();
    }
  }
  
  /// Thử kết nối lại
  void _tryReconnect() {
    // Hủy timer hiện tại nếu có
    _reconnectTimer?.cancel();
    
    // Kiểm tra số lần thử
    if (_reconnectAttempts >= _maxReconnectAttempts && _connectionType != ConnectionType.longPolling) {
      debugPrint('Switching to long polling after $_reconnectAttempts WebSocket attempts');
      _startLongPolling();
      return;
    }
    
    // Tăng số lần thử
    _reconnectAttempts++;
    
    // Tính toán độ trễ với exponential backoff
    final delay = min(
      _baseReconnectDelay * pow(1.5, _reconnectAttempts - 1),
      _maxReconnectDelay,
    ).toInt();
    
    debugPrint('Reconnect attempt $_reconnectAttempts in ${delay}ms');
    
    // Set timer reconnect
    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      // Kiểm tra kết nối mạng trước khi thử lại
      if (await _connectivityService.isConnected()) {
        _connectWebSocket();
      } else {
        _updateConnectionState(ConnectionState.disconnected);
      }
    });
  }
  
  /// Bắt đầu long polling
  Future<bool> _startLongPolling() async {
    debugPrint('Starting long polling');
    
    // Đóng WebSocket nếu đang có
    await _closeWebSocketChannel();
    
    // Cập nhật trạng thái
    _updateConnectionType(ConnectionType.longPolling);
    _updateConnectionState(ConnectionState.connecting);
    
    // Bắt đầu polling
    final success = await _performLongPolling();
    
    if (success) {
      // Cập nhật trạng thái
      _updateConnectionState(ConnectionState.connected);
      
      // Tạo timer cho long polling
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
      
      return true;
    } else {
      // Cập nhật trạng thái
      _updateConnectionState(ConnectionState.error);
      
      // Thử lại sau
      _tryReconnect();
      return false;
    }
  }
  
  /// Thực hiện long polling
  Future<bool> _performLongPolling() async {
    if (_isClosing) return false;
    
    try {
      // Kiểm tra kết nối mạng
      if (!await _connectivityService.isConnected()) {
        return false;
      }
      
      // Gửi request lấy tin nhắn
      final response = await _httpClient
          .get(
            Uri.parse(
              '${AppConfig.apiUrl}/realtime/poll?session_id=$_sessionId&client=flutter&last_id=${_messageController.value?.id ?? ""}',
            ),
          )
          .timeout(const Duration(seconds: 30));
      
      // Kiểm tra kết quả
      if (response.statusCode == 200) {
        // Phân tích dữ liệu
        final responseData = json.decode(response.body);
        
        // Kiểm tra nếu server báo WebSocket khả dụng
        if (responseData['websocket_available'] == true) {
          _switchToWebSocket();
          return true;
        }
        
        // Xử lý tin nhắn
        if (responseData['messages'] != null) {
          for (final messageData in responseData['messages']) {
            final message = RealtimeMessage.fromJson(messageData);
            _messageController.add(message);
          }
        }
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Long polling error: $e');
      _handleConnectionError(e);
      return false;
    }
  }
  
  /// Kiểm tra WebSocket khả dụng
  Future<void> _checkWebSocketAvailability() async {
    if (_connectionType == ConnectionType.longPolling && !_isClosing) {
      try {
        // Kiểm tra kết nối mạng
        if (!await _connectivityService.isConnected()) {
          return;
        }
        
        // Gửi request kiểm tra
        final response = await _httpClient
            .get(Uri.parse('${AppConfig.apiUrl}/realtime/check'))
            .timeout(const Duration(seconds: 5));
        
        // Kiểm tra kết quả
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Chuyển sang WebSocket nếu khả dụng
          if (data['websocket_available'] == true) {
            _switchToWebSocket();
          }
        }
      } catch (e) {
        debugPrint('WebSocket availability check failed: $e');
      }
    }
  }
  
  /// Chuyển từ long polling sang WebSocket
  Future<void> _switchToWebSocket() async {
    debugPrint('Switching from long polling to WebSocket');
    
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
  
  /// Bắt đầu timer keep-alive
  void _startKeepAliveTimer() {
    // Hủy timer hiện tại nếu có
    _keepAliveTimer?.cancel();
    
    // Tạo timer mới
    _keepAliveTimer = Timer.periodic(
      const Duration(milliseconds: _keepAliveInterval),
      (_) => _sendPing(),
    );
  }
  
  /// Gửi ping để giữ kết nối
  void _sendPing() {
    if (_connectionType == ConnectionType.webSocket && _webSocketChannel != null) {
      try {
        // Lưu thời gian gửi
        _lastPingTime = DateTime.now();
        
        // Gửi ping
        _webSocketChannel!.sink.add(
          jsonEncode({
            'type': 'ping',
            'data': {'timestamp': _lastPingTime!.millisecondsSinceEpoch},
            'session_id': _sessionId,
          }),
        );
        
        // Bắt đầu timeout timer
        _startPingPongTimeoutTimer();
      } catch (e) {
        debugPrint('Error sending ping: $e');
        _handleConnectionError(e);
      }
    }
  }
  
  /// Bắt đầu timer kiểm tra timeout ping/pong
  void _startPingPongTimeoutTimer() {
    // Hủy timer hiện tại nếu có
    _keepAliveTimer?.cancel();
    
    // Tạo timer mới
    _keepAliveTimer = Timer(
      const Duration(milliseconds: _pingPongTimeout),
      _checkPingPongTimeout,
    );
  }
  
  /// Kiểm tra timeout ping/pong
  void _checkPingPongTimeout() {
    // Kiểm tra nếu không nhận được pong
    if (_lastPingTime != null &&
        _lastPongTime == null ||
        (_lastPongTime != null &&
         _lastPingTime!.isAfter(_lastPongTime!))) {
      
      debugPrint('Ping-pong timeout');
      
      // Ngắt kết nối và thử lại
      _closeWebSocketChannel();
      _updateConnectionState(ConnectionState.disconnected);
      _updateConnectionType(ConnectionType.none);
      
      // Thử kết nối lại
      _tryReconnect();
    }
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
  
  /// Gửi các tin nhắn đang chờ
  Future<void> _sendPendingMessages() async {
    if (_pendingMessages.isEmpty || !isConnected) {
      return;
    }
    
    debugPrint('Sending ${_pendingMessages.length} pending messages');
    
    // Tạo bản sao để tránh sửa đổi danh sách trong khi đang duyệt
    final pendingMessagesCopy = List<_PendingMessage>.from(_pendingMessages);
    _pendingMessages.clear();
    
    // Gửi từng tin nhắn
    for (final message in pendingMessagesCopy) {
      final success = await sendMessage(
        message.type,
        message.data,
        queueIfDisconnected: true,
      );
      
      // Nếu không gửi được, có thể đã mất kết nối
      if (!success) {
        break;
      }
    }
  }
}

/// Lớp lưu trữ tin nhắn đang chờ gửi
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
} 