import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_chat_app/core/network/connectivity/connectivity_service.dart';
import 'package:flutter_chat_app/core/network/http/http_client_interface.dart';
import 'package:flutter_chat_app/core/network/realtime/backoff_strategy.dart';
import 'package:flutter_chat_app/core/network/realtime/connection_health_monitor.dart';
import 'package:flutter_chat_app/core/network/realtime/connection_state_machine.dart';
import 'package:flutter_chat_app/core/network/realtime/models/realtime_connection_config.dart' as models;
import 'package:flutter_chat_app/core/network/realtime/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/network/realtime/realtime_performance_metrics.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Dịch vụ kết nối realtime được tối ưu hiệu suất
///
/// Cung cấp khả năng xử lý kết nối WebSocket thông minh, tự phục hồi,
/// và chuyển đổi mượt mà giữa WebSocket và long polling.
@lazySingleton
class EnhancedRealtimeConnectionService implements IRealtimeConnectionService {
  /// Logger
  final AppLogger _logger;
  
  /// HTTP client cho các request như long polling
  final IHttpClient _httpClient;
  
  /// Service kiểm tra kết nối
  final IConnectivityService _connectivityService;
  
  /// WebSocket channel
  WebSocketChannel? _webSocketChannel;
  
  /// StreamSubscription cho WebSocket
  StreamSubscription? _webSocketSubscription;
  
  /// StreamSubscription cho theo dõi kết nối
  StreamSubscription? _connectivitySubscription;

  /// Cấu hình kết nối (mutable để support dynamic auth token updates)
  models.RealtimeConnectionConfig _config;

  /// Controllers
  final _messageController = PublishSubject<RealtimeMessage>();
  final _errorController = PublishSubject<RealtimeError>();
  final _connectionTypeController = BehaviorSubject<RealtimeConnectionType>.seeded(RealtimeConnectionType.websocket);
  
  /// Metrics theo dõi hiệu suất
  final RealtimePerformanceMetrics _metrics = RealtimePerformanceMetrics();
  
  /// State machine quản lý trạng thái kết nối
  late final ConnectionStateMachine _stateMachine;
  
  /// Monitor theo dõi sức khỏe kết nối
  late final ConnectionHealthMonitor _healthMonitor;
  
  /// Chiến lược backoff
  late final SmartBackoffStrategy _backoffStrategy;
  
  /// ID phiên
  String? _sessionId;
  
  /// Thông tin rate limit
  RateLimitInfo? _rateLimitInfo;
  
  /// Danh sách tin nhắn đang chờ
  final List<_PendingMessage> _pendingMessages = [];
  
  /// Cấu hình realtime
  final RealtimeConfig _realtimeConfig;
  
  /// Timers
  Timer? _longPollingTimer;
  Timer? _pingPongTimer;
  Timer? _batchProcessingTimer;
  
  /// Flag khởi tạo
  bool _initialized = false;
  
  /// Constructor
  EnhancedRealtimeConnectionService(
    this._logger,
    this._httpClient,
    this._connectivityService,
    this._config, [
    this._realtimeConfig = const RealtimeConfig(serverUrl: 'ws://localhost:3000'),
  ]) {
    _backoffStrategy = BackoffStrategyFactory.createForWebSocketReconnect();
    
    // Khởi tạo state machine
    _stateMachine = ConnectionStateMachine(
      connectCallback: _performConnect,
      disconnectCallback: _performDisconnect,
      backoffStrategy: _backoffStrategy,
      maxReconnectAttempts: _config.maxReconnectAttempts,
      autoReconnect: true,
    );
    
    // Lắng nghe các thay đổi trạng thái
    _stateMachine.stateStream.listen(_handleStateChange);
    
    // Khởi tạo health monitor
    _healthMonitor = ConnectionHealthMonitor(
      sendPingFunction: _sendPing,
      onHealthStateChanged: _handleHealthStateChanged,
      onZombieConnectionDetected: _handleZombieConnection,
    );
  }
  
  /// Stream theo dõi tin nhắn
  @override
  Stream<RealtimeMessage> get messageStream => _messageController.stream;
  
  /// Stream theo dõi trạng thái kết nối
  @override
  Stream<RealtimeConnectionState> get connectionStateStream => 
    _stateMachine.stateStream.map(_mapToRealtimeConnectionState);
  
  /// Stream theo dõi loại kết nối
  @override
  Stream<RealtimeConnectionType> get connectionTypeStream => _connectionTypeController.stream;
  
  /// Stream để theo dõi lỗi
  @override
  Stream<RealtimeError> get errorStream => _errorController.stream;
  
  /// Metrics hiệu suất
  @override
  RealtimePerformanceMetrics get metrics => _metrics;
  
  /// Thông tin rate limit
  @override
  RateLimitInfo? get rateLimitInfo => _rateLimitInfo;
  
  /// Trạng thái kết nối hiện tại
  @override
  RealtimeConnectionState get connectionState => 
    _mapToRealtimeConnectionState(_stateMachine.currentState);
  
  /// Kiểu kết nối hiện tại
  @override
  RealtimeConnectionType get connectionType {
    if (_stateMachine.currentState.state == ConnectionState.connected) {
      return _webSocketChannel != null
          ? RealtimeConnectionType.websocket
          : RealtimeConnectionType.sse;
    }
    return RealtimeConnectionType.websocket;
  }
  
  /// Kiểm tra kết nối đã được thiết lập chưa
  @override
  bool get isConnected => 
    _stateMachine.currentState.state == ConnectionState.connected;
  
  /// Kiểm tra đang trong quá trình kết nối
  @override
  bool get isConnecting =>
    _stateMachine.currentState.state == ConnectionState.connecting ||
    _stateMachine.currentState.state == ConnectionState.reconnecting;
  
  /// Khởi tạo service
  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _logger.d('Khởi tạo EnhancedRealtimeConnectionService');
      
      // Tạo session ID
      _sessionId = _generateSessionId();
      
      // Đăng ký lắng nghe kết nối
      _connectivitySubscription = _connectivityService
          .onConnectivityChanged
          .listen(_handleConnectivityChangeAdapter);
      
      _initialized = true;
      _logger.d('EnhancedRealtimeConnectionService đã khởi tạo thành công');
    } catch (e, stackTrace) {
      _logger.e('Lỗi khi khởi tạo EnhancedRealtimeConnectionService: $e\n$stackTrace');
      rethrow;
    }
  }
  
  /// Kết nối đến server
  @override
  Future<bool> connect() async {
    if (!_initialized) {
      await initialize();
    }
    
    // Gửi sự kiện yêu cầu kết nối tới state machine
    await _stateMachine.handleEvent(
      ConnectionEvent.connectRequested,
      reason: 'Yêu cầu kết nối từ client',
    );
    
    // Đợi một chút để state machine xử lý
    // và kết nối được thiết lập
    await Future.delayed(const Duration(milliseconds: 100));
    
    return isConnected;
  }
  
  /// Thực hiện kết nối
  Future<bool> _performConnect() async {
    _logger.d('Thực hiện kết nối WebSocket');
    
    try {
      // Thử kết nối WebSocket
      final wsSuccess = await _connectWebSocket();
      
      if (wsSuccess) {
        _logger.d('Kết nối WebSocket thành công');
        
        // Khởi động monitor
        _healthMonitor.start();
        
        // Xử lý tin nhắn đang chờ
        if (_pendingMessages.isNotEmpty) {
          _processPendingMessages();
        }
        
        return true;
      } else if (_realtimeConfig.supportLongPolling) {
        _logger.d('Kết nối WebSocket thất bại, thử long polling');
        
        // Thử long polling nếu WebSocket thất bại
        final lpSuccess = await _startLongPolling();
        
        if (lpSuccess) {
          _logger.d('Kết nối long polling thành công');
          
          // Xử lý tin nhắn đang chờ
          if (_pendingMessages.isNotEmpty) {
            _processPendingMessages();
          }
          
          return true;
        }
      }
      
      _logger.w('Tất cả phương thức kết nối đều thất bại');
      return false;
    } catch (e, stackTrace) {
      _logger.e('Lỗi khi thực hiện kết nối: $e\n$stackTrace');
      return false;
    }
  }
  
  /// Ngắt kết nối
  @override
  Future<void> disconnect({bool autoReconnect = false}) async {
    // Gửi sự kiện yêu cầu ngắt kết nối tới state machine
    await _stateMachine.handleEvent(
      ConnectionEvent.disconnectRequested,
      reason: 'Yêu cầu ngắt kết nối từ client',
    );
  }
  
  /// Thực hiện ngắt kết nối
  Future<void> _performDisconnect() async {
    _logger.d('Thực hiện ngắt kết nối');
    
    // Dừng health monitor
    _healthMonitor.stop();
    
    // Hủy các timers
    _cancelTimers();
    
    // Đóng WebSocket channel
    await _closeWebSocket();
    
    // Hủy subscriptions
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    
    _logger.d('Đã ngắt kết nối thành công');
  }
  
  /// Gửi tin nhắn đến server
  @override
  Future<void> sendMessage(RealtimeMessage message) async {
    await _sendMessageInternal(
      message.type,
      message.data,
      queueIfDisconnected: true,
      metadata: null,
    );
  }

  /// Internal method for sending messages with additional options
  Future<bool> _sendMessageInternal(
    String type,
    dynamic data, {
    bool queueIfDisconnected = true,
    Map<String, dynamic>? metadata,
  }) async {
    // Đánh dấu có hoạt động
    _healthMonitor.markActivity();
    
    try {
      // Kiểm tra kết nối
      if (!isConnected) {
        if (queueIfDisconnected) {
          _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
          _logger.d('Đã thêm vào hàng đợi tin nhắn: $type');
          return true;
        }
        return false;
      }
      
      // Kiểm tra rate limit
      if (_isRateLimited()) {
        if (queueIfDisconnected) {
          _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
          _logger.d('Rate limited, đã thêm vào hàng đợi tin nhắn: $type');
          return true;
        }
        return false;
      }
      
      // Tạo tin nhắn
      final messageData = <String, dynamic>{
        ...data as Map<String, dynamic>? ?? {},
        if (metadata != null) 'metadata': metadata,
      };

      final message = RealtimeMessage(
        id: _generateMessageId(),
        type: type,
        data: messageData,
        timestamp: DateTime.now(),
      );
      
      // Gửi tin nhắn
      final success = await _sendRaw(jsonEncode(message.toJson()));
      
      if (success) {
        _metrics.recordMessageSent();
        _logger.t('Đã gửi tin nhắn: $type');
        return true;
      } else if (queueIfDisconnected) {
        _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
        _logger.d('Gửi thất bại, đã thêm vào hàng đợi tin nhắn: $type');
        return true;
      }
      
      _metrics.recordMessageFailed();
      return false;
    } catch (e) {
      _logger.e('Lỗi khi gửi tin nhắn: $e');
      
      if (queueIfDisconnected) {
        _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
        return true;
      }
      
      _metrics.recordMessageFailed();
      return false;
    }
  }
  
  /// Gửi dữ liệu raw
  Future<bool> _sendRaw(String rawData) async {
    try {
      // Kiểm tra kết nối
      if (!isConnected) {
        return false;
      }
      
      // Gửi dữ liệu
      if (_webSocketChannel != null) {
        _webSocketChannel!.sink.add(rawData);
        return true;
      } else {
        // Sử dụng long polling
        final response = await _httpClient.post<Map<String, dynamic>>(
          '${_config.httpUrl}/send',
          data: {'message': rawData},
          headers: {
            'Authorization': 'Bearer ${_config.authToken}',
            'X-Session-ID': _sessionId ?? '',
          },
        );
        
        // Kiểm tra rate limit
        _checkRateLimitFromHeaders(response);
        
        return response.statusCode == 200;
      }
    } catch (e) {
      _logger.e('Lỗi khi gửi dữ liệu raw: $e');
      return false;
    }
  }
  
  /// Đăng ký lắng nghe các tin nhắn theo loại
  @override
  Stream<RealtimeMessage> listenForMessages(List<String> types) {
    return _messageController.stream
        .where((message) => types.contains(message.type));
  }
  
  /// Kiểm tra độ trễ kết nối
  @override
  Future<int?> checkLatency() async {
    return await _healthMonitor.measureLatency();
  }
  
  /// Thiết lập token xác thực
  @override
  Future<void> setAuthToken(String token) async {
    if (_config.authToken == token) return;
    
    // Tạo config mới với token mới
    _config = _config.copyWith(authToken: token);
    
    // Cần reconnect nếu đang kết nối
    if (isConnected) {
      await reconnect();
    }
  }
  
  /// Giải phóng tài nguyên
  @override
  Future<void> dispose() async {
    // Dừng health monitor
    _healthMonitor.stop();
    
    // Ngắt kết nối
    await disconnect();
    
    // Hủy subscriptions
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    // Giải phóng state machine
    _stateMachine.dispose();
    
    // Đóng controllers
    await _messageController.close();
    await _errorController.close();
    await _connectionTypeController.close();
    
    _logger.d('EnhancedRealtimeConnectionService đã được giải phóng');
  }
  
  /// Khởi động reconnect thủ công
  @override
  Future<bool> reconnect() async {
    await disconnect();
    return await connect();
  }
  
  /// Kiểm tra hiệu suất kết nối
  @override
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    final healthData = <String, dynamic>{
      'state': connectionState.toString(),
      'type': connectionType.toString(),
      'latency': await checkLatency(),
      'metrics': _metrics.toJson(),
      'health': {
        'state': _healthMonitor.healthState.toString(),
        'averageLatency': _healthMonitor.averageLatency,
        'minLatency': _healthMonitor.minLatency,
        'maxLatency': _healthMonitor.maxLatency,
        'isConnectionStable': _healthMonitor.isConnectionStable,
        'timeSinceLastActivityMs': _healthMonitor.timeSinceLastActivityMs,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    return healthData;
  }
  
  /// Gửi ping
  Future<bool> _sendPing(Map<String, dynamic> pingData) async {
    _metrics.recordMessageSent();
    
    try {
      final encodedPing = jsonEncode(pingData);
      final sent = await _sendRaw(encodedPing);
      
      return sent;
    } catch (e) {
      _logger.e('Lỗi khi gửi ping: $e');
      return false;
    }
  }
  
  /// Xử lý nhận pong
  void _handlePongReceived(Map<String, dynamic> pongData) {
    _healthMonitor.handlePongReceived(pongData);
  }
  
  /// Xử lý thay đổi trạng thái kết nối
  void _handleStateChange(ConnectionStateModel state) {
    _logger.d('Trạng thái kết nối thay đổi: ${state.state} (${state.reason})');

    // Cập nhật connection type stream
    _updateConnectionType(state.state);

    // Xử lý các tác vụ khi trạng thái thay đổi
    switch (state.state) {
      case ConnectionState.connected:
        // Gửi thông báo hiện tại đang online
        _sendOnlineStatusNotification(true);
        break;

      case ConnectionState.disconnected:
      case ConnectionState.error:
      case ConnectionState.closed:
        // Gửi thông báo hiện tại đang offline nếu trước đó đang online
        if (_stateMachine.currentState.state == ConnectionState.connected) {
          _sendOnlineStatusNotification(false);
        }
        break;

      default:
        break;
    }
  }

  /// Cập nhật connection type dựa trên trạng thái
  void _updateConnectionType(ConnectionState state) {
    if (state == ConnectionState.connected) {
      final connectionType = _webSocketChannel != null
          ? RealtimeConnectionType.websocket
          : RealtimeConnectionType.sse;
      _connectionTypeController.add(connectionType);
    } else {
      // Khi không kết nối, mặc định là websocket
      _connectionTypeController.add(RealtimeConnectionType.websocket);
    }
  }
  
  /// Xử lý thay đổi sức khỏe kết nối
  void _handleHealthStateChanged(ConnectionHealthState healthState, String reason) {
    _logger.d('Sức khỏe kết nối thay đổi: $healthState ($reason)');
    
    // Cập nhật vào state machine
    _stateMachine.updateHealthState(healthState, reason);
  }
  
  /// Xử lý phát hiện zombie connection
  void _handleZombieConnection() {
    _logger.w('Phát hiện zombie connection');
    
    // Gửi sự kiện zombieDetected đến state machine
    _stateMachine.handleEvent(
      ConnectionEvent.zombieDetected,
      reason: 'Phát hiện zombie connection',
    );
  }

  /// Adapter method to handle connectivity changes from bool to List<ConnectionType>
  void _handleConnectivityChangeAdapter(bool hasConnection) {
    final connectionTypes = hasConnection
        ? [ConnectionType.wifi] // Assume wifi when connected
        : [ConnectionType.none];
    _handleConnectivityChange(connectionTypes);
  }

  /// Xử lý thay đổi kết nối
  void _handleConnectivityChange(List<ConnectionType> connectionTypes) {
    final hasConnection = connectionTypes.isNotEmpty && 
                         !connectionTypes.contains(ConnectionType.none);
    
    if (hasConnection) {
      _logger.d('Kết nối mạng khả dụng');
      
      // Gửi sự kiện networkRestored đến state machine
      _stateMachine.handleEvent(
        ConnectionEvent.networkRestored,
        reason: 'Kết nối mạng khả dụng',
      );
    } else {
      _logger.d('Kết nối mạng bị mất');
      
      // Gửi sự kiện networkLost đến state machine
      _stateMachine.handleEvent(
        ConnectionEvent.networkLost,
        reason: 'Kết nối mạng bị mất',
      );
    }
  }
  
  /// Tạo một WebSocket mới
  Future<bool> _connectWebSocket() async {
    _logger.d('Đang tạo kết nối WebSocket');
    
    try {
      // Tạo URI
      final wsUrl = Uri.parse('${_config.webSocketUrl}?token=${_config.authToken}&sessionId=$_sessionId');
      
      // Khởi tạo WebSocket
      _webSocketChannel = WebSocketChannel.connect(wsUrl);
      
      // Đăng ký lắng nghe
      _webSocketSubscription = _webSocketChannel?.stream.listen(
        _handleMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );
      
      // Đợi một chút để đảm bảo kết nối đã được thiết lập
      await Future.delayed(const Duration(milliseconds: 100));
      
      _logger.d('Kết nối WebSocket thành công');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Lỗi khi kết nối WebSocket: $e\n$stackTrace');
      
      // Tạo lỗi
      final realtimeError = RealtimeError(
        message: 'WebSocket connection failed: $e',
        code: 'WEBSOCKET_ERROR',
        timestamp: DateTime.now(),
      );

      // Gửi lỗi
      _handleError(realtimeError);
      
      // Đóng WebSocket channel nếu đã tạo
      await _closeWebSocket();
      
      return false;
    }
  }
  
  /// Đóng WebSocket hiện tại
  Future<void> _closeWebSocket() async {
    if (_webSocketChannel != null) {
      try {
        await _webSocketChannel!.sink.close(ws_status.normalClosure);
      } catch (e) {
        _logger.e('Lỗi khi đóng WebSocket: $e');
      }
      
      _webSocketChannel = null;
    }
    
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
  }
  
  /// Hủy các timers
  void _cancelTimers() {
    _longPollingTimer?.cancel();
    _longPollingTimer = null;
    
    _pingPongTimer?.cancel();
    _pingPongTimer = null;
    
    _batchProcessingTimer?.cancel();
    _batchProcessingTimer = null;
  }
  
  /// Xử lý lỗi WebSocket
  void _handleWebSocketError(dynamic error) {
    final realtimeError = RealtimeError(
      code: 'WEBSOCKET_ERROR',
      message: 'WebSocket error: $error',
      timestamp: DateTime.now(),
    );

    _logger.e('Lỗi WebSocket: ${realtimeError.message}');

    // Gửi lỗi
    _handleError(realtimeError);
    
    // Gửi sự kiện connectionError đến state machine
    _stateMachine.handleEvent(
      ConnectionEvent.connectionError,
      reason: 'Lỗi WebSocket: ${realtimeError.message}',
    );
  }
  
  /// Xử lý khi WebSocket đóng kết nối
  void _handleWebSocketDone() {
    _logger.d('WebSocket đã đóng kết nối');
    
    // Gửi sự kiện connectionClosed đến state machine
    _stateMachine.handleEvent(
      ConnectionEvent.connectionClosed,
      reason: 'WebSocket đã đóng kết nối',
    );
  }
  
  /// Xử lý tin nhắn từ WebSocket
  void _handleMessage(dynamic data) {
    try {
      // Đánh dấu có hoạt động
      _healthMonitor.markActivity();
      
      // Chuyển đổi dữ liệu thành JSON
      Map<String, dynamic> jsonData;
      
      if (data is String) {
        try {
          jsonData = json.decode(data);
        } catch (e) {
          _logger.e('Lỗi khi parse tin nhắn JSON: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        jsonData = data;
      } else {
        _logger.e('Định dạng tin nhắn không hỗ trợ: ${data.runtimeType}');
        return;
      }
      
      // Kiểm tra xem có phải pong không
      if (jsonData['type'] == 'pong') {
        _handlePongReceived(jsonData);
        return;
      }
      
      // Parse thành RealtimeMessage
      final message = RealtimeMessage.fromJson(jsonData);
      
      // Gửi tin nhắn qua controller
      _messageController.add(message);
      
      // Cập nhật metrics
      _metrics.recordMessageReceived();
      
    } catch (e, stackTrace) {
      _logger.e('Lỗi khi xử lý tin nhắn: $e\n$stackTrace');

      final error = RealtimeError(
        code: 'MESSAGE_FORMAT_ERROR',
        message: 'Message processing failed: $e',
        timestamp: DateTime.now(),
      );
      
      _handleError(error);
    }
  }
  
  /// Bắt đầu long polling
  Future<bool> _startLongPolling() async {
    _logger.d('Bắt đầu long polling');
    
    try {
      // Hủy các timers hiện tại
      _cancelTimers();
      
      // Khởi tạo long polling timer
      _longPollingTimer = Timer.periodic(
        Duration(milliseconds: _config.longPollingInterval),
        (_) => _performLongPolling(),
      );
      
      _logger.d('Long polling đã bắt đầu');
      return true;
    } catch (e) {
      _logger.e('Lỗi khi bắt đầu long polling: $e');

      final error = RealtimeError(
        code: 'NETWORK_ERROR',
        message: 'Long polling failed: $e',
        timestamp: DateTime.now(),
      );
      
      _handleError(error);
      return false;
    }
  }
  
  /// Thực hiện long polling
  Future<void> _performLongPolling() async {
    if (!isConnected) return;
    
    try {
      // Thực hiện request để lấy tin nhắn mới
      final response = await _httpClient.get<Map<String, dynamic>>(
        '${_config.httpUrl}/poll',
        headers: {
          'Authorization': 'Bearer ${_config.authToken}',
          'X-Session-ID': _sessionId ?? '',
        },
      );
      
      // Kiểm tra rate limit
      _checkRateLimitFromHeaders(response);
      
      // Xử lý tin nhắn
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        if (data.containsKey('messages') && data['messages'] is List) {
          final messages = data['messages'] as List;
          
          for (final message in messages) {
            if (message is Map<String, dynamic>) {
              _handleMessage(message);
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Lỗi khi thực hiện long polling: $e');
    }
  }
  
  /// Xử lý tin nhắn đang chờ
  void _processPendingMessages() {
    if (_pendingMessages.isEmpty || !isConnected) {
      return;
    }
    
    // Tránh xử lý quá nhiều tin nhắn cùng lúc
    _batchProcessingTimer?.cancel();
    
    // Lên lịch xử lý theo batch
    _batchProcessingTimer = Timer(
      const Duration(milliseconds: 50),
      _processPendingMessagesBatch,
    );
  }
  
  /// Xử lý một batch tin nhắn đang chờ
  Future<void> _processPendingMessagesBatch() async {
    if (_pendingMessages.isEmpty || !isConnected) {
      return;
    }
    
    _logger.d('Xử lý ${_pendingMessages.length} tin nhắn đang chờ');
    
    // Tạo bản sao để tránh sửa đổi khi đang lặp
    final pendingCopy = List<_PendingMessage>.from(_pendingMessages);
    _pendingMessages.clear();
    
    // Giới hạn số lượng tin nhắn xử lý trong mỗi batch
    final batchSize = min(pendingCopy.length, 10);
    final batch = pendingCopy.sublist(0, batchSize);
    
    // Còn lại đưa lại vào hàng đợi
    if (batchSize < pendingCopy.length) {
      _pendingMessages.addAll(pendingCopy.sublist(batchSize));
    }
    
    // Xử lý batch
    for (final pending in batch) {
      final messageData = <String, dynamic>{
        ...pending.data as Map<String, dynamic>? ?? {},
        if (pending.metadata != null) 'metadata': pending.metadata,
      };

      final message = RealtimeMessage(
        id: _generateMessageId(),
        type: pending.type,
        data: messageData,
        timestamp: DateTime.now(),
      );

      final success = await _sendMessageInternal(
        pending.type,
        pending.data,
        queueIfDisconnected: false,
        metadata: pending.metadata,
      );
      
      if (!success && isConnected) {
        // Đưa lại vào đầu hàng đợi nếu thất bại
        pending.retryCount++;
        
        if (pending.retryCount < 3) {
          _pendingMessages.insert(0, pending);
        } else {
          _logger.w('Bỏ tin nhắn sau ${pending.retryCount} lần thử: ${pending.type}');
        }
      }
      
      // Pause để tránh rate limit
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    // Tiếp tục xử lý nếu còn tin nhắn
    if (_pendingMessages.isNotEmpty && isConnected) {
      // Đợi một khoảng thời gian trước khi xử lý batch tiếp theo
      _batchProcessingTimer = Timer(
        const Duration(milliseconds: 200),
        () => _processPendingMessagesBatch(),
      );
    }
  }
  
  /// Xử lý lỗi
  void _handleError(RealtimeError error) {
    _logger.e('Lỗi realtime: ${error.message}');
    
    // Gửi lỗi qua controller
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
    
    // Cập nhật metrics
    _metrics.recordError(error.code);
  }
  
  /// Chuyển đổi từ ConnectionState sang RealtimeConnectionState
  RealtimeConnectionState _mapToRealtimeConnectionState(ConnectionStateModel state) {
    switch (state.state) {
      case ConnectionState.initial:
        return RealtimeConnectionState.disconnected;
        
      case ConnectionState.connecting:
        return RealtimeConnectionState.connecting;
        
      case ConnectionState.connected:
        return RealtimeConnectionState.connected;
        
      case ConnectionState.reconnecting:
        return RealtimeConnectionState.reconnecting;
        
      case ConnectionState.waitingForNetwork:
        return RealtimeConnectionState.error;
        
      case ConnectionState.disconnected:
        return RealtimeConnectionState.disconnected;
        
      case ConnectionState.error:
        return RealtimeConnectionState.error;
        
      case ConnectionState.closed:
        return RealtimeConnectionState.disconnected;
    }
  }
  
  /// Kiểm tra rate limit
  bool _isRateLimited() {
    // TODO: Implement rate limiting
    return false;
  }
  
  /// Kiểm tra rate limit từ headers
  void _checkRateLimitFromHeaders(dynamic response) {
    // TODO: Implement rate limit from headers
  }
  
  /// Tạo một ID phiên ngẫu nhiên
  String _generateSessionId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
  
  /// Tạo một ID tin nhắn ngẫu nhiên
  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomStr = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return '$timestamp-$randomStr';
  }
  
  /// Gửi thông báo trạng thái online
  Future<void> _sendOnlineStatusNotification(bool isOnline) async {
    try {
      final message = RealtimeMessage(
        id: _generateMessageId(),
        type: 'status_update',
        data: {'online': isOnline, 'timestamp': DateTime.now().millisecondsSinceEpoch},
        timestamp: DateTime.now(),
      );

      await sendMessage(message);
    } catch (e) {
      _logger.e('Lỗi khi gửi thông báo trạng thái online: $e');
    }
  }

  @override
  Future<void> subscribe(String channel) async {
    // Implementation for channel subscription
    _logger.i('Subscribing to channel: $channel');
    // Add channel subscription logic here
  }

  @override
  Future<void> unsubscribe(String channel) async {
    // Implementation for channel unsubscription
    _logger.i('Unsubscribing from channel: $channel');
    // Add channel unsubscription logic here
  }

  @override
  List<String> get subscribedChannels {
    // Return list of subscribed channels
    return []; // Placeholder implementation
  }
}

/// Class đại diện cho một tin nhắn đang chờ gửi
class _PendingMessage {
  /// Loại tin nhắn
  final String type;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// Metadata bổ sung
  final Map<String, dynamic>? metadata;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Số lần thử gửi
  int retryCount = 0;
  
  /// Constructor
  _PendingMessage(this.type, this.data, {this.metadata}) 
      : createdAt = DateTime.now();
} 