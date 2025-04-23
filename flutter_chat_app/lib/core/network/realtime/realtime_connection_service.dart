import 'dart:async';
import 'dart:collection';
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
  final Queue<Map<String, dynamic>> _messageQueue = Queue<Map<String, dynamic>>();
  
  /// Timer để xử lý queue
  Timer? _queueTimer;
  
  /// Lưu trữ thời gian nhận tin nhắn để kiểm soát tốc độ
  final List<DateTime> _messageTimes = [];
  
  /// Track last connection attempt time
  DateTime? _lastConnectionAttemptTime;
  
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
    // Nếu đã kết nối, không làm gì
    if (_connectionState == RealtimeConnectionState.connected ||
        _connectionState == RealtimeConnectionState.connecting) {
      debugPrint('Already connected or connecting');
      return true;
    }
    
    // Cập nhật trạng thái kết nối
    _updateConnectionState(RealtimeConnectionState.connecting);
    
    // Ghi nhận sự kiện bắt đầu kết nối
    _metrics.recordConnectionStart();
    _lastConnectionAttemptTime = DateTime.now();
    
    // Đặt lại số lần thử kết nối và lỗi
    _reconnectAttempts = 0;
    
    // Hủy bỏ timers nếu có
    _cancelTimers();
    
    // Khởi tạo session ID mới nếu chưa có
    _sessionId ??= _generateSessionId();
    
    try {
      // Thử kết nối WebSocket với timeout
      final connectTask = _connectWebSocket();
      
      // Đặt timeout cho kết nối
      final result = await connectTask.timeout(
        Duration(milliseconds: _config.connectionTimeout),
        onTimeout: () {
          debugPrint('WebSocket connection timed out');
          // Nếu thất bại, thử long polling (nếu được hỗ trợ)
          if (_httpClient != null) {
            debugPrint('WebSocket connection failed, falling back to long polling');
            return _startLongPolling();
          }
          return false;
        },
      );
      
      return result;
    } catch (e) {
      final error = RealtimeError.fromException(e, type: RealtimeErrorType.networkError);
      _handleError(error);
      
      // Ghi nhận kết nối thất bại
      _metrics.recordConnectionFailure();
      
      // Đặt trạng thái kết nối về disconnected
      _updateConnectionState(RealtimeConnectionState.disconnected);
      
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
    final hasConnection = connectionTypes.isNotEmpty && !connectionTypes.contains(ConnectionType.none);
    
    if (hasConnection) {
      // Có kết nối mạng, thử kết nối lại nếu đang trong trạng thái lỗi hoặc ngắt kết nối
      if (_connectionState == RealtimeConnectionState.error || 
          _connectionState == RealtimeConnectionState.disconnected || 
          _connectionState == RealtimeConnectionState.closed) {
        
        if (_autoReconnect) {
          debugPrint('Network connection restored, attempting to reconnect');
          _reconnectAttempts = 0;
          
          // Ghi nhận sự kiện khôi phục kết nối vào metrics
          _metrics.recordConnectionStart();
          
          // Đặt trạng thái kết nối về reconnecting trước khi kết nối lại
          _updateConnectionState(RealtimeConnectionState.reconnecting);
          
          // Thử kết nối lại
          connect();
        }
      }
    } else {
      // Không có kết nối mạng, cập nhật trạng thái
      if (_connectionState == RealtimeConnectionState.connected || 
          _connectionState == RealtimeConnectionState.connecting) {
        debugPrint('Network connection lost');
        
        // Ghi nhận sự kiện mất kết nối vào metrics
        _metrics.recordDisconnect();
        
        // Hủy WebSocket hiện tại nếu có
        _closeWebSocket();
        
        // Cập nhật trạng thái
        _updateConnectionState(RealtimeConnectionState.disconnected);
        
        // Thông báo lỗi
        final error = RealtimeError(
          code: 'NETWORK_DISCONNECTED',
          message: 'Network connection lost',
          type: RealtimeErrorType.networkError,
        );
        _errorController.add(error);
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
          _metrics.recordError('parse_error');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        jsonData = data;
      } else {
        debugPrint('Unknown WebSocket message format: ${data.runtimeType}');
        _metrics.recordError('parse_error');
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
        _metrics.recordMessageReceived();
        
        if (processingTime > 100) {
          debugPrint('Warning: Message processing took $processingTime ms');
        }
      } else {
        _queueMessage(jsonData);
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling WebSocket message: $e');
      _errorController.add(RealtimeError.fromException(e, type: RealtimeErrorType.messageFormatError));
      _metrics.recordError('message_error');
    }
  }
  
  /// Đánh dấu tin nhắn đã nhận nếu cần
  void _acknowledgeMessage(String messageId) {
    if (_realtimeConfig.useMessageAcknowledgement && messageId.isNotEmpty) {
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
    if (_pendingMessages.length >= _realtimeConfig.maxQueueSize) {
      // Xóa tin nhắn cũ nhất nếu hàng đợi đầy
      _pendingMessages.removeAt(0);
      _realtimeMetrics.recordQueueOverflow();
    }
    
    _pendingMessages.add(_PendingMessage(message['type'], message['data'], metadata: message['metadata']));
    _realtimeMetrics.recordMessageQueued();
    
    // Đặt lịch xử lý hàng đợi nếu chưa có
    if (_connectionCheckTimer == null) {
      final delay = _rateLimitInfo?.retryAfterMs ?? _config.rateLimitBackoffMs;
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
    if (_rateLimitInfo != null && _rateLimitInfo!.remaining <= 0) {
      return true;
    }
    
    // Kiểm tra tốc độ tin nhắn hiện tại
    final now = DateTime.now();
    final oneSecondAgo = now.subtract(const Duration(seconds: 1));
    
    // Đếm số tin nhắn trong giây vừa qua
    final recentMessages = _messageTimestamps.where((time) => time.isAfter(oneSecondAgo)).length;
    
    if (recentMessages >= _realtimeConfig.maxMessagesPerSecond) {
      // Tạo rate limit mới
      _rateLimitInfo = RateLimitInfo(
        limit: _realtimeConfig.maxMessagesPerSecond,
        used: recentMessages,
        resetTimestamp: now.add(const Duration(seconds: 1)).millisecondsSinceEpoch ~/ 1000,
        retryAfterMs: 1000,
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
  Future<bool> _connectWebSocket() async {
    if (_connectionState == RealtimeConnectionState.connecting || 
        _connectionState == RealtimeConnectionState.reconnecting) {
      return false;
    }

    try {
      // Cập nhật thời gian thử kết nối mới nhất
      _lastConnectionAttemptTime = DateTime.now();
      
      // Khởi tạo WebSocket
      final wsUrl = Uri.parse('${_config.webSocketUrl}?token=${_config.authToken}&sessionId=$_sessionId');
      _webSocketChannel = WebSocketChannel.connect(wsUrl);
      
      // Khởi động timer để theo dõi kết nối
      _lastPingSent = DateTime.now();
      _startKeepAliveTimer();
      
      // Đăng ký lắng nghe WebSocket
      _webSocketSubscription = _webSocketChannel?.stream.listen(
        _handleMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );
      
      _updateConnectionType(RealtimeConnectionType.webSocket);
      _updateConnectionState(RealtimeConnectionState.connected);
      
      debugPrint('Connected to WebSocket: ${_config.webSocketUrl}');
      _metrics.recordConnectionSuccess();
      
      return true;
    } catch (e) {
      final error = RealtimeError.fromException(e, type: RealtimeErrorType.webSocketError);
      _handleError(error);
      return false;
    }
  }

  /// Xử lý lỗi WebSocket
  void _handleWebSocketError(dynamic error) {
    // Đo thời gian đến khi có lỗi
    final connectionTime = _lastConnectionAttemptTime != null 
        ? DateTime.now().difference(_lastConnectionAttemptTime!).inMilliseconds 
        : null;
    
    final realtimeError = RealtimeError.fromException(
      error,
      type: RealtimeErrorType.webSocketError
    );
    
    debugPrint('WebSocket error: ${realtimeError.message}');
    
    // Ghi nhận lỗi vào metrics
    _metrics.recordError(realtimeError.type.toString());
    if (connectionTime != null) {
      _metrics.recordConnectionFailure();
    }
    
    // Gửi lỗi qua stream
    if (!_errorController.isClosed) {
      _errorController.add(realtimeError);
    }
    
    // Hủy kết nối WebSocket hiện tại
    _closeWebSocket();
    
    // Cập nhật trạng thái
    _updateConnectionState(RealtimeConnectionState.error);
    
    // Thử kết nối lại nếu được cấu hình và không đang trong quá trình kết nối lại
    if (_autoReconnect && _connectionState != RealtimeConnectionState.reconnecting) {
      _tryReconnect();
    }
  }
  
  /// Xử lý khi WebSocket đóng kết nối
  void _handleWebSocketDone() {
    debugPrint('WebSocket connection closed');
    
    // Kiểm tra xem đây có phải là ngắt kết nối do người dùng không
    final isUserInitiated = _connectionState == RealtimeConnectionState.connecting;
    
    // Nếu đang trong trạng thái connected, cập nhật trạng thái
    if (_connectionState == RealtimeConnectionState.connected) {
      // Ghi nhận vào metrics
      _metrics.recordDisconnect();
      
      // Cập nhật trạng thái
      _updateConnectionState(RealtimeConnectionState.closed);
      
      // Hủy timer
      _cancelTimers();
      
      // Hủy WebSocket channel nếu còn
      _closeWebSocket();
      
      // Thử kết nối lại nếu được cấu hình và không phải người dùng chủ động ngắt kết nối
      if (_autoReconnect && !isUserInitiated) {
        // Đặt trạng thái kết nối về reconnecting trước khi kết nối lại
        _updateConnectionState(RealtimeConnectionState.reconnecting);
        _tryReconnect();
      }
    } else if (isUserInitiated) {
      // Nếu là ngắt kết nối do người dùng, cập nhật trạng thái thành disconnected
      _updateConnectionState(RealtimeConnectionState.disconnected);
      
      // Ghi nhận vào metrics
      _metrics.recordDisconnect();
    }
  }

  /// Bắt đầu long polling thay vì WebSocket
  Future<bool> _startLongPolling() async {
    try {
      debugPrint('Starting long polling connection');
      
      // Hủy các timer hiện tại nếu có
      _cancelTimers();
      
      // Cập nhật trạng thái và loại kết nối
      _updateConnectionType(RealtimeConnectionType.longPolling);
      _updateConnectionState(RealtimeConnectionState.connected);
      
      // Khởi tạo long polling timer
      _longPollingTimer = Timer.periodic(
        Duration(milliseconds: _config.longPollingInterval),
        (_) => _performLongPolling(),
      );
      
      // Khởi động timer kiểm tra kết nối
      _startConnectionChecker();
      
      _metrics.recordConnectionSuccess();
      return true;
    } catch (e) {
      final error = RealtimeError.fromException(e, type: RealtimeErrorType.networkError);
      _handleError(error);
      _metrics.recordConnectionFailure();
      return false;
    }
  }
  
  /// Thực hiện long polling
  Future<void> _performLongPolling() async {
    try {
      // Kiểm tra kết nối
      if (!isConnected || _connectionType != RealtimeConnectionType.longPolling) {
        return;
      }
      
      // Gửi request đến server
      final response = await _httpClient.get<Map<String, dynamic>>(
        '${_config.httpUrl}/poll',
        headers: {
          'Authorization': 'Bearer ${_config.authToken}',
          'X-Session-ID': _sessionId ?? '',
          'X-Last-Message-Id': _lastReceivedMessageId ?? '',
          ..._config.additionalHeaders ?? {},
        },
      );
      
      // Kiểm tra rate limit
      _checkRateLimitFromHeaders(response);
      
      // Xử lý các tin nhắn
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
      
      // Cập nhật thời gian pong
      _lastPongReceived = DateTime.now();
    } catch (e) {
      debugPrint('Long polling error: $e');
      
      final error = RealtimeError.fromException(e, type: RealtimeErrorType.networkError);
      _handleError(error);
    }
  }
  
  /// ID tin nhắn cuối cùng nhận được (dùng cho long polling)
  String? _lastReceivedMessageId;
  
  /// Xử lý các tin nhắn đang chờ
  void _processPendingMessages() async {
    if (_pendingMessages.isEmpty || !isConnected) {
      return;
    }
    
    debugPrint('Processing ${_pendingMessages.length} pending messages');
    
    // Tạo bản sao để tránh sửa đổi trong khi lặp
    final pendingMessagesCopy = List<_PendingMessage>.from(_pendingMessages);
    _pendingMessages.clear();
    
    // Xử lý từng tin nhắn
    for (final pendingMessage in pendingMessagesCopy) {
      // Dừng nếu đã mất kết nối
      if (!isConnected) {
        _pendingMessages.add(pendingMessage);
        return;
      }
      
      // Thử gửi tin nhắn
      final success = await sendMessage(
        pendingMessage.type,
        pendingMessage.data,
        metadata: pendingMessage.metadata,
      );
      
      // Nếu không thành công, thêm lại vào hàng đợi
      if (!success) {
        pendingMessage.retryCount++;
        
        // Kiểm tra số lần thử
        if (pendingMessage.retryCount < 3) {
          _pendingMessages.add(pendingMessage);
        } else {
          debugPrint('Dropped pending message after ${pendingMessage.retryCount} attempts: ${pendingMessage.type}');
        }
      }
      
      // Đợi một chút giữa mỗi lần gửi để tránh quá tải
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Khởi động timer để gửi ping
  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(
      Duration(milliseconds: _config.pingInterval),
      (_) => _sendPing(),
    );
    
    _pingPongTimer?.cancel();
  }
  
  /// Gửi ping để kiểm tra kết nối
  void _sendPing() {
    if (!isConnected || _webSocketChannel == null) {
      return;
    }
    
    try {
      final pingMessage = {
        'type': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _lastPingSent = DateTime.now();
      _webSocketChannel?.sink.add(jsonEncode(pingMessage));
      
      // Thiết lập timer theo dõi pong
      _pingPongTimer?.cancel();
      _pingPongTimer = Timer(Duration(milliseconds: _config.pingTimeout), _checkPingTimeout);
    } catch (e) {
      debugPrint('Error sending ping: $e');
    }
  }
  
  /// Kiểm tra timeout sau khi gửi ping
  void _checkPingTimeout() {
    // Nếu không nhận được pong sau khi gửi ping
    if (_lastPingSent != null && _lastPongReceived == null || 
        _lastPongReceived != null && _lastPongReceived!.isBefore(_lastPingSent!)) {
      debugPrint('Ping timeout detected');
      
      final error = RealtimeError(
        type: RealtimeErrorType.timeout,
        message: 'Ping timeout after ${_config.pingTimeout}ms',
      );
      _handleError(error);
      
      // Thử kết nối lại
      if (_autoReconnect) {
        _tryReconnect();
      }
    }
  }
  
  /// Gửi raw data qua WebSocket hoặc HTTP
  void _sendRaw(String rawData) {
    if (!isConnected) return;
    
    try {
      switch (_connectionType) {
        case RealtimeConnectionType.webSocket:
          _webSocketChannel?.sink.add(rawData);
          break;
          
        case RealtimeConnectionType.longPolling:
          // Không thực hiện gì
          break;
          
        case RealtimeConnectionType.none:
          // Không thực hiện gì
          break;
      }
    } catch (e) {
      debugPrint('Error sending raw data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    // Kiểm tra độ trễ
    final latency = await checkLatency();
    
    // Cập nhật thông tin thống kê
    final healthData = <String, dynamic>{
      'connection_state': _connectionState.toString(),
      'connection_type': _connectionType.toString(),
      'is_connected': isConnected,
      'latency_ms': latency,
      'reconnect_attempts': _reconnectAttempts,
      'uptime_percentage': _metrics.uptimePercentage,
      'messages': {
        'sent': _metrics.messagesSent,
        'received': _metrics.messagesReceived,
        'failed': _metrics.failedMessages,
      },
      'rate_limit': _rateLimitInfo != null 
          ? {
              'limit': _rateLimitInfo!.limit,
              'used': _rateLimitInfo!.used,
              'remaining': _rateLimitInfo!.remaining,
              'reset_timestamp': _rateLimitInfo!.resetTimestamp,
            }
          : null,
      'metrics': _metrics.toJson(),
    };
    
    return healthData;
  }

  /// Tạo một session ID ngẫu nhiên
  String _generateSessionId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
} 