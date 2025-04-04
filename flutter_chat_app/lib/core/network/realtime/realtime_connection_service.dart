import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../connectivity/connectivity_service.dart';
import '../http/http_client_interface.dart';
import 'realtime_error.dart';
import 'realtime_message.dart';
import 'realtime_performance_metrics.dart';

/// Định nghĩa các loại kết nối realtime
enum RealtimeConnectionType {
  /// Kết nối WebSocket
  webSocket,
  
  /// Kết nối dựa trên long polling
  longPolling,
  
  /// Không có kết nối
  none,
}

/// Định nghĩa các trạng thái kết nối
enum RealtimeConnectionState {
  /// Chưa kết nối
  disconnected,
  
  /// Đang kết nối
  connecting,
  
  /// Đã kết nối
  connected,
  
  /// Đang thử kết nối lại
  reconnecting,
  
  /// Kết nối bị lỗi
  error,
  
  /// Kết nối bị đóng
  closed,
}

/// Cấu hình cho RealtimeConnectionService
class RealtimeConnectionConfig {
  /// URL cho WebSocket
  final String webSocketUrl;
  
  /// URL cho HTTP
  final String httpUrl;
  
  /// Token xác thực
  final String authToken;
  
  /// Số lần thử kết nối tối đa
  final int maxReconnectAttempts;
  
  /// Thời gian ban đầu giữa các lần thử kết nối (ms)
  final int initialReconnectDelay;
  
  /// Hệ số tăng thời gian thử lại
  final double reconnectBackoffFactor;
  
  /// Timeout cho kết nối (ms)
  final int connectionTimeout;
  
  /// Thời gian giữa các lần ping (ms)
  final int pingInterval;
  
  /// Thời gian timeout cho ping (ms)
  final int pingTimeout;
  
  /// Thời gian giữa các lần poll (ms)
  final int longPollingInterval;
  
  /// Giới hạn số lượng tin nhắn mỗi phút
  final int messageRateLimit;
  
  /// Thời gian chờ giữa các request khi vượt quá rate limit (ms)
  final int rateLimitBackoffMs;
  
  /// Có sử dụng connection pooling không
  final bool useConnectionPool;
  
  /// Số lượng kết nối tối đa trong pool
  final int maxConnectionPoolSize;
  
  /// Headers bổ sung
  final Map<String, String>? additionalHeaders;
  
  /// Constructor
  RealtimeConnectionConfig({
    required this.webSocketUrl,
    required this.httpUrl,
    required this.authToken,
    this.maxReconnectAttempts = 10,
    this.initialReconnectDelay = 1000,
    this.reconnectBackoffFactor = 1.5,
    this.connectionTimeout = 15000,
    this.pingInterval = 30000,
    this.pingTimeout = 10000,
    this.longPollingInterval = 3000,
    this.messageRateLimit = 120, // 120 tin nhắn mỗi phút
    this.rateLimitBackoffMs = 1000, // 1 giây
    this.useConnectionPool = false,
    this.maxConnectionPoolSize = 5,
    this.additionalHeaders,
  });
}

/// Interface cho RealtimeConnectionService
abstract class IRealtimeConnectionService {
  /// Stream theo dõi tin nhắn
  Stream<RealtimeMessage> get messageStream;
  
  /// Stream theo dõi trạng thái kết nối
  Stream<RealtimeConnectionState> get connectionStateStream;
  
  /// Stream theo dõi loại kết nối
  Stream<RealtimeConnectionType> get connectionTypeStream;
  
  /// Stream để theo dõi lỗi
  Stream<RealtimeError> get errorStream;
  
  /// Metrics hiệu suất
  RealtimePerformanceMetrics get metrics;
  
  /// Thông tin rate limit
  RateLimitInfo? get rateLimitInfo;
  
  /// Trạng thái kết nối hiện tại
  RealtimeConnectionState get connectionState;
  
  /// Kiểu kết nối hiện tại
  RealtimeConnectionType get connectionType;
  
  /// Kiểm tra kết nối đã được thiết lập chưa
  bool get isConnected;
  
  /// Kiểm tra đang trong quá trình kết nối
  bool get isConnecting;
  
  /// Khởi tạo service
  Future<void> initialize();
  
  /// Kết nối đến server
  Future<bool> connect();
  
  /// Ngắt kết nối
  Future<void> disconnect({bool autoReconnect = false});
  
  /// Gửi tin nhắn đến server
  Future<bool> sendMessage(
    String type,
    dynamic data, {
    bool queueIfDisconnected = true,
    Map<String, dynamic>? metadata,
  });
  
  /// Đăng ký lắng nghe các tin nhắn theo loại
  Stream<RealtimeMessage> listenForMessages(List<String> types);
  
  /// Kiểm tra độ trễ kết nối
  Future<int?> checkLatency();
  
  /// Thiết lập token xác thực
  Future<void> setAuthToken(String token);
  
  /// Giải phóng tài nguyên
  Future<void> dispose();
  
  /// Khởi động reconnect thủ công
  Future<bool> reconnect();
  
  /// Kiểm tra hiệu suất kết nối
  Future<Map<String, dynamic>> checkConnectionHealth();
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

/// Implementation của IRealtimeConnectionService
@LazySingleton(as: IRealtimeConnectionService)
class RealtimeConnectionService implements IRealtimeConnectionService {
  /// WebSocket channel
  WebSocketChannel? _webSocketChannel;
  
  /// Kiểu kết nối hiện tại
  RealtimeConnectionType _connectionType = RealtimeConnectionType.none;
  
  /// Trạng thái kết nối hiện tại
  RealtimeConnectionState _connectionState = RealtimeConnectionState.disconnected;
  
  /// Controller cho stream kết nối
  final _connectionStateController = BehaviorSubject<RealtimeConnectionState>.seeded(RealtimeConnectionState.disconnected);
  
  /// Controller cho stream tin nhắn
  final _messageController = PublishSubject<RealtimeMessage>();
  
  /// Controller cho stream kiểu kết nối
  final _connectionTypeController = BehaviorSubject<RealtimeConnectionType>.seeded(RealtimeConnectionType.none);
  
  /// Controller cho stream error
  final _errorController = PublishSubject<RealtimeError>();
  
  /// Flag đánh dấu đã khởi tạo
  bool _initialized = false;
  
  /// Cấu hình kết nối
  RealtimeConnectionConfig _config;
  
  /// Số lần thử kết nối lại
  int _reconnectAttempts = 0;
  
  /// HTTP client
  final IHttpClient _httpClient;
  
  /// Service kiểm tra kết nối
  final IConnectivityService _connectivityService;
  
  /// Timer cho việc thử kết nối lại
  Timer? _reconnectTimer;
  
  /// Timer cho việc poll định kỳ
  Timer? _longPollingTimer;
  
  /// Timer cho việc gửi ping
  Timer? _keepAliveTimer;
  
  /// Timer cho việc kiểm tra timeout ping
  Timer? _pingPongTimer;
  
  /// Timer cho việc kiểm tra kết nối
  Timer? _connectionCheckTimer;
  
  /// Thời gian ping gần nhất
  DateTime? _lastPingSent;
  
  /// Thời gian pong gần nhất
  DateTime? _lastPongReceived;
  
  /// Hàng đợi tin nhắn chờ gửi
  final List<_PendingMessage> _pendingMessages = [];
  
  /// Đăng ký lắng nghe kết nối
  StreamSubscription? _connectivitySubscription;
  
  /// StreamSubscription cho WebSocket
  StreamSubscription? _webSocketSubscription;
  
  /// ID phiên hiện tại
  String? _sessionId;
  
  /// Flag đánh dấu có nên tự động kết nối lại khi mất kết nối
  bool _autoReconnect = true;
  
  /// Độ trễ kết nối cuối cùng đo được (ms)
  int? _lastMeasuredLatency;
  
  /// Completer cho việc kiểm tra độ trễ
  Completer<int?>? _latencyCompleter;
  
  /// Thời gian gửi ping latency
  DateTime? _latencyPingSentTime;
  
  /// Metrics theo dõi hiệu suất
  final RealtimePerformanceMetrics _metrics = RealtimePerformanceMetrics();
  
  /// Thông tin rate limit
  RateLimitInfo? _rateLimitInfo;
  
  /// Timestamp gửi tin nhắn gần nhất
  final List<DateTime> _messageTimestamps = [];
  
  /// Constructor
  @factoryMethod
  RealtimeConnectionService(
    this._httpClient,
    this._connectivityService,
    @Named('realtimeConfig') this._config,
  ) {
    // Lắng nghe sự thay đổi kết nối
    _connectivitySubscription = _connectivityService.connectivityStream
        .listen(_handleConnectivityChange);
  }
  
  @override
  Stream<RealtimeMessage> get messageStream => _messageController.stream;
  
  @override
  Stream<RealtimeConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  @override
  Stream<RealtimeConnectionType> get connectionTypeStream => _connectionTypeController.stream;
  
  @override
  Stream<RealtimeError> get errorStream => _errorController.stream;
  
  @override
  RealtimePerformanceMetrics get metrics => _metrics;
  
  @override
  RateLimitInfo? get rateLimitInfo => _rateLimitInfo;
  
  @override
  RealtimeConnectionState get connectionState => _connectionState;
  
  @override
  RealtimeConnectionType get connectionType => _connectionType;
  
  @override
  bool get isConnected => _connectionState == RealtimeConnectionState.connected;
  
  @override
  bool get isConnecting => 
      _connectionState == RealtimeConnectionState.connecting || 
      _connectionState == RealtimeConnectionState.reconnecting;
  
  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Tạo ID phiên mới
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${(Random().nextDouble() * 1000).floor()}';
    
    _metrics.reset();
    
    _initialized = true;
    
    // Thử kết nối ngay lập tức nếu có mạng
    final hasNetwork = await _connectivityService.isConnected();
    if (hasNetwork) {
      // Kết nối sau một khoảng thời gian ngắn để cho phép các service khác khởi tạo
      Future.delayed(const Duration(milliseconds: 100), () => connect());
    }
  }
  
  @override
  Future<bool> connect() async {
    if (_connectionState == RealtimeConnectionState.connected || 
        _connectionState == RealtimeConnectionState.connecting) {
      return isConnected;
    }
    
    _updateConnectionState(RealtimeConnectionState.connecting);
    _metrics.recordConnectionStart();
    
    // Kiểm tra kết nối mạng
    final isNetworkConnected = await _connectivityService.isConnected();
    if (!isNetworkConnected) {
      final error = RealtimeError(
        type: RealtimeErrorType.networkError,
        message: 'Cannot connect: no network connection',
      );
      _handleError(error);
      _metrics.recordConnectionFailure();
      return false;
    }
    
    // Đặt lại số lần thử kết nối
    _reconnectAttempts = 0;
    
    try {
      // Thử kết nối WebSocket
      final success = await _connectWebSocket();
      
      // Nếu không thành công, thử long polling
      if (!success && _connectionType != RealtimeConnectionType.longPolling) {
        debugPrint('WebSocket connection failed, falling back to long polling');
        await _startLongPolling();
      }
      
      // Xử lý tin nhắn đang chờ
      if (isConnected && _pendingMessages.isNotEmpty) {
        _processPendingMessages();
      }
      
      // Khởi động timer kiểm tra kết nối
      _startConnectionChecker();
      
      if (isConnected) {
        _metrics.recordConnectionSuccess();
      } else {
        _metrics.recordConnectionFailure();
      }
      
      return isConnected;
    } catch (e) {
      final error = RealtimeError.fromException(e, type: RealtimeErrorType.webSocketError);
      _handleError(error);
      _metrics.recordConnectionFailure();
      return false;
    }
  }
  
  @override
  Future<void> disconnect({bool autoReconnect = false}) async {
    _autoReconnect = autoReconnect;
    
    if (_connectionState == RealtimeConnectionState.disconnected ||
        _connectionState == RealtimeConnectionState.closed) {
      return;
    }
    
    _updateConnectionState(RealtimeConnectionState.disconnected);
    _metrics.recordDisconnect();
    
    // Hủy các timer
    _cancelTimers();
    
    // Đóng WebSocket
    await _closeWebSocket();
    
    // Hủy đăng ký WebSocket
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    
    _updateConnectionType(RealtimeConnectionType.none);
    
    debugPrint('Disconnected from realtime service');
  }
  
  @override
  Future<bool> sendMessage(
    String type,
    dynamic data, {
    bool queueIfDisconnected = true,
    Map<String, dynamic>? metadata,
  }) async {
    // Kiểm tra rate limit
    if (!_checkRateLimit()) {
      final error = RealtimeError(
        type: RealtimeErrorType.rateLimitExceeded,
        message: 'Rate limit exceeded, max ${_config.messageRateLimit} messages per minute',
        details: {'rateLimit': _config.messageRateLimit},
      );
      _handleError(error);
      
      if (queueIfDisconnected) {
        _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
        debugPrint('Added message to pending queue due to rate limit: $type');
      }
      
      _metrics.recordMessageFailed();
      return false;
    }
    
    // Nếu đang kết nối, gửi ngay
    if (isConnected) {
      final message = RealtimeMessage(
        type: type,
        data: data,
        metadata: metadata,
      );
      
      try {
        // Thêm timestamp để theo dõi rate limit
        _messageTimestamps.add(DateTime.now());
        
        // Giới hạn số lượng timestamps lưu trữ
        if (_messageTimestamps.length > _config.messageRateLimit) {
          _messageTimestamps.removeAt(0);
        }
        
        switch (_connectionType) {
          case RealtimeConnectionType.webSocket:
            _webSocketChannel?.sink.add(jsonEncode(message.toJson()));
            _metrics.recordMessageSent();
            return true;
            
          case RealtimeConnectionType.longPolling:
            final response = await _httpClient.post<Map<String, dynamic>>(
              '${_config.httpUrl}/send',
              data: message.toJson(),
              headers: {
                'Authorization': 'Bearer ${_config.authToken}',
                'X-Session-ID': _sessionId ?? '',
                ..._config.additionalHeaders ?? {},
              },
            );
            
            // Kiểm tra rate limit từ response headers
            _checkRateLimitFromHeaders(response);
            
            _metrics.recordMessageSent();
            return true;
            
          case RealtimeConnectionType.none:
            // Không có kết nối
            if (queueIfDisconnected) {
              _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
              debugPrint('Added message to pending queue: $type');
            }
            
            _metrics.recordMessageFailed();
            return false;
        }
      } catch (e) {
        final error = RealtimeError.fromException(e, type: RealtimeErrorType.messageSendError);
        _handleError(error);
        
        if (queueIfDisconnected) {
          _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
          debugPrint('Added message to pending queue after error: $type');
        }
        
        _metrics.recordMessageFailed();
        return false;
      }
    } else if (queueIfDisconnected) {
      // Thêm vào hàng đợi để gửi sau
      _pendingMessages.add(_PendingMessage(type, data, metadata: metadata));
      debugPrint('Added message to pending queue (not connected): $type');
      
      // Thử kết nối nếu có thể
      if (_connectionState == RealtimeConnectionState.disconnected && _autoReconnect) {
        connect();
      }
      
      _metrics.recordMessageFailed();
      return false;
    }
    
    _metrics.recordMessageFailed();
    return false;
  }
  
  @override
  Stream<RealtimeMessage> listenForMessages(List<String> types) {
    return _messageController.stream.where((message) => types.contains(message.type));
  }
  
  @override
  Future<int?> checkLatency() async {
    if (!isConnected) {
      return null;
    }
    
    _latencyCompleter = Completer<int?>();
    
    // Gửi ping latency
    _latencyPingSentTime = DateTime.now();
    
    // Xác định thời gian timeout
    final timeout = Duration(milliseconds: _config.pingTimeout);
    
    try {
      switch (_connectionType) {
        case RealtimeConnectionType.webSocket:
          _webSocketChannel?.sink.add(jsonEncode({
            'type': 'latency_ping',
            'id': 'latency_${DateTime.now().millisecondsSinceEpoch}',
            'data': {'timestamp': _latencyPingSentTime!.millisecondsSinceEpoch},
          }));
          
          // Đợi kết quả hoặc timeout
          final result = await _latencyCompleter!.future.timeout(
            timeout,
            onTimeout: () {
              _latencyCompleter = null;
              _latencyPingSentTime = null;
              return null;
            },
          );
          
          // Lưu kết quả vào metrics
          if (result != null) {
            _metrics.recordLatency(result);
          }
          
          return result;
          
        case RealtimeConnectionType.longPolling:
          // Đo latency bằng HTTP request đơn giản
          final stopwatch = Stopwatch()..start();
          
          await _httpClient.get(
            '${_config.httpUrl}/ping',
            headers: {
              'Authorization': 'Bearer ${_config.authToken}',
              'X-Session-ID': _sessionId ?? '',
              ..._config.additionalHeaders ?? {},
            },
          );
          
          stopwatch.stop();
          _lastMeasuredLatency = stopwatch.elapsedMilliseconds;
          
          // Lưu kết quả vào metrics
          _metrics.recordLatency(_lastMeasuredLatency!);
          
          return _lastMeasuredLatency;
          
        case RealtimeConnectionType.none:
          return null;
      }
    } catch (e) {
      final error = RealtimeError.fromException(e, type: RealtimeErrorType.timeout);
      _handleError(error);
      
      _latencyCompleter = null;
      _latencyPingSentTime = null;
      return null;
    }
  }
  
  @override
  Future<void> setAuthToken(String token) async {
    final needReconnect = isConnected && _config.authToken != token;
    
    // Tạo cấu hình mới với token mới
    final newConfig = RealtimeConnectionConfig(
      webSocketUrl: _config.webSocketUrl,
      httpUrl: _config.httpUrl,
      authToken: token,
      maxReconnectAttempts: _config.maxReconnectAttempts,
      initialReconnectDelay: _config.initialReconnectDelay,
      reconnectBackoffFactor: _config.reconnectBackoffFactor,
      connectionTimeout: _config.connectionTimeout,
      pingInterval: _config.pingInterval,
      pingTimeout: _config.pingTimeout,
      longPollingInterval: _config.longPollingInterval,
      messageRateLimit: _config.messageRateLimit,
      rateLimitBackoffMs: _config.rateLimitBackoffMs,
      useConnectionPool: _config.useConnectionPool,
      maxConnectionPoolSize: _config.maxConnectionPoolSize,
      additionalHeaders: _config.additionalHeaders,
    );
    
    // Gán cấu hình mới
    _updateConfig(newConfig);
    
    // Kết nối lại nếu cần
    if (needReconnect) {
      await disconnect(autoReconnect: true);
      await connect();
    }
  }
  
  @override
  Future<void> dispose() async {
    await disconnect(autoReconnect: false);
    
    // Hủy đăng ký lắng nghe thay đổi kết nối
    await _connectivitySubscription?.cancel();
    
    // Đóng các controller
    await _connectionStateController.close();
    await _messageController.close();
    await _connectionTypeController.close();
    await _errorController.close();
    
    _initialized = false;
    
    debugPrint('Disposed realtime connection service');
  }
  
  /// Kết nối WebSocket
  Future<bool> _connectWebSocket() async {
    try {
      // Đóng WebSocket hiện tại nếu có
      await _closeWebSocket();
      
      // Tạo URL WebSocket
      final url = _buildWebSocketUrl();
      debugPrint('Connecting to WebSocket: $url');
      
      // Tạo WebSocket mới
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(url));
      
      // Đợi kết nối
      final connectCompleter = Completer<bool>();
      
      // Thiết lập timeout
      final timeoutTimer = Timer(
        Duration(milliseconds: _config.connectionTimeout),
        () {
          if (!connectCompleter.isCompleted) {
            final error = RealtimeError(
              type: RealtimeErrorType.timeout,
              message: 'WebSocket connection timeout after ${_config.connectionTimeout}ms',
            );
            _handleError(error);
            connectCompleter.complete(false);
          }
        },
      );
      
      // Lắng nghe sự kiện từ WebSocket
      _webSocketSubscription = _webSocketChannel!.stream.listen(
        (data) {
          // Hoàn thành kết nối nếu chưa
          if (!connectCompleter.isCompleted) {
            debugPrint('WebSocket connected');
            connectCompleter.complete(true);
            timeoutTimer.cancel();
          }
          
          // Xử lý dữ liệu
          _processWebSocketMessage(data);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          
          // Hoàn thành kết nối với lỗi nếu chưa
          if (!connectCompleter.isCompleted) {
            connectCompleter.complete(false);
            timeoutTimer.cancel();
          }
          
          _updateConnectionState(RealtimeConnectionState.error);
          _tryReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          
          // Hoàn thành kết nối nếu chưa
          if (!connectCompleter.isCompleted) {
            connectCompleter.complete(false);
            timeoutTimer.cancel();
          }
          
          _updateConnectionState(RealtimeConnectionState.closed);
          
          // Thử kết nối lại nếu cần
          if (_autoReconnect) {
            _tryReconnect();
          }
        },
      );
      
      // Đợi kết quả
      final success = await connectCompleter.future;
      
      if (success) {
        _updateConnectionState(RealtimeConnectionState.connected);
        _updateConnectionType(RealtimeConnectionType.webSocket);
        
        // Khởi động timer keep-alive
        _startKeepAliveTimer();
        
        return true;
      }
      
      return false;
    } catch (e) {
      final error = RealtimeError.fromException(e, type: RealtimeErrorType.webSocketError);
      _handleError(error);
      return false;
    }
  }
  
  /// Khởi động long polling
  Future<bool> _startLongPolling() async {
    try {
      debugPrint('Starting long polling');
      
      // Cập nhật loại kết nối
      _updateConnectionType(RealtimeConnectionType.longPolling);
      _updateConnectionState(RealtimeConnectionState.connected);
      
      // Thiết lập timer poll định kỳ
      _longPollingTimer?.cancel();
      _longPollingTimer = Timer.periodic(
        Duration(milliseconds: _config.longPollingInterval),
        (_) => _poll(),
      );
      
      // Tạo session
      await _createLongPollingSession();
      
      return true;
    } catch (e) {
      debugPrint('Error starting long polling: $e');
      _updateConnectionState(RealtimeConnectionState.error);
      return false;
    }
  }
  
  /// Tạo phiên long polling
  Future<void> _createLongPollingSession() async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '${_config.httpUrl}/session',
        data: {
          'sessionId': _sessionId,
          'clientInfo': {
            'type': 'flutter',
            'version': '1.0.0',
            'platform': defaultTargetPlatform.toString(),
          },
        },
        headers: {
          'Authorization': 'Bearer ${_config.authToken}',
          ..._config.additionalHeaders ?? {},
        },
      );
      
      debugPrint('Long polling session created');
    } catch (e) {
      debugPrint('Error creating long polling session: $e');
      throw e;
    }
  }
  
  /// Thực hiện long polling
  Future<void> _poll() async {
    if (_connectionType != RealtimeConnectionType.longPolling || 
        _connectionState != RealtimeConnectionState.connected) {
      return;
    }
    
    try {
      final response = await _httpClient.get<List<dynamic>>(
        '${_config.httpUrl}/poll',
        queryParams: {'sessionId': _sessionId},
        headers: {
          'Authorization': 'Bearer ${_config.authToken}',
          ..._config.additionalHeaders ?? {},
        },
      );
      
      // Xử lý các tin nhắn nhận được
      if (response != null) {
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            final message = RealtimeMessage.fromJson(item);
            _handleMessage(message);
          }
        }
      }
    } catch (e) {
      debugPrint('Error polling: $e');
      
      // Nếu lỗi liên tục, thử kết nối lại
      _tryReconnect();
    }
  }
  
  /// Thử kết nối lại
  void _tryReconnect() {
    if (_reconnectTimer != null || 
        _connectionState == RealtimeConnectionState.connecting ||
        _connectionState == RealtimeConnectionState.reconnecting) {
      return;
    }
    
    // Kiểm tra số lần thử kết nối
    if (_reconnectAttempts >= _config.maxReconnectAttempts) {
      final error = RealtimeError(
        type: RealtimeErrorType.networkError,
        message: 'Maximum reconnect attempts reached (${_config.maxReconnectAttempts})',
      );
      _handleError(error);
      _updateConnectionState(RealtimeConnectionState.error);
      return;
    }
    
    _reconnectAttempts++;
    _updateConnectionState(RealtimeConnectionState.reconnecting);
    _metrics.recordReconnectAttempt();
    
    // Tính thời gian đợi
    final delay = _calculateReconnectDelay();
    debugPrint('Reconnecting in $delay ms (attempt $_reconnectAttempts)');
    
    // Thiết lập timer
    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      _reconnectTimer = null;
      
      // Kiểm tra kết nối mạng
      final hasNetwork = await _connectivityService.isConnected();
      if (!hasNetwork) {
        debugPrint('Cannot reconnect: no network connection');
        _updateConnectionState(RealtimeConnectionState.error);
        return;
      }
      
      // Thử kết nối WebSocket
      final success = await _connectWebSocket();
      
      // Nếu không thành công, thử long polling
      if (!success && _connectionType != RealtimeConnectionType.longPolling) {
        await _startLongPolling();
      }
      
      // Xử lý tin nhắn đang chờ
      if (isConnected && _pendingMessages.isNotEmpty) {
        _processPendingMessages();
      }
    });
  }
  
  /// Tính thời gian đợi giữa các lần thử kết nối
  int _calculateReconnectDelay() {
    final baseDelay = _config.initialReconnectDelay;
    final factor = _config.reconnectBackoffFactor;
    
    // Tăng theo hàm mũ với một chút nhiễu ngẫu nhiên
    final exponentialDelay = baseDelay * pow(factor, _reconnectAttempts - 1);
    final jitter = Random().nextDouble() * 0.3 * exponentialDelay;
    
    return (exponentialDelay + jitter).toInt();
  }
  
  /// Cập nhật cấu hình
  void _updateConfig(RealtimeConnectionConfig config) {
    _config = config;
  }
  
  /// Đóng WebSocket
  Future<void> _closeWebSocket() async {
    if (_webSocketChannel != null) {
      try {
        await _webSocketChannel!.sink.close(ws_status.normalClosure);
      } catch (e) {
        debugPrint('Error closing WebSocket: $e');
      }
      _webSocketChannel = null;
    }
  }
  
  /// Hủy các timer
  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    _longPollingTimer?.cancel();
    _longPollingTimer = null;
    
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    
    _pingPongTimer?.cancel();
    _pingPongTimer = null;
    
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }
  
  /// Khởi động timer kiểm tra kết nối
  void _startConnectionChecker() {
    // Hủy timer hiện tại nếu có
    _connectionCheckTimer?.cancel();
    
    // Tạo timer mới để kiểm tra kết nối định kỳ
    _connectionCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkConnection(),
    );
  }
  
  /// Kiểm tra kết nối
  Future<void> _checkConnection() async {
    if (!isConnected) return;
    
    // Kiểm tra độ trễ
    final latency = await checkLatency();
    
    // Nếu không đo được độ trễ, thử kết nối lại
    if (latency == null) {
      debugPrint('Connection check failed, trying to reconnect');
      _tryReconnect();
    }
  }
  
  /// Xử lý thay đổi kết nối
  void _handleConnectivityChange(List<ConnectionType> connectionTypes) {
    final hasConnection = connectionTypes.isNotEmpty && 
                        !connectionTypes.contains(ConnectionType.none);
    
    if (hasConnection) {
      // Có kết nối mạng, thử kết nối lại nếu cần
      if (_connectionState == RealtimeConnectionState.error && _autoReconnect) {
        debugPrint('Network connection restored, trying to reconnect');
        _reconnectAttempts = 0;
        connect();
      }
    } else {
      // Không có kết nối mạng, cập nhật trạng thái
      if (_connectionState == RealtimeConnectionState.connected) {
        debugPrint('Network connection lost');
        _updateConnectionState(RealtimeConnectionState.error);
      }
    }
  }
  
  /// Xử lý tin nhắn từ WebSocket
  void _processWebSocketMessage(dynamic data) {
    try {
      if (data is String) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final message = RealtimeMessage.fromJson(json);
        
        // Xử lý ping/pong
        if (message.type == 'pong') {
          _handlePong();
          return;
        } else if (message.type == 'latency_pong') {
          _handleLatencyPong(message);
          return;
        }
        
        // Xử lý tin nhắn thông thường
        _handleMessage(message);
      }
    } catch (e) {
      debugPrint('Error processing WebSocket message: $e');
    }
  }
  
  /// Xử lý tin nhắn
  void _handleMessage(RealtimeMessage message) {
    _messageController.add(message);
    _metrics.recordMessageReceived();
  }
  
  /// Xử lý pong
  void _handlePong() {
    _lastPongReceived = DateTime.now();
  }
  
  /// Xử lý latency pong
  void _handleLatencyPong(RealtimeMessage message) {
    if (_latencyPingSentTime != null && _latencyCompleter != null && !_latencyCompleter!.isCompleted) {
      // Tính toán độ trễ
      final now = DateTime.now();
      final latency = now.difference(_latencyPingSentTime!).inMilliseconds;
      
      _lastMeasuredLatency = latency;
      _latencyCompleter!.complete(latency);
      
      _latencyPingSentTime = null;
      _latencyCompleter = null;
    }
  }
  
  /// Tạo URL WebSocket
  String _buildWebSocketUrl() {
    final uri = Uri.parse(_config.webSocketUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    // Thêm thông tin session
    queryParams['session_id'] = _sessionId ?? '';
    queryParams['client'] = 'flutter';
    queryParams['version'] = '1.0.0';
    queryParams['platform'] = defaultTargetPlatform.toString();
    
    // Tạo URI mới với query parameters
    final newUri = uri.replace(queryParameters: queryParams);
    
    // Thêm token vào URL
    return newUri.toString() + '&token=${_config.authToken}';
  }
  
  /// Khởi động timer keep-alive
  void _startKeepAliveTimer() {
    // Hủy timer hiện tại nếu có
    _keepAliveTimer?.cancel();
    _pingPongTimer?.cancel();
    
    // Thiết lập thời gian ban đầu
    _lastPingSent = DateTime.now();
    _lastPongReceived = DateTime.now();
    
    // Tạo timer mới
    _keepAliveTimer = Timer.periodic(
      Duration(milliseconds: _config.pingInterval),
      (_) => _sendPing(),
    );
  }
  
  /// Gửi ping
  void _sendPing() {
    if (_connectionType != RealtimeConnectionType.webSocket || 
        _connectionState != RealtimeConnectionState.connected) return;
    
    try {
      // Gửi ping
      _webSocketChannel?.sink.add(jsonEncode({
        'type': 'ping',
        'id': 'ping_${DateTime.now().millisecondsSinceEpoch}',
      }));
      
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
    _pingPongTimer = Timer(Duration(milliseconds: _config.pingTimeout), () {
      if (_lastPingSent != null && _lastPongReceived != null) {
        final pingDuration = DateTime.now().difference(_lastPingSent!).inMilliseconds;
        final pongAge = DateTime.now().difference(_lastPongReceived!).inMilliseconds;
        
        // Nếu quá thời gian timeout, thử kết nối lại
        if (pingDuration > _config.pingTimeout && pongAge > _config.pingTimeout) {
          debugPrint('Ping/Pong timeout: reconnecting...');
          _tryReconnect();
        }
      }
    });
  }
  
  /// Xử lý tin nhắn đang chờ
  Future<void> _processPendingMessages() async {
    if (_pendingMessages.isEmpty || !isConnected) return;
    
    final messagesToSend = List<_PendingMessage>.from(_pendingMessages);
    _pendingMessages.clear();
    
    debugPrint('Processing ${messagesToSend.length} pending messages');
    
    for (final pendingMsg in messagesToSend) {
      try {
        final success = await sendMessage(
          pendingMsg.type,
          pendingMsg.data,
          metadata: pendingMsg.metadata,
        );
        
        if (!success) {
          // Thêm lại vào hàng đợi nếu không thành công
          pendingMsg.retryCount++;
          
          // Chỉ thêm lại nếu số lần thử chưa quá giới hạn
          if (pendingMsg.retryCount < 3) {
            _pendingMessages.add(pendingMsg);
          } else {
            debugPrint('Dropping message after ${pendingMsg.retryCount} retries: ${pendingMsg.type}');
          }
        }
      } catch (e) {
        debugPrint('Error processing pending message: $e');
      }
      
      // Đợi một chút giữa các tin nhắn để tránh quá tải
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  
  /// Cập nhật trạng thái kết nối
  void _updateConnectionState(RealtimeConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }
  
  /// Cập nhật loại kết nối
  void _updateConnectionType(RealtimeConnectionType type) {
    if (_connectionType != type) {
      _connectionType = type;
      _connectionTypeController.add(type);
    }
  }
  
  /// Xử lý lỗi
  void _handleError(RealtimeError error) {
    // Log lỗi
    error.log();
    
    // Cập nhật metrics
    _metrics.recordError(error.type.toString());
    
    // Gửi lỗi qua stream
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
    
    // Xử lý lỗi cụ thể
    switch (error.type) {
      case RealtimeErrorType.networkError:
        // Thử kết nối lại nếu lỗi mạng
        if (_autoReconnect && _connectionState != RealtimeConnectionState.reconnecting) {
          _tryReconnect();
        }
        break;
        
      case RealtimeErrorType.timeout:
        // Xử lý timeout, có thể thử lại
        if (_autoReconnect && _connectionState != RealtimeConnectionState.reconnecting) {
          _tryReconnect();
        }
        break;
        
      case RealtimeErrorType.authError:
        // Đặt trạng thái lỗi và ngừng kết nối
        _updateConnectionState(RealtimeConnectionState.error);
        break;
        
      case RealtimeErrorType.rateLimitExceeded:
        // Không làm gì, đã xử lý ở nơi gọi
        break;
        
      case RealtimeErrorType.webSocketError:
        // Thử lại hoặc chuyển sang long polling
        if (_autoReconnect && _connectionState != RealtimeConnectionState.reconnecting) {
          _tryReconnect();
        }
        break;
        
      default:
        // Xử lý mặc định cho các lỗi khác
        if (_autoReconnect && 
            _connectionState != RealtimeConnectionState.reconnecting &&
            _connectionState != RealtimeConnectionState.error) {
          _tryReconnect();
        }
        break;
    }
  }
  
  /// Kiểm tra rate limit
  bool _checkRateLimit() {
    // Nếu không có message nào thì luôn cho phép
    if (_messageTimestamps.isEmpty) {
      return true;
    }
    
    // Xóa các timestamps cũ (hơn 1 phút)
    final now = DateTime.now();
    final threshold = now.subtract(const Duration(minutes: 1));
    
    _messageTimestamps.removeWhere((timestamp) => timestamp.isBefore(threshold));
    
    // Kiểm tra số lượng tin nhắn trong 1 phút
    if (_messageTimestamps.length >= _config.messageRateLimit) {
      debugPrint('Rate limit exceeded: ${_messageTimestamps.length} messages in the last minute');
      return false;
    }
    
    return true;
  }
  
  /// Kiểm tra rate limit từ headers của HTTP response
  void _checkRateLimitFromHeaders(dynamic response) {
    if (response != null && response is Response) {
      final headers = response.headers.map;
      
      if (headers.containsKey('x-ratelimit-limit') || 
          headers.containsKey('x-ratelimit-used') ||
          headers.containsKey('retry-after')) {
        _rateLimitInfo = RateLimitInfo.fromHeaders(headers);
        
        // Log thông tin rate limit
        debugPrint('Rate limit info: $_rateLimitInfo');
      }
    }
  }
} 