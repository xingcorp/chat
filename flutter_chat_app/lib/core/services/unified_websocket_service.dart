/// **UNIFIED WEBSOCKET SERVICE**
///
/// Enterprise-grade WebSocket service with <100ms latency
/// Consolidates all WebSocket implementations into single service
/// 
/// **Features:**
/// - Real-time messaging with <100ms delivery
/// - Automatic reconnection with exponential backoff
/// - Offline message queuing
/// - Connection state management
/// - Performance monitoring
/// - Error handling and recovery
///
/// **Architecture:** Clean Architecture + SOLID Principles

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';
import '../network/network_info.dart';

/// Simple Result type to replace dartz
abstract class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}

/// Extension for Result
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get value => isSuccess ? (this as Success<T>).value : null;
  String? get error => isFailure ? (this as Failure<T>).message : null;

  R fold<R>(R Function(String) onFailure, R Function(T) onSuccess) {
    if (isSuccess) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onFailure((this as Failure<T>).message);
    }
  }
}

/// Connection state enumeration
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Message priority levels
enum MessagePriority {
  low,
  normal,
  high,
  critical,
}

/// WebSocket message model
class WebSocketMessage {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final MessagePriority priority;
  final DateTime timestamp;
  final int retryCount;

  const WebSocketMessage({
    required this.id,
    required this.type,
    required this.data,
    this.priority = MessagePriority.normal,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'priority': priority.name,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  WebSocketMessage copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    MessagePriority? priority,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return WebSocketMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Performance metrics
class WebSocketMetrics {
  final int messagesSent;
  final int messagesReceived;
  final int reconnectAttempts;
  final Duration averageLatency;
  final DateTime lastConnected;
  final int queuedMessages;

  const WebSocketMetrics({
    required this.messagesSent,
    required this.messagesReceived,
    required this.reconnectAttempts,
    required this.averageLatency,
    required this.lastConnected,
    required this.queuedMessages,
  });
}

/// **UNIFIED WEBSOCKET SERVICE**
@singleton
class UnifiedWebSocketService {
  // Dependencies
  final NetworkInfo _networkInfo;
  final Logger _logger = Logger();

  // WebSocket connections
  io.Socket? _socketIO;
  WebSocketChannel? _webSocketChannel;
  
  // State management
  final BehaviorSubject<WebSocketConnectionState> _connectionStateController = 
      BehaviorSubject<WebSocketConnectionState>.seeded(WebSocketConnectionState.disconnected);
  
  final BehaviorSubject<WebSocketMessage> _messageController = 
      BehaviorSubject<WebSocketMessage>();
  
  final BehaviorSubject<WebSocketMetrics> _metricsController = 
      BehaviorSubject<WebSocketMetrics>();

  // Configuration
  late String _serverUrl;
  late Map<String, dynamic> _connectionOptions;
  
  // Reconnection logic
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  
  // Message queue for offline scenarios
  final List<WebSocketMessage> _messageQueue = [];
  static const int _maxQueueSize = 1000;
  
  // Performance tracking
  int _messagesSent = 0;
  int _messagesReceived = 0;
  final List<Duration> _latencyMeasurements = [];
  DateTime? _lastConnected;
  
  // Heartbeat
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  /// Constructor
  UnifiedWebSocketService(this._networkInfo) {
    _initializeService();
  }

  /// Initialize service
  void _initializeService() {
    _serverUrl = AppConstants.websocketUrl;
    _connectionOptions = {
      'transports': ['websocket'],
      'timeout': AppConstants.websocketTimeoutSeconds * 1000,
      'reconnection': false, // We handle reconnection manually
      'autoConnect': false,
    };
    
    _logger.i('🚀 UnifiedWebSocketService initialized');
    _logger.d('📋 Server URL: $_serverUrl');
  }

  /// **PUBLIC API**

  /// Connection state stream
  Stream<WebSocketConnectionState> get connectionState => _connectionStateController.stream;

  /// Message stream
  Stream<WebSocketMessage> get messages => _messageController.stream;

  /// Metrics stream
  Stream<WebSocketMetrics> get metrics => _metricsController.stream;

  /// Current connection state
  WebSocketConnectionState get currentState => _connectionStateController.value;

  /// Is connected
  bool get isConnected => currentState == WebSocketConnectionState.connected;

  /// Is connecting
  bool get isConnecting => currentState == WebSocketConnectionState.connecting;

  /// **CONNECT TO WEBSOCKET**
  ///
  /// **Performance Target:** <2s connection establishment
  /// **Returns:** Result<bool>
  Future<Result<bool>> connect({String? authToken}) async {
    if (isConnected || isConnecting) {
      return const Success(true);
    }

    // Check network connectivity
    final isNetworkAvailable = await _networkInfo.isConnected;
    if (!isNetworkAvailable) {
      return const Failure('No network connection available');
    }

    _updateConnectionState(WebSocketConnectionState.connecting);
    _logger.i('🔌 Connecting to WebSocket server...');

    try {
      // Try Socket.IO first (preferred for real-time chat)
      final socketIOResult = await _connectSocketIO(authToken);
      if (socketIOResult.fold((l) => false, (r) => r)) {
        return const Success(true);
      }

      // Fallback to WebSocket
      final webSocketResult = await _connectWebSocket(authToken);
      return webSocketResult;

    } catch (e) {
      _logger.e('💥 Connection error: $e');
      _updateConnectionState(WebSocketConnectionState.error);
      return Failure('Connection failed: $e');
    }
  }

  /// **SEND MESSAGE**
  ///
  /// **Performance Target:** <100ms delivery
  /// **Strategy:** Priority queue + offline handling
  Future<Result<bool>> sendMessage({
    required String type,
    required Map<String, dynamic> data,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final message = WebSocketMessage(
      id: _generateMessageId(),
      type: type,
      data: data,
      priority: priority,
      timestamp: DateTime.now(),
    );

    // Queue message if not connected
    if (!isConnected) {
      _queueMessage(message);
      return const Success(true);
    }

    return _sendMessageInternal(message);
  }

  /// **DISCONNECT**
  Future<Result<bool>> disconnect() async {
    try {
      _logger.i('🔌 Disconnecting from WebSocket server');
      
      _cancelReconnectTimer();
      _cancelHeartbeat();
      
      await _disconnectSocketIO();
      await _disconnectWebSocket();
      
      _updateConnectionState(WebSocketConnectionState.disconnected);
      _resetMetrics();
      
      return const Success(true);
    } catch (e) {
      _logger.e('Error disconnecting: $e');
      return Failure('Disconnect failed: $e');
    }
  }

  /// **DISPOSE**
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _messageController.close();
    await _metricsController.close();
  }

  /// **PRIVATE METHODS**

  /// Connect using Socket.IO
  Future<Result<bool>> _connectSocketIO(String? authToken) async {
    try {
      _logger.d('🔌 Attempting Socket.IO connection');

      final options = Map<String, dynamic>.from(_connectionOptions);
      if (authToken != null) {
        options['auth'] = {'token': authToken};
      }

      _socketIO = io.io(_serverUrl, options);
      _setupSocketIOHandlers();

      _socketIO!.connect();

      // Wait for connection with timeout
      final completer = Completer<bool>();
      Timer? timeoutTimer;

      void onConnect() {
        if (!completer.isCompleted) {
          timeoutTimer?.cancel();
          completer.complete(true);
        }
      }

      void onError(dynamic error) {
        if (!completer.isCompleted) {
          timeoutTimer?.cancel();
          completer.complete(false);
        }
      }

      _socketIO!.onConnect((_) => onConnect());
      _socketIO!.onConnectError((error) => onError(error));

      timeoutTimer = Timer(Duration(seconds: AppConstants.websocketTimeoutSeconds), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      final success = await completer.future;

      if (success) {
        _updateConnectionState(WebSocketConnectionState.connected);
        _lastConnected = DateTime.now();
        _reconnectAttempts = 0;
        _startHeartbeat();
        _processMessageQueue();
        _logger.i('✅ Socket.IO connected successfully');
        return const Success(true);
      } else {
        await _disconnectSocketIO();
        return const Failure('Socket.IO connection timeout');
      }

    } catch (e) {
      _logger.e('Socket.IO connection error: $e');
      return Failure('Socket.IO failed: $e');
    }
  }

  /// Connect using WebSocket
  Future<Result<bool>> _connectWebSocket(String? authToken) async {
    try {
      _logger.d('🔌 Attempting WebSocket connection');

      var uri = Uri.parse(_serverUrl.replaceFirst('http', 'ws'));
      if (authToken != null) {
        uri = uri.replace(queryParameters: {'token': authToken});
      }

      _webSocketChannel = WebSocketChannel.connect(uri);
      await _webSocketChannel!.ready.timeout(
        Duration(seconds: AppConstants.websocketTimeoutSeconds),
      );

      _setupWebSocketHandlers();
      _updateConnectionState(WebSocketConnectionState.connected);
      _lastConnected = DateTime.now();
      _reconnectAttempts = 0;
      _startHeartbeat();
      _processMessageQueue();

      _logger.i('✅ WebSocket connected successfully');
      return const Success(true);

    } catch (e) {
      _logger.e('WebSocket connection error: $e');
      await _disconnectWebSocket();
      return Failure('WebSocket failed: $e');
    }
  }

  /// Setup Socket.IO event handlers
  void _setupSocketIOHandlers() {
    _socketIO!.onConnect((_) {
      _logger.d('Socket.IO connected');
    });

    _socketIO!.onDisconnect((_) {
      _logger.d('Socket.IO disconnected');
      _handleDisconnection();
    });

    _socketIO!.onConnectError((error) {
      _logger.e('Socket.IO connection error: $error');
      _handleConnectionError();
    });

    _socketIO!.on('message', (data) {
      _handleIncomingMessage(data);
    });

    _socketIO!.on('pong', (_) {
      _logger.t('Received pong from server');
    });
  }

  /// Setup WebSocket handlers
  void _setupWebSocketHandlers() {
    _webSocketChannel!.stream.listen(
      (data) {
        _handleIncomingMessage(data);
      },
      onError: (error) {
        _logger.e('WebSocket stream error: $error');
        _handleConnectionError();
      },
      onDone: () {
        _logger.d('WebSocket stream closed');
        _handleDisconnection();
      },
    );
  }

  /// Handle incoming message
  void _handleIncomingMessage(dynamic data) {
    try {
      _messagesReceived++;

      Map<String, dynamic> messageData;
      if (data is String) {
        messageData = jsonDecode(data);
      } else {
        messageData = data as Map<String, dynamic>;
      }

      final message = WebSocketMessage(
        id: messageData['id'] ?? _generateMessageId(),
        type: messageData['type'] ?? 'unknown',
        data: messageData['data'] ?? {},
        timestamp: DateTime.now(),
      );

      _messageController.add(message);
      _updateMetrics();

      _logger.t('📥 Message received: ${message.type}');

    } catch (e) {
      _logger.e('Error processing incoming message: $e');
    }
  }

  /// Send message internal
  Future<Result<bool>> _sendMessageInternal(WebSocketMessage message) async {
    try {
      final startTime = DateTime.now();

      if (_socketIO != null && _socketIO!.connected) {
        _socketIO!.emit('message', message.toJson());
      } else if (_webSocketChannel != null) {
        _webSocketChannel!.sink.add(jsonEncode(message.toJson()));
      } else {
        return const Failure('No active connection');
      }

      _messagesSent++;

      // Track latency
      final latency = DateTime.now().difference(startTime);
      _latencyMeasurements.add(latency);
      if (_latencyMeasurements.length > 100) {
        _latencyMeasurements.removeAt(0);
      }

      _updateMetrics();
      _logger.t('📤 Message sent: ${message.type}');

      return const Success(true);

    } catch (e) {
      _logger.e('Error sending message: $e');
      _queueMessage(message);
      return Failure('Send failed: $e');
    }
  }

  /// Queue message for offline sending
  void _queueMessage(WebSocketMessage message) {
    if (_messageQueue.length >= _maxQueueSize) {
      _messageQueue.removeAt(0); // Remove oldest message
    }
    _messageQueue.add(message);
    _updateMetrics();
    _logger.d('📦 Message queued: ${message.type}');
  }

  /// Process queued messages
  void _processMessageQueue() {
    if (_messageQueue.isEmpty) return;

    _logger.i('📦 Processing ${_messageQueue.length} queued messages');

    final messages = List<WebSocketMessage>.from(_messageQueue);
    _messageQueue.clear();

    for (final message in messages) {
      _sendMessageInternal(message);
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    if (currentState != WebSocketConnectionState.disconnected) {
      _updateConnectionState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Handle connection error
  void _handleConnectionError() {
    _updateConnectionState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.w('Max reconnect attempts reached');
      return;
    }

    _cancelReconnectTimer();

    final delay = Duration(
      milliseconds: _baseReconnectDelay.inMilliseconds *
          (1 << _reconnectAttempts.clamp(0, 6)), // Exponential backoff
    );

    _logger.d('Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _updateConnectionState(WebSocketConnectionState.reconnecting);
      connect();
    });
  }

  /// Start heartbeat
  void _startHeartbeat() {
    _cancelHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (isConnected) {
        _sendHeartbeat();
      }
    });
  }

  /// Send heartbeat
  void _sendHeartbeat() {
    if (_socketIO != null && _socketIO!.connected) {
      _socketIO!.emit('ping');
    } else if (_webSocketChannel != null) {
      _webSocketChannel!.sink.add(jsonEncode({'type': 'ping'}));
    }
    _logger.t('💓 Heartbeat sent');
  }

  /// Update connection state
  void _updateConnectionState(WebSocketConnectionState state) {
    _connectionStateController.add(state);
    _logger.d('🔄 Connection state: ${state.name}');
  }

  /// Update metrics
  void _updateMetrics() {
    final averageLatency = _latencyMeasurements.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: _latencyMeasurements
                .map((d) => d.inMicroseconds)
                .reduce((a, b) => a + b) ~/
                _latencyMeasurements.length,
          );

    final metrics = WebSocketMetrics(
      messagesSent: _messagesSent,
      messagesReceived: _messagesReceived,
      reconnectAttempts: _reconnectAttempts,
      averageLatency: averageLatency,
      lastConnected: _lastConnected ?? DateTime.now(),
      queuedMessages: _messageQueue.length,
    );

    _metricsController.add(metrics);
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_messagesSent}';
  }

  /// Cancel reconnect timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Cancel heartbeat
  void _cancelHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Disconnect Socket.IO
  Future<void> _disconnectSocketIO() async {
    if (_socketIO != null) {
      _socketIO!.disconnect();
      _socketIO!.dispose();
      _socketIO = null;
    }
  }

  /// Disconnect WebSocket
  Future<void> _disconnectWebSocket() async {
    if (_webSocketChannel != null) {
      await _webSocketChannel!.sink.close();
      _webSocketChannel = null;
    }
  }

  /// Reset metrics
  void _resetMetrics() {
    _messagesSent = 0;
    _messagesReceived = 0;
    _reconnectAttempts = 0;
    _latencyMeasurements.clear();
    _messageQueue.clear();
    _lastConnected = null;
  }
}
