import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../monitoring/analytics_service.dart';
import '../monitoring/logger_service.dart';
import 'socket_connection_quality.dart';
import 'socket_event_rate_limiter.dart';

/// Advanced WebSocket client with performance monitoring, auto-reconnect,
/// quality monitoring, rate limiting, and efficient event handling
class AdvancedSocketClient {
  /// Socket.io client instance
  Socket? _socket;
  
  /// Server URL for socket connection
  final String _serverUrl;
  
  /// Socket options configuration
  final Map<String, dynamic> _options;
  
  /// Logger instance for debug and error information
  final LoggerService _logger;
  
  /// Analytics service for tracking socket performance
  final AnalyticsService _analytics;
  
  /// Connection quality monitor
  late final SocketConnectionQualityMonitor _qualityMonitor;
  
  /// Rate limiter for outgoing events
  late final SocketEventRateLimiter _rateLimiter;
  
  /// Current connection state
  bool _isConnected = false;
  
  /// Pending events to be sent when connection is established
  final List<_PendingEvent> _pendingEvents = [];
  
  /// Callback for quality change events
  Function(SocketConnectionQuality)? onQualityChange;
  
  /// Stream controller for connection state changes
  final StreamController<bool> _connectionStateController = 
      StreamController<bool>.broadcast();
  
  /// Stream of connection state changes (true = connected, false = disconnected)
  Stream<bool> get connectionState => _connectionStateController.stream;
  
  /// Connection quality monitor instance
  SocketConnectionQualityMonitor get qualityMonitor => _qualityMonitor;
  
  /// Creates an advanced socket client
  AdvancedSocketClient({
    required String serverUrl,
    required LoggerService logger,
    required AnalyticsService analytics,
    Map<String, dynamic> options = const {},
    int maxEventsPerSecond = 50,
    int qualityCheckIntervalMs = 5000,
  }) : _serverUrl = serverUrl,
       _options = options,
       _logger = logger,
       _analytics = analytics {
    // Initialize quality monitor
    _qualityMonitor = SocketConnectionQualityMonitor();
    
    // Initialize rate limiter (50 events per second by default)
    _rateLimiter = SocketEventRateLimiter(
      maxEvents: maxEventsPerSecond,
      timeWindowMs: 1000, // 1 second window
    );
    
    // Start periodic quality check
    Timer.periodic(Duration(milliseconds: qualityCheckIntervalMs), (_) {
      _checkConnectionQuality();
    });
  }
  
  /// Connect to the socket server
  Future<void> connect() async {
    if (_socket != null) {
      _logger.debug('Socket already exists, disconnecting first');
      disconnect();
    }
    
    try {
      _logger.info('Connecting to socket server: $_serverUrl');
      
      // Default options
      final defaultOptions = {
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'timeout': 20000,
      };
      
      // Merge with user options
      final mergedOptions = {...defaultOptions, ..._options};
      
      // Create and connect socket
      _socket = io(_serverUrl, mergedOptions);
      
      // Set up event handlers
      _setupEventHandlers();
      
      // Start performance monitoring
      _startPerformanceMonitoring();
      
    } catch (e, stackTrace) {
      _logger.error('Error connecting to socket server', e, stackTrace);
      _analytics.logError(
        'socket_connection_error',
        {'error': e.toString(), 'url': _serverUrl}
      );
      rethrow;
    }
  }
  
  /// Disconnect from the socket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setConnected(false);
    _logger.info('Disconnected from socket server');
  }
  
  /// Set up socket event handlers
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      _logger.info('Socket connected');
      _setConnected(true);
      _processPendingEvents();
      
      // Send ping to measure initial latency
      _measureLatency();
    });
    
    _socket?.onDisconnect((_) {
      _logger.info('Socket disconnected');
      _setConnected(false);
      _qualityMonitor.updateQuality(SocketConnectionQuality.none);
    });
    
    _socket?.onConnectError((error) {
      _logger.error('Socket connection error', error);
      _analytics.logError(
        'socket_connection_error',
        {'error': error.toString(), 'url': _serverUrl}
      );
    });
    
    _socket?.onError((error) {
      _logger.error('Socket error', error);
      _analytics.logError(
        'socket_error',
        {'error': error.toString()}
      );
    });
  }
  
  /// Start monitoring socket performance
  void _startPerformanceMonitoring() {
    // Periodically measure latency
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isConnected) {
        _measureLatency();
      }
    });
  }
  
  /// Measure current latency
  void _measureLatency() {
    if (!_isConnected || _socket == null) return;
    
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Use socket.io ping feature
    _socket!.emit('ping', (_) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final latency = endTime - startTime;
      
      _qualityMonitor.addLatencyMeasurement(latency);
      
      // Track very high latency
      if (latency > 500) {
        _analytics.logEvent(
          AnalyticsEvent.custom,
          {'type': 'high_socket_latency', 'value': latency}
        );
      }
    });
  }
  
  /// Check connection quality and trigger callbacks if needed
  void _checkConnectionQuality() {
    if (!_isConnected) return;
    
    // Get current quality
    final oldQuality = _qualityMonitor.currentQuality;
    
    // Update quality (this will recalculate based on recent measurements)
    _qualityMonitor.updateMetrics();
    
    // Get new quality
    final newQuality = _qualityMonitor.currentQuality;
    
    // If quality changed, notify listeners
    if (oldQuality != newQuality) {
      onQualityChange?.call(newQuality);
      
      // Log quality changes (except initial connection)
      if (oldQuality != SocketConnectionQuality.none) {
        _analytics.logEvent(
          AnalyticsEvent.custom,
          {
            'type': 'socket_quality_change',
            'from': oldQuality.toString(),
            'to': newQuality.toString(),
            'metrics': _qualityMonitor.getSummary(),
          }
        );
      }
    }
  }
  
  /// Register a listener for socket events
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, (data) {
      try {
        callback(data);
      } catch (e, stackTrace) {
        _logger.error('Error in socket event handler: $event', e, stackTrace);
      }
    });
  }
  
  /// Remove a listener for socket events
  void off(String event) {
    _socket?.off(event);
  }
  
  /// Emit an event to the server
  void emit(String event, dynamic data) {
    if (!_isConnected) {
      _logger.debug('Socket not connected, adding event to pending list: $event');
      _pendingEvents.add(_PendingEvent(event, data));
      return;
    }
    
    // Check rate limiting
    if (_rateLimiter.shouldLimit(event)) {
      _logger.warning('Rate limiting socket event: $event');
      
      // Track rate limited events
      _analytics.logEvent(
        AnalyticsEvent.custom,
        {'type': 'socket_rate_limited', 'event': event}
      );
      
      return;
    }
    
    try {
      // Record the event for rate limiting
      _rateLimiter.recordEvent(event);
      
      // Emit the event
      _socket?.emit(event, data);
      
    } catch (e, stackTrace) {
      _logger.error('Error emitting socket event: $event', e, stackTrace);
    }
  }
  
  /// Emit an event and get a response
  Future<T> emitWithAck<T>(String event, dynamic data, {Duration timeout = const Duration(seconds: 10)}) {
    final completer = Completer<T>();
    
    if (!_isConnected) {
      completer.completeError('Socket not connected');
      return completer.future;
    }
    
    // Check rate limiting
    if (_rateLimiter.shouldLimit(event)) {
      _logger.warning('Rate limiting socket event with ack: $event');
      completer.completeError('Rate limited');
      return completer.future;
    }
    
    try {
      // Record the event for rate limiting
      _rateLimiter.recordEvent(event);
      
      // Set timeout
      Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError('Timeout');
          
          // Log timeouts for analysis
          _analytics.logEvent(
            AnalyticsEvent.custom,
            {'type': 'socket_ack_timeout', 'event': event}
          );
          
          // Increment packet loss counter
          _qualityMonitor.incrementPacketLoss();
        }
      });
      
      // Emit with acknowledgement
      _socket?.emitWithAck(event, data, ack: (response) {
        if (!completer.isCompleted) {
          completer.complete(response as T);
        }
      });
      
    } catch (e, stackTrace) {
      _logger.error('Error emitting socket event with ack: $event', e, stackTrace);
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
    
    return completer.future;
  }
  
  /// Process any events that were emitted while disconnected
  void _processPendingEvents() {
    if (_pendingEvents.isEmpty) return;
    
    _logger.debug('Processing ${_pendingEvents.length} pending events');
    
    // Process all pending events
    final events = List<_PendingEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    
    for (final event in events) {
      emit(event.name, event.data);
    }
  }
  
  /// Set the connection state and notify listeners
  void _setConnected(bool connected) {
    if (_isConnected == connected) return;
    
    _isConnected = connected;
    _connectionStateController.add(connected);
  }
  
  /// Get the current connection state
  bool get isConnected => _isConnected;
  
  /// Set a custom rate limit for a specific event
  void setEventRateLimit(String event, int maxPerSecond) {
    _rateLimiter.setCustomRateLimit(event, maxPerSecond, 1000);
  }
  
  /// Block a specific event from being emitted
  void blockEvent(String event) {
    _rateLimiter.blockEvent(event);
  }
  
  /// Unblock a previously blocked event
  void unblockEvent(String event) {
    _rateLimiter.unblockEvent(event);
  }
  
  /// Dispose the client and release resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
  }
}

/// Represents a pending event to be sent when connection is established
class _PendingEvent {
  final String name;
  final dynamic data;
  
  _PendingEvent(this.name, this.data);
} 