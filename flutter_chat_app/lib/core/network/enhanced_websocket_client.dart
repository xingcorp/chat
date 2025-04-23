import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../monitoring/analytics_service.dart';
import 'models/socket_connection_state.dart';
import 'models/socket_error.dart';
import 'socket_analytics.dart' hide SocketErrorType;

/// Interface for WebSocket connections with advanced features
abstract class WebSocketClient {
  /// Connect to the specified URL
  Future<void> connect({Map<String, String>? headers});
  
  /// Disconnect from the server
  Future<void> disconnect({int? code, String? reason});
  
  /// Send data to the server
  void send(dynamic data);
  
  /// Send binary data to the server
  void sendBytes(Uint8List data);
  
  /// Stream of incoming text messages
  Stream<String> get textMessages;
  
  /// Stream of incoming binary messages
  Stream<Uint8List> get binaryMessages;
  
  /// Stream of connection state changes
  Stream<SocketConnectionState> get connectionState;
  
  /// Stream of errors
  Stream<SocketError> get errors;
  
  /// Current connection state
  SocketConnectionState get currentState;
  
  /// Whether the connection is currently established
  bool get isConnected;
  
  /// The URL this client is connected to
  String get url;
  
  /// Clean up resources
  void dispose();
}

/// Enhanced WebSocket client with automatic reconnection and performance monitoring
@lazySingleton
class EnhancedWebSocketClient implements WebSocketClient {
  /// Socket connection
  WebSocket? _socket;
  
  /// Connection URL
  final String _url;
  
  /// Logger instance
  final Logger _logger;
  
  /// Analytics service
  final SocketAnalytics _analytics;
  
  /// Analytics service for tracking
  final AnalyticsService _analyticsService;
  
  /// Authentication token provider
  final Future<String> Function()? _tokenProvider;
  
  /// Controller for text messages
  final PublishSubject<String> _textMessageController = PublishSubject<String>();
  
  /// Controller for binary messages
  final PublishSubject<Uint8List> _binaryMessageController = PublishSubject<Uint8List>();
  
  /// Controller for connection state
  final BehaviorSubject<SocketConnectionState> _connectionStateController = 
      BehaviorSubject<SocketConnectionState>.seeded(SocketConnectionState.disconnected);
  
  /// Controller for errors
  final PublishSubject<SocketError> _errorController = PublishSubject<SocketError>();
  
  /// Connection attempts
  int _connectAttempts = 0;
  
  /// Maximum connection attempts
  final int _maxConnectAttempts;
  
  /// Automatic reconnection
  final bool _autoReconnect;
  
  /// Connection timeout
  final Duration _connectTimeout;
  
  /// Ping interval
  final Duration _pingInterval;
  
  /// Timer for pings
  Timer? _pingTimer;
  
  /// Timer for reconnection
  Timer? _reconnectTimer;
  
  /// Subscriptions
  StreamSubscription? _socketSubscription;
  
  /// Custom headers
  Map<String, String>? _lastHeaders;
  
  /// Whether disconnect was initiated by user
  bool _userInitiatedDisconnect = false;
  
  /// Buffer of messages to send once connected
  final List<dynamic> _messageBuffer = [];
  
  /// Constructor
  EnhancedWebSocketClient(
    this._url, 
    this._logger,
    this._analytics,
    this._analyticsService, {
    Future<String> Function()? tokenProvider,
    int maxConnectAttempts = 5,
    bool autoReconnect = true,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration pingInterval = const Duration(seconds: 30),
  }) : 
    _tokenProvider = tokenProvider,
    _maxConnectAttempts = maxConnectAttempts,
    _autoReconnect = autoReconnect,
    _connectTimeout = connectTimeout,
    _pingInterval = pingInterval;
  
  @override
  Stream<String> get textMessages => _textMessageController.stream;
  
  @override
  Stream<Uint8List> get binaryMessages => _binaryMessageController.stream;
  
  @override
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  
  @override
  Stream<SocketError> get errors => _errorController.stream;
  
  @override
  SocketConnectionState get currentState => _connectionStateController.value;
  
  @override
  bool get isConnected => currentState == SocketConnectionState.connected;
  
  @override
  String get url => _url;
  
  /// Get authentication headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{};
    
    if (_tokenProvider != null) {
      try {
        final token = await _tokenProvider!();
        if (token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        _logger.e('Error getting authentication token: $e');
      }
    }
    
    return headers;
  }
  
  @override
  Future<void> connect({Map<String, String>? headers}) async {
    if (isConnected) {
      _logger.d('Already connected to $url');
      return;
    }
    
    if (currentState == SocketConnectionState.connecting) {
      _logger.d('Already connecting to $url');
      return;
    }
    
    _userInitiatedDisconnect = false;
    _updateConnectionState(SocketConnectionState.connecting);
    
    // Store headers for reconnection
    _lastHeaders = headers;
    
    try {
      _analytics.trackConnectionAttempt();
      _connectAttempts++;
      
      // Merge headers with auth headers
      final authHeaders = await _getAuthHeaders();
      final mergedHeaders = {...authHeaders, ...?headers};
      
      // Measure connection time
      final startTime = DateTime.now().millisecondsSinceEpoch;
      
      // Connect with timeout
      _socket = await WebSocket.connect(
        _url,
        headers: mergedHeaders,
      ).timeout(_connectTimeout);
      
      final connectionTime = DateTime.now().millisecondsSinceEpoch - startTime;
      _logger.i('Connected to $url in ${connectionTime}ms');
      
      // Reset connection attempts on success
      _connectAttempts = 0;
      
      // Set up listeners
      _socketSubscription = _socket!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );
      
      _updateConnectionState(SocketConnectionState.connected);
      _analytics.trackConnection();
      
      // Start ping timer
      _startPingTimer();
      
      // Process buffered messages
      _processBuffer();
    } catch (e) {
      final error = SocketError(
        type: SocketErrorType.connectionFailed,
        message: 'Failed to connect to $url: ${e.toString()}',
        originalError: e,
      );
      
      _handleError(error);
      
      // Schedule reconnect if enabled and not max attempts
      if (_autoReconnect && 
          !_userInitiatedDisconnect && 
          _connectAttempts < _maxConnectAttempts) {
        _scheduleReconnect();
      } else {
        _updateConnectionState(SocketConnectionState.disconnected);
      }
      
      rethrow;
    }
  }
  
  @override
  Future<void> disconnect({int? code, String? reason}) async {
    _userInitiatedDisconnect = true;
    _cancelReconnect();
    _cancelPingTimer();
    
    if (_socket != null) {
      try {
        await _socketSubscription?.cancel();
        _socketSubscription = null;
        
        await _socket!.close(code ?? WebSocketStatus.normalClosure, reason ?? 'Normal closure');
        _socket = null;
        
        _updateConnectionState(SocketConnectionState.disconnectedByUser);
        _analytics.trackDisconnection(reason: 'user_initiated');
        
        _logger.i('Disconnected from $url');
      } catch (e) {
        _logger.e('Error disconnecting from $url: $e');
      }
    }
  }
  
  @override
  void send(dynamic data) {
    if (!isConnected) {
      if (_autoReconnect && !_userInitiatedDisconnect) {
        // Buffer message for later
        _messageBuffer.add(data);
        _logger.d('Message buffered for later sending');
        return;
      } else {
        _logger.w('Cannot send message - not connected');
        return;
      }
    }
    
    try {
      if (data is String) {
        _socket!.add(data);
        _analytics.trackEventSent('message');
      } else if (data is Map || data is List) {
        final jsonString = jsonEncode(data);
        _socket!.add(jsonString);
        _analytics.trackEventSent('json');
      } else {
        _socket!.add(data.toString());
        _analytics.trackEventSent('data');
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      _errorController.add(SocketError(
        type: SocketErrorType.serverError,
        message: 'Error sending message: ${e.toString()}',
        originalError: e,
      ));
    }
  }
  
  @override
  void sendBytes(Uint8List data) {
    if (!isConnected) {
      if (_autoReconnect && !_userInitiatedDisconnect) {
        // Buffer message for later
        _messageBuffer.add(data);
        _logger.d('Binary message buffered for later sending');
        return;
      } else {
        _logger.w('Cannot send binary message - not connected');
        return;
      }
    }
    
    try {
      _socket!.add(data);
      _analytics.trackEventSent('binary');
    } catch (e) {
      _logger.e('Error sending binary message: $e');
      _errorController.add(SocketError(
        type: SocketErrorType.serverError,
        message: 'Error sending binary message: ${e.toString()}',
        originalError: e,
      ));
    }
  }
  
  /// Send ping to keep connection alive
  void _sendPing() {
    if (!isConnected || _socket == null) {
      return;
    }
    
    try {
      final pingTime = DateTime.now().millisecondsSinceEpoch;
      final pingData = jsonEncode({
        'type': 'ping',
        'timestamp': pingTime
      });
      
      _socket!.add(pingData);
      
      // Set up timeout to measure latency
      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (isConnected) {
          final latency = DateTime.now().millisecondsSinceEpoch - pingTime;
          if (latency < 10000) { // Reasonable latency
            _analytics.trackEventLatency('ping', latency);
          }
        }
      });
    } catch (e) {
      _logger.w('Error sending ping: $e');
    }
  }
  
  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        _analytics.trackEventReceived('message');
        
        // Check if it's a pong message
        try {
          final data = jsonDecode(message);
          if (data is Map && data['type'] == 'pong' && data.containsKey('timestamp')) {
            final pingTime = data['timestamp'] as int;
            final pongTime = DateTime.now().millisecondsSinceEpoch;
            final latency = pongTime - pingTime;
            
            _analytics.trackEventLatency('ping-pong', latency);
            return;
          }
        } catch (_) {
          // Not a JSON message or not a pong, continue with normal handling
        }
        
        _textMessageController.add(message);
      } else if (message is Uint8List) {
        _analytics.trackEventReceived('binary');
        _binaryMessageController.add(message);
      } else {
        _logger.w('Received unsupported message type: ${message.runtimeType}');
      }
    } catch (e) {
      _logger.e('Error handling message: $e');
    }
  }
  
  /// Handle WebSocket error
  void _handleError(dynamic error) {
    if (error is SocketError) {
      _errorController.add(error);
    } else {
      final socketError = SocketError(
        type: SocketErrorType.unknown,
        message: 'WebSocket error: ${error.toString()}',
        originalError: error,
      );
      _errorController.add(socketError);
    }
    
    _logger.e('WebSocket error: $error');
    _updateConnectionState(SocketConnectionState.error);
    
    if (_autoReconnect && !_userInitiatedDisconnect) {
      _scheduleReconnect();
    }
  }
  
  /// Handle WebSocket connection closed
  void _handleDone() {
    _logger.i('WebSocket connection closed');
    _socket = null;
    
    _updateConnectionState(
      _userInitiatedDisconnect 
        ? SocketConnectionState.disconnectedByUser 
        : SocketConnectionState.disconnectedByServer
    );
    
    _analytics.trackDisconnection(
      reason: _userInitiatedDisconnect 
        ? 'user_initiated' 
        : 'server_closed'
    );
    
    _cancelPingTimer();
    
    if (_autoReconnect && !_userInitiatedDisconnect) {
      _scheduleReconnect();
    }
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _cancelReconnect();
    
    if (_connectAttempts >= _maxConnectAttempts) {
      _logger.w('Maximum reconnection attempts reached: $_connectAttempts');
      _updateConnectionState(SocketConnectionState.disconnected);
      
      _analyticsService.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'websocket_max_reconnect_attempts',
        parameters: {'url': _url, 'attempts': _connectAttempts},
      );
      
      return;
    }
    
    // Exponential backoff with jitter
    final baseDelay = 1000 * math.pow(1.5, _connectAttempts.toDouble()); 
    final jitter = 500 * _generateRandomDouble();
    final delay = math.min(baseDelay + jitter, 30000);
    
    _logger.d('Scheduling reconnect in ${delay.toInt()}ms (attempt $_connectAttempts)');
    _updateConnectionState(SocketConnectionState.reconnecting);
    
    _reconnectTimer = Timer(Duration(milliseconds: delay.toInt()), () {
      _reconnectTimer = null;
      connect(headers: _lastHeaders);
    });
  }
  
  /// Generate a random double between 0 and 1
  double _generateRandomDouble() {
    final random = math.Random();
    return random.nextDouble();
  }
  
  /// Start ping timer
  void _startPingTimer() {
    _cancelPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }
  
  /// Cancel ping timer
  void _cancelPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
  
  /// Cancel reconnect timer
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Process buffered messages after reconnection
  void _processBuffer() {
    if (_messageBuffer.isEmpty || !isConnected) {
      return;
    }
    
    _logger.d('Processing ${_messageBuffer.length} buffered messages');
    
    // Create a copy and clear buffer
    final messages = List.from(_messageBuffer);
    _messageBuffer.clear();
    
    // Send all buffered messages
    for (final message in messages) {
      if (message is Uint8List) {
        sendBytes(message);
      } else {
        send(message);
      }
    }
    
    _logger.d('Processed all buffered messages');
  }
  
  /// Update connection state
  void _updateConnectionState(SocketConnectionState state) {
    if (!_connectionStateController.isClosed && _connectionStateController.value != state) {
      _connectionStateController.add(state);
    }
  }
  
  @override
  void dispose() {
    _cancelPingTimer();
    _cancelReconnect();
    
    if (_socket != null) {
      disconnect();
    }
    
    _socketSubscription?.cancel();
    _socketSubscription = null;
    
    _textMessageController.close();
    _binaryMessageController.close();
    _errorController.close();
    _connectionStateController.close();
    
    _messageBuffer.clear();
  }
} 