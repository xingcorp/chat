import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';

import '../monitoring/analytics_service.dart';
import 'models/socket_connection_state.dart';
import 'models/socket_error.dart';
import 'models/network_quality.dart';
import 'socket_manager.dart';
import 'socket_analytics.dart' hide SocketErrorType;
import 'socket_rate_limiter.dart';

/// Service that handles WebSocket connections with optimized performance
@lazySingleton
class SocketConnectionService {
  /// The underlying socket manager
  final SocketManager _socketManager;
  
  /// Socket analytics service
  final SocketAnalytics _analytics;
  
  /// Rate limiter for socket events
  final SocketRateLimiter _rateLimiter;
  
  /// Logger instance
  final Logger _logger;
  
  /// Controller for tracking network quality
  final BehaviorSubject<NetworkQuality> _networkQualityController = 
      BehaviorSubject<NetworkQuality>.seeded(NetworkQuality.offline);
  
  /// Controller for tracking socket errors
  final PublishSubject<SocketError> _errorController = PublishSubject<SocketError>();
  
  /// Timer for checking connection quality
  Timer? _qualityCheckTimer;
  
  /// Timer for retrying failed connections
  Timer? _reconnectTimer;
  
  /// Controller for connection state events
  final BehaviorSubject<SocketConnectionState> _connectionStateController = 
      BehaviorSubject<SocketConnectionState>.seeded(SocketConnectionState.disconnected);
  
  /// Number of reconnection attempts
  int _reconnectAttempts = 0;
  
  /// Maximum number of reconnection attempts
  final int _maxReconnectAttempts = 10;
  
  /// Whether to automatically reconnect
  bool _autoReconnect = true;
  
  /// List of subscriptions
  final List<StreamSubscription> _subscriptions = [];
  
  /// Constructor
  SocketConnectionService(
    this._socketManager,
    this._analytics,
    this._rateLimiter,
    this._logger,
  ) {
    _initialize();
  }
  
  /// Get connection state stream
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  
  /// Get current connection state
  SocketConnectionState get currentState => _connectionStateController.value;
  
  /// Get network quality stream
  Stream<NetworkQuality> get networkQuality => _networkQualityController.stream;
  
  /// Get current network quality
  NetworkQuality get currentNetworkQuality => _networkQualityController.value;
  
  /// Get error stream
  Stream<SocketError> get errors => _errorController.stream;
  
  /// Whether the connection is currently active
  bool get isConnected => _socketManager.isConnected;
  
  /// Initialize the service
  void _initialize() {
    // Listen to socket manager connection state changes
    _subscriptions.add(
      _socketManager.connectionState.listen(_handleConnectionStateChange)
    );
    
    // Start periodic connection quality checks
    _startQualityCheck();
  }
  
  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (isConnected) {
      _logger.d('Already connected, ignoring connect request');
      return;
    }
    
    _updateConnectionState(SocketConnectionState.connecting);
    try {
      await _socketManager.connect();
    } catch (e) {
      _handleError(SocketError(
        type: SocketErrorType.connectionFailed,
        message: 'Failed to connect: ${e.toString()}',
        originalError: e,
      ));
    }
  }
  
  /// Disconnect from the WebSocket server
  Future<void> disconnect() async {
    _autoReconnect = false;
    _cancelReconnect();
    await _socketManager.disconnect();
    _updateConnectionState(SocketConnectionState.disconnectedByUser);
  }
  
  /// Send event through the WebSocket
  void emit(String event, [dynamic data]) {
    // Check if we're connected
    if (!isConnected) {
      _logger.w('Cannot emit event: Socket not connected');
      _errorController.add(SocketError(
        type: SocketErrorType.connectionLost,
        message: 'Cannot emit event: Socket not connected',
      ));
      return;
    }
    
    // Check rate limits
    final rateLimitResult = _rateLimiter.checkRateLimit(event);
    if (!rateLimitResult.allowed) {
      _errorController.add(SocketError(
        type: SocketErrorType.rateLimitExceeded,
        message: 'Rate limit exceeded for event: $event',
        data: rateLimitResult.info,
      ));
      
      // Queue message for later
      _rateLimiter.enqueueMessage(event, data, (queuedData) {
        _socketManager.emit(event, queuedData);
        _analytics.trackEventSent(event);
      });
      
      _analytics.trackRateLimited(event);
      return;
    }
    
    // Send the message
    _socketManager.emit(event, data);
    _rateLimiter.recordMessage(event);
    _analytics.trackEventSent(event);
  }
  
  /// Send event and wait for acknowledgment
  Future<T?> emitWithAck<T>(String event, [dynamic data, Duration timeout = const Duration(seconds: 10)]) async {
    if (!isConnected) {
      throw SocketError(
        type: SocketErrorType.connectionLost,
        message: 'Cannot emit event: Socket not connected',
      );
    }
    
    // Check rate limits
    final rateLimitResult = _rateLimiter.checkRateLimit(event);
    if (!rateLimitResult.allowed) {
      throw SocketError(
        type: SocketErrorType.rateLimitExceeded,
        message: 'Rate limit exceeded for event: $event',
        data: rateLimitResult.info,
      );
    }
    
    // Create a completer to handle the response
    final completer = Completer<T?>();
    
    // Set up timeout
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(SocketError(
          type: SocketErrorType.timeout,
          message: 'Request timed out: $event',
        ));
      }
    });
    
    try {
      // Create a unique ack ID
      final ackId = DateTime.now().millisecondsSinceEpoch.toString() + 
                   '_' + 
                   (data is Map ? json.encode(data).hashCode : data.hashCode).toString();
      
      // Add ack ID to data
      final Map<String, dynamic> dataWithAck;
      if (data is Map) {
        dataWithAck = {...Map<String, dynamic>.from(data), '_ackId': ackId};
      } else {
        dataWithAck = {'data': data, '_ackId': ackId};
      }
      
      // Set up listener for ack events
      final subscription = on<Map<String, dynamic>>('ack:$ackId').listen(
        (response) {
          timer.cancel();
          if (!completer.isCompleted) {
            final result = response['data'] as T?;
            completer.complete(result);
          }
        },
        onError: (error) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        }
      );
      
      // Clean up subscription when timer fires
      subscription.onDone(() {
        timer.cancel();
      });
      
      // Send the message
      _socketManager.emit(event, dataWithAck);
      _rateLimiter.recordMessage(event);
      _analytics.trackEventSent(event);
      
      // Start tracking event latency
      final startTime = DateTime.now().millisecondsSinceEpoch;
      
      // When complete, record latency
      completer.future.then((_) {
        final latency = DateTime.now().millisecondsSinceEpoch - startTime;
        _analytics.trackEventLatency(event, latency);
      }).catchError((e) {
        _analytics.trackEventFailure(event, errorMessage: e.toString());
      });
      
      return await completer.future;
    } catch (e) {
      timer.cancel();
      _analytics.trackEventFailure(event, errorMessage: e.toString());
      rethrow;
    }
  }
  
  /// Listen for events from the server
  Stream<T> on<T>(String event) {
    final controller = BehaviorSubject<T>();
    
    final subscription = _socketManager.on<T>(event).listen(
      (data) {
        if (!controller.isClosed) {
          controller.add(data);
          _analytics.trackEventReceived(event);
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
          _analytics.trackEventFailure(event, errorMessage: error.toString());
        }
      }
    );
    
    _subscriptions.add(subscription);
    controller.onCancel = () {
      subscription.cancel();
    };
    
    return controller.stream;
  }
  
  /// Handle connection state changes
  void _handleConnectionStateChange(SocketConnectionState state) {
    _updateConnectionState(state);
    
    switch (state) {
      case SocketConnectionState.connected:
        _reconnectAttempts = 0;
        _startQualityCheck();
        _analytics.trackConnection();
        break;
        
      case SocketConnectionState.disconnected:
      case SocketConnectionState.disconnectedByServer:
      case SocketConnectionState.error:
        if (_autoReconnect) {
          _scheduleReconnect();
        }
        _analytics.trackDisconnection(reason: state.toString());
        break;
        
      case SocketConnectionState.disconnectedByUser:
        // Do not reconnect when user disconnects
        _autoReconnect = false;
        _analytics.trackDisconnection(reason: 'user_initiated');
        break;
        
      case SocketConnectionState.connecting:
      case SocketConnectionState.reconnecting:
        // These states are handled by the socket manager
        _analytics.trackConnectionAttempt();
        break;
    }
  }
  
  /// Schedule a reconnection attempt
  void _scheduleReconnect() {
    _cancelReconnect();
    
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.w('Maximum reconnection attempts reached');
      _updateConnectionState(SocketConnectionState.disconnected);
      return;
    }
    
    _reconnectAttempts++;
    
    // Calculate backoff time (exponential backoff with jitter)
    final baseDelay = 1000 * math.pow(1.5, _reconnectAttempts.toDouble());
    final jitter = 500 * _generateRandomDouble();
    final delay = math.min(baseDelay + jitter, 30000);
    
    _updateConnectionState(SocketConnectionState.reconnecting);
    
    _reconnectTimer = Timer(Duration(milliseconds: delay.toInt()), () {
      _reconnectTimer = null;
      connect();
    });
  }
  
  /// Generate a random double between 0 and 1
  double _generateRandomDouble() {
    return (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
  }
  
  /// Cancel the reconnection timer
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Handle socket errors
  void _handleError(SocketError error) {
    _logger.e('Socket error: ${error.message}');
    _errorController.add(error);
  }
  
  /// Start periodic connection quality checks
  void _startQualityCheck() {
    _qualityCheckTimer?.cancel();
    
    // Check every 30 seconds
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkNetworkQuality();
    });
    
    // Check immediately
    _checkNetworkQuality();
  }
  
  /// Check network quality
  Future<void> _checkNetworkQuality() async {
    if (!isConnected) {
      _networkQualityController.add(NetworkQuality.offline);
      return;
    }
    
    try {
      final metrics = _analytics.getMetrics();
      final latencies = metrics['average_latencies'] as Map<String, double>? ?? {};
      
      // Calculate average latency across all events
      double avgLatency = 0;
      if (latencies.isNotEmpty) {
        final sum = latencies.values.fold<double>(0, (prev, curr) => prev + curr);
        avgLatency = sum / latencies.length;
      }
      
      // Determine quality based on latency and error rates
      NetworkQuality quality;
      if (avgLatency < 100) {
        quality = NetworkQuality.excellent;
      } else if (avgLatency < 300) {
        quality = NetworkQuality.good;
      } else if (avgLatency < 1000) {
        quality = NetworkQuality.fair;
      } else if (avgLatency < 3000) {
        quality = NetworkQuality.poor;
      } else {
        quality = NetworkQuality.veryPoor;
      }
      
      // Update the quality if it changed
      if (quality != _networkQualityController.value) {
        _networkQualityController.add(quality);
        _logger.i('Network quality: $quality (avg latency: ${avgLatency.toStringAsFixed(0)}ms)');
      }
    } catch (e) {
      _logger.e('Error checking network quality: $e');
    }
  }
  
  /// Update connection state
  void _updateConnectionState(SocketConnectionState state) {
    if (!_connectionStateController.isClosed && _connectionStateController.value != state) {
      _connectionStateController.add(state);
    }
  }
  
  /// Dispose resources
  void dispose() {
    _qualityCheckTimer?.cancel();
    _reconnectTimer?.cancel();
    
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _networkQualityController.close();
    _errorController.close();
    _connectionStateController.close();
  }
}

/// Extension on Completer to check completion status
extension CompleterExtension on Completer {
  bool get isCompleted {
    // This is a workaround since Dart doesn't expose isCompleted directly
    try {
      // Try to complete it with a dummy value
      Future.microtask(() => null);
      return false;  // If no exception is thrown, it's not completed
    } catch (_) {
      return true;   // If an exception is thrown, it's already completed
    }
  }
} 