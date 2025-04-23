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

/// Cấu hình kết nối thời gian thực
class RealtimeConfig {
  final Duration connectTimeout;
  final Duration pingInterval;
  final Duration pongTimeout;
  final int maxReconnectAttempts;
  final int baseReconnectDelayMs;
  final int maxReconnectDelayMs;
  final bool useMessageAcknowledgement;
  final int maxQueueSize;
  final int queueBatchSize;
  final int queueProcessInterval;
  final int defaultRateLimitRetry;
  final int maxMessagesPerSecond;

  const RealtimeConfig({
    this.connectTimeout = const Duration(seconds: 10),
    this.pingInterval = const Duration(seconds: 30),
    this.pongTimeout = const Duration(seconds: 10),
    this.maxReconnectAttempts = 10,
    this.baseReconnectDelayMs = 1000,
    this.maxReconnectDelayMs = 30000,
    this.useMessageAcknowledgement = true,
    this.maxQueueSize = 100,
    this.queueBatchSize = 10,
    this.queueProcessInterval = 500,
    this.defaultRateLimitRetry = 5000,
    this.maxMessagesPerSecond = 20,
  });
}

/// Metrics cho kết nối thời gian thực
class RealtimeMetrics {
  int messagesReceived = 0;
  int messagesSent = 0;
  int reconnectAttempts = 0;
  int parseErrors = 0;
  int messageErrors = 0;
  int queueOverflows = 0;
  int messagesQueued = 0;
  
  List<int> processingTimes = [];
  final _analytics;

  RealtimeMetrics(this._analytics);

  void recordMessageReceived(int processingTimeMs) {
    messagesReceived++;
    processingTimes.add(processingTimeMs);
    if (processingTimes.length > 100) {
      processingTimes.removeAt(0);
    }
  }

  void recordMessageSent() {
    messagesSent++;
  }

  void recordReconnectAttempt() {
    reconnectAttempts++;
    _analytics?.logEvent('websocket_reconnect_attempt', {'count': reconnectAttempts});
  }

  void recordMessageParseError() {
    parseErrors++;
    _analytics?.logEvent('websocket_parse_error', {'count': parseErrors});
  }

  void recordMessageError() {
    messageErrors++;
    _analytics?.logEvent('websocket_message_error', {'count': messageErrors});
  }

  void recordQueueOverflow() {
    queueOverflows++;
    _analytics?.logEvent('websocket_queue_overflow', {'count': queueOverflows});
  }

  void recordMessageQueued() {
    messagesQueued++;
  }
  
  double get averageProcessingTime {
    if (processingTimes.isEmpty) return 0.0;
    final sum = processingTimes.reduce((a, b) => a + b);
    return sum / processingTimes.length;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'messagesReceived': messagesReceived,
      'messagesSent': messagesSent,
      'reconnectAttempts': reconnectAttempts,
      'parseErrors': parseErrors,
      'messageErrors': messageErrors,
      'queueOverflows': queueOverflows,
      'messagesQueued': messagesQueued,
      'averageProcessingTime': averageProcessingTime,
    };
  }
}

/// Thông tin về rate limit
class _RateLimitInfo {
  final DateTime limitedUntil;
  final int retryAfter;

  _RateLimitInfo({
    required this.limitedUntil,
    required this.retryAfter,
  });
  
  bool get isActive => DateTime.now().isBefore(limitedUntil);
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
  
  /// Cấu hình kết nối thời gian thực
  final RealtimeConfig _realtimeConfig;
  
  /// Metrics cho kết nối thời gian thực
  final RealtimeMetrics _realtimeMetrics;
  
  /// Queue để lưu trữ tin nhắn
  final Queue<Map<String, dynamic>> _messageQueue = Queue();
  
  /// Timer để xử lý queue
  Timer? _queueTimer;
  
  /// Lưu trữ thời gian nhận tin nhắn để kiểm soát tốc độ
  final List<DateTime> _messageTimes = [];
  
  /// Constructor
  @factoryMethod
  RealtimeConnectionService(
    this._httpClient,
    this._connectivityService,
    @Named('realtimeConfig') this._config,
    this._realtimeConfig,
    this._realtimeMetrics,
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
      // Thử kết nối WebSocket với timeout
      final connectTask = _connectWebSocket();
      final timeoutTask = Future.delayed(Duration(milliseconds: _config.connectionTimeout), () => false);
      
      // Chọn kết quả từ task hoàn thành trước
      final success = await Future.any([connectTask, timeoutTask]);
      
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
  
  @override
  Future<bool> reconnect() async {
    // Xóa bỏ các timer hiện tại
    _cancelTimers();
    
    // Đảm bảo trạng thái phù hợp
    _updateConnectionState(RealtimeConnectionState.reconnecting);
    
    // Đặt lại số lần thử 
    _reconnectAttempts = 0;
    
    // Đóng kết nối hiện tại nếu cần
    if (_connectionType != RealtimeConnectionType.none) {
      await _closeWebSocket();
      _updateConnectionType(RealtimeConnectionType.none);
    }
    
    // Thử kết nối lại
    return await connect();
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
    
    // Tính thời gian đợi với jitter để tránh thundering herd
    final delay = _calculateReconnectDelay();
    debugPrint('Reconnecting in $delay ms (attempt $_reconnectAttempts of ${_config.maxReconnectAttempts})');
    
    // Thiết lập timer
    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      _reconnectTimer = null;
      
      // Kiểm tra kết nối mạng trước khi thử
      final hasNetwork = await _connectivityService.isConnected();
      if (!hasNetwork) {
        debugPrint('Cannot reconnect: no network connection');
        
        // Thử lại sau với khoảng thời gian lâu hơn
        _updateConnectionState(RealtimeConnectionState.error);
        
        if (_autoReconnect && _reconnectAttempts < _config.maxReconnectAttempts) {
          final nextDelay = _calculateReconnectDelay() * 2; // Đợi lâu hơn khi không có mạng
          _reconnectTimer = Timer(Duration(milliseconds: nextDelay), () {
            _reconnectTimer = null;
            _tryReconnect();
          });
        }
        return;
      }
      
      // Thử kết nối WebSocket
      bool success = false;
      
      try {
        success = await _connectWebSocket();
      } catch (e) {
        debugPrint('Error during WebSocket reconnect: $e');
        success = false;
      }
      
      // Nếu không thành công, thử long polling
      if (!success && _connectionType != RealtimeConnectionType.longPolling) {
        try {
          success = await _startLongPolling();
        } catch (e) {
          debugPrint('Error during long polling fallback: $e');
          success = false;
        }
      }
      
      // Xử lý tin nhắn đang chờ
      if (isConnected && _pendingMessages.isNotEmpty) {
        _processPendingMessages();
      }
      
      // Nếu vẫn không thành công, thử lại
      if (!success && _autoReconnect) {
        _tryReconnect();
      }
    });
  }
  
  /// Tính thời gian đợi giữa các lần thử kết nối
  int _calculateReconnectDelay() {
    final baseDelay = _config.initialReconnectDelay;
    final factor = _config.reconnectBackoffFactor;
    
    // Tăng theo hàm mũ với một chút nhiễu ngẫu nhiên để tránh thundering herd
    final exponentialDelay = baseDelay * pow(factor, _reconnectAttempts - 1);
    
    // Thêm jitter ±30%
    final jitterFactor = 0.7 + (Random().nextDouble() * 0.6); // 0.7-1.3
    final jitteredDelay = exponentialDelay * jitterFactor;
    
    // Giới hạn tối đa là 2 phút
    return min(jitteredDelay.toInt(), 120000);
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
  void _handleMessage(dynamic data) {
    try {
      if (data == null) {
        return;
      }
      
      // Đo thời gian xử lý
      final stopwatch = Stopwatch()..start();
      
      // Chuyển đổi dữ liệu thành JSON
      Map<String, dynamic> jsonData;
      if (data is String) {
        try {
          jsonData = json.decode(data);
        } catch (e) {
          debugPrint('Error decoding WebSocket message: $e');
          _metrics.recordMessageParseError();
          return;
        }
      } else if (data is Map<String, dynamic>) {
        jsonData = data;
      } else {
        debugPrint('Unknown WebSocket message format: ${data.runtimeType}');
        _metrics.recordMessageParseError();
        return;
      }

      // Kiểm tra rate limit
      if (_checkRateLimit()) {
        // Parse tin nhắn
        final message = RealtimeMessage.fromJson(jsonData);
        
        // Đánh dấu đã nhận
        _acknowledgeMessage(message.id);
        
        // Gửi sự kiện tin nhắn
        _messageController.add(message);
        
        // Cập nhật metrics
        final processingTime = stopwatch.elapsedMilliseconds;
        _metrics.recordMessageReceived(processingTime);
        
        if (processingTime > 100) {
          debugPrint('Warning: Message processing took $processingTime ms');
        }
      } else {
        _queueMessage(jsonData);
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling WebSocket message: $e');
      _errorController.add(RealtimeError.fromException(e, type: RealtimeErrorType.messageError));
      _metrics.recordMessageError();
    }
  }
  
  /// Đánh dấu tin nhắn đã nhận nếu cần
  void _acknowledgeMessage(String messageId) {
    if (_config.useMessageAcknowledgement && messageId.isNotEmpty) {
      try {
        final ackMessage = {
          'type': 'ack',
          'messageId': messageId,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        };
        _sendRaw(json.encode(ackMessage));
      } catch (e) {
        debugPrint('Error acknowledging message: $e');
      }
    }
  }
  
  /// Xếp hàng đợi tin nhắn khi rate limited
  void _queueMessage(Map<String, dynamic> message) {
    if (_pendingMessages.length >= _config.maxConnectionPoolSize) {
      // Xóa tin nhắn cũ nhất nếu hàng đợi đầy
      _pendingMessages.removeAt(0);
      _metrics.recordQueueOverflow();
    }
    
    _pendingMessages.add(_PendingMessage(message['type'], message['data'], metadata: message['metadata']));
    _metrics.recordMessageQueued();
    
    // Đặt lịch xử lý hàng đợi nếu chưa có
    if (_connectionCheckTimer == null) {
      final delay = _rateLimitInfo?.retryAfter ?? _config.rateLimitBackoffMs;
      _connectionCheckTimer = Timer(Duration(milliseconds: delay), _processMessageQueue);
    }
  }
  
  /// Xử lý hàng đợi tin nhắn
  void _processMessageQueue() {
    _connectionCheckTimer = null;
    
    if (_pendingMessages.isEmpty || !isConnected) {
      return;
    }
    
    // Xử lý một số tin nhắn trong hàng đợi
    final batchSize = min(_pendingMessages.length, _config.maxConnectionPoolSize);
    for (var i = 0; i < batchSize; i++) {
      if (_checkRateLimit()) {
        break;
      }
      
      final pendingMsg = _pendingMessages.removeAt(0);
      _handleMessage(pendingMsg.data);
    }
    
    // Nếu vẫn còn tin nhắn, đặt lịch xử lý tiếp
    if (_pendingMessages.isNotEmpty && _connectionCheckTimer == null) {
      _connectionCheckTimer = Timer(Duration(milliseconds: _config.rateLimitBackoffMs), _processMessageQueue);
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
  
  /// Kiểm tra xem có đang bị rate limit không
  bool _isRateLimited() {
    // Kiểm tra nếu đã có thông tin rate limit và vẫn còn hiệu lực
    if (_rateLimitInfo != null && _rateLimitInfo!.isActive) {
      return true;
    }
    
    // Kiểm tra tốc độ tin nhắn hiện tại
    final now = DateTime.now();
    final oneSecondAgo = now.subtract(const Duration(seconds: 1));
    
    // Đếm số tin nhắn trong giây vừa qua
    final recentMessages = _messageTimestamps.where((time) => time.isAfter(oneSecondAgo)).length;
    
    if (recentMessages >= _config.maxMessagesPerSecond) {
      // Tạo rate limit mới
      _rateLimitInfo = _RateLimitInfo(
        limitedUntil: now.add(const Duration(seconds: 1)),
        retryAfter: 1000,
      );
      return true;
    }
    
    return false;
  }
  
  /// Cập nhật thời gian tin nhắn
  void _updateMessageTimes() {
    final now = DateTime.now();
    _messageTimestamps.add(now);
    
    // Giữ danh sách thời gian trong khoảng 5 giây gần đây
    _messageTimestamps.removeWhere((time) => 
      now.difference(time).inSeconds > 5
    );
  }

  /// Tạo một WebSocket mới với logic thử lại
  Future<void> _createNewSocket() async {
    if (_isReconnecting) {
      return;
    }

    _isReconnecting = true;
    int attempts = 0;
    
    while (attempts < _config.maxReconnectAttempts) {
      try {
        // Tạo chuỗi kết nối WebSocket
        final uri = _buildSocketUri();
        if (uri == null) {
          _logger.severe('Invalid WebSocket URI');
          break;
        }

        // Bắt đầu theo dõi thời gian kết nối
        final connectionStartTime = DateTime.now().millisecondsSinceEpoch;
        
        // Thử kết nối WebSocket với timeout
        _socket = await WebSocket.connect(
          uri.toString(),
          headers: await _getAuthHeaders(),
        ).timeout(Duration(milliseconds: _config.connectTimeout));
        
        // Ghi nhận thời gian kết nối
        final connectionTime = DateTime.now().millisecondsSinceEpoch - connectionStartTime;
        _metrics.recordConnectionTime(connectionTime);
        
        // Cấu hình WebSocket listeners
        _socket!.listen(
          _handleWebSocketMessage,
          onError: _handleWebSocketError,
          onDone: _handleWebSocketDone,
        );
        
        // Khởi tạo ping timer
        _startPingTimer();
        
        // Cập nhật trạng thái
        _setConnectionState(RealtimeConnectionState.connected);
        _isReconnecting = false;
        _reconnectAttempts = 0;
        
        _logger.info('WebSocket connection established');
        return;
      } catch (e) {
        attempts++;
        _reconnectAttempts++;
        _metrics.recordReconnectAttempt();
        
        _logger.warning(
          'WebSocket connection attempt $attempts failed: $e. '
          'Retrying in ${_getBackoffDuration(attempts)}ms',
        );
        
        await Future.delayed(Duration(milliseconds: _getBackoffDuration(attempts)));
      }
    }
    
    // Nếu đã vượt quá số lần thử lại tối đa
    _isReconnecting = false;
    _setConnectionState(RealtimeConnectionState.disconnected);
    _logger.severe('Failed to establish WebSocket connection after $attempts attempts');
  }
  
  /// Tính toán thời gian chờ dựa trên exponential backoff
  int _getBackoffDuration(int attempt) {
    final baseDelay = _config.reconnectBaseDelay;
    final maxDelay = _config.reconnectMaxDelay;
    final jitter = Random().nextInt(_config.reconnectJitter);
    
    // Tính toán backoff với công thức: min(maxDelay, baseDelay * 2^attempt) + jitter
    final delay = min(maxDelay, baseDelay * pow(2, min(attempt, 6)).toInt()) + jitter;
    return delay;
  }
  
  /// Khởi tạo URI WebSocket với các tham số cần thiết
  Uri? _buildSocketUri() {
    try {
      final baseUrl = _config.wsEndpoint;
      if (baseUrl.isEmpty) {
        _logger.severe('WebSocket endpoint is not configured');
        return null;
      }
      
      // Thêm các tham số truy vấn vào URI
      final queryParams = <String, dynamic>{
        'client': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web',
        'v': _config.protocolVersion,
        'device_id': _deviceId,
      };
      
      if (_userId != null && _userId!.isNotEmpty) {
        queryParams['user_id'] = _userId;
      }
      
      // Xây dựng URI
      return Uri.parse(baseUrl).replace(queryParameters: queryParams);
    } catch (e) {
      _logger.severe('Failed to build WebSocket URI: $e');
      return null;
    }
  }
  
  /// Bắt đầu timer để gửi tin nhắn ping định kỳ
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      Duration(milliseconds: _config.pingInterval),
      (_) => _sendPing(),
    );
  }
  
  /// Gửi tin nhắn ping để kiểm tra kết nối
  void _sendPing() {
    if (_connectionState != RealtimeConnectionState.connected || _socket == null) {
      return;
    }
    
    try {
      final ping = {
        'type': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _socket!.add(jsonEncode(ping));
      _metrics.recordMessageSent();
    } catch (e) {
      _logger.warning('Failed to send ping: $e');
    }
  }
  
  /// Lấy header xác thực cho kết nối WebSocket
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{};
    
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      _logger.warning('Failed to get auth token: $e');
    }
    
    return headers;
  }
} 