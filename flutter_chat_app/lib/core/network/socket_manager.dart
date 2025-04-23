import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../monitoring/analytics_service.dart';
import 'models/socket_connection_state.dart';

/// Base Socket Manager that handles Socket.IO connections
@injectable
class SocketManager {
  /// Socket.IO client instance
  io.Socket? _socket;
  
  /// Server URL for WebSocket connection
  final String _serverUrl;
  
  /// Connection options for Socket.IO
  final Map<String, dynamic> _options;

  /// Logger instance
  final Logger _logger;
  
  /// Analytics service for tracking performance
  final AnalyticsService? _analytics;
  
  /// Current connection state
  final BehaviorSubject<SocketConnectionState> _connectionStateController = 
      BehaviorSubject<SocketConnectionState>.seeded(SocketConnectionState.disconnected);
  
  /// Stream of connection state changes
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  
  /// Stream của trạng thái kết nối để tương thích ngược
  Stream<SocketConnectionState> get connectionStateStream => connectionState;
  
  /// Current connection state
  SocketConnectionState get currentState => _connectionStateController.value;
  
  /// Whether the socket is connected
  bool get isConnected => currentState == SocketConnectionState.connected;
  
  /// Whether the socket is connecting
  bool get isConnecting => currentState == SocketConnectionState.connecting;
  
  /// Whether the socket is disconnected
  bool get isDisconnected => 
      currentState == SocketConnectionState.disconnected || 
      currentState == SocketConnectionState.disconnectedByUser || 
      currentState == SocketConnectionState.disconnectedByServer || 
      currentState == SocketConnectionState.error;

  /// Connected getter for backwards compatibility
  bool get connected => isConnected;
  
  /// Constructor
  SocketManager({
    required String serverUrl,
    Map<String, dynamic> options = const {},
    Logger? logger,
    AnalyticsService? analytics,
  }) : _serverUrl = serverUrl,
       _options = options,
       _logger = logger ?? Logger(),
       _analytics = analytics;
  
  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_socket != null && (isConnected || isConnecting)) {
      _logger.d('Socket already connected or connecting');
      return;
    }
    
    if (_socket != null) {
       _logger.d('Existing socket found, disposing before reconnecting');
       await disconnect();
    }

    _updateConnectionState(SocketConnectionState.connecting);
    
    try {
      final defaultOptions = {
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'timeout': 10000,
        'query': _options['query'],
        'auth': _options['auth'],
        'extraHeaders': _options['extraHeaders'],
      };
      
      final providedOptions = Map<String, dynamic>.from(_options)
        ..removeWhere((key, value) => value == null);
        
      final mergedOptions = {...defaultOptions, ...providedOptions};
      
      _logger.d('Socket.IO connecting to $_serverUrl with options: $mergedOptions');

      _socket = io.io(_serverUrl, mergedOptions);
      
      _setupEventHandlers();
      
      _socket!.connect();

      _logger.i('Socket.IO connection attempt initiated to $_serverUrl');
      
      _analytics?.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_connect_attempt',
        parameters: {'url': _serverUrl},
      );

    } catch (e, stackTrace) {
      _logger.e('Error initiating socket connection: $e', stackTrace: stackTrace);
      _updateConnectionState(SocketConnectionState.error);
      
      _analytics?.logError(
        errorType: 'socket_init_error',
        errorMessage: e.toString(),
        errorDetails: 'URL: $_serverUrl',
      );
    }
  }
  
  /// Disconnect from the WebSocket server
  Future<void> disconnect() async {
    if (_socket != null) {
      _logger.d('Disconnecting socket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _updateConnectionState(SocketConnectionState.disconnectedByUser);
      
      _analytics?.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_disconnect',
        parameters: {'reason': 'user_request'},
      );
    }
  }
  
  /// Set up Socket.IO event handlers
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      _logger.i('Socket connected');
      _updateConnectionState(SocketConnectionState.connected);
      
      _analytics?.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_connected',
        parameters: {'url': _serverUrl},
      );
    });
    
    _socket?.onDisconnect((reason) {
      _logger.i('Socket disconnected. Reason: $reason');
      if (currentState != SocketConnectionState.disconnectedByUser) {
        final newState = (reason == 'io server disconnect' || reason == 'transport close')
            ? SocketConnectionState.disconnectedByServer
            : SocketConnectionState.disconnected; 
        _updateConnectionState(newState);
        
        _analytics?.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_disconnected',
          parameters: {'reason': reason},
        );
      }
    });
    
    _socket?.onConnectError((error) {
      _logger.e('Socket connect error: $error');
      _updateConnectionState(SocketConnectionState.error);
      
      _analytics?.logError(
        errorType: 'socket_connect_error',
        errorMessage: error.toString(),
        errorDetails: 'URL: $_serverUrl',
      );
    });
    
    _socket?.onError((error) {
      _logger.e('Socket error: $error');
      _analytics?.logError(
        errorType: 'socket_error',
        errorMessage: error.toString(),
      );
    });
    
    _socket?.onReconnect((attempt) {
      _logger.i('Socket reconnected on attempt #$attempt');
      _updateConnectionState(SocketConnectionState.connected);
      
      _analytics?.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_reconnected',
         parameters: {'attempt': attempt},
      );
    });
        
    _socket?.on('reconnect_attempt', (attempt) {
      _logger.i('Socket reconnecting (attempt: $attempt)');
      _updateConnectionState(SocketConnectionState.reconnecting);
      
      _analytics?.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_reconnecting',
        parameters: {'attempt': attempt},
      );
    });
    
    _socket?.onReconnectFailed((_) {
      _logger.e('Socket reconnect failed after maximum attempts');
      _updateConnectionState(SocketConnectionState.error);
      
      _analytics?.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_reconnect_failed',
        parameters: {},
      );
    });
     _socket?.onReconnectError((error) {
       _logger.e('Socket reconnect error: $error');
        _analytics?.logError(
          errorType: 'socket_reconnect_error',
          errorMessage: error.toString(),
        );
     });

  }
  
  /// Update connection state only if changed and controller is not closed
  void _updateConnectionState(SocketConnectionState state) {
    if (!_connectionStateController.isClosed && currentState != state) {
      _logger.d('Socket state changed: ${currentState.name} -> ${state.name}');
      _connectionStateController.add(state);
    }
  }
  
  /// Register a listener for socket events
  Stream<T> on<T>(String event) {
    final controller = StreamController<T>.broadcast();
    
    final listener = (data) {
       if (!controller.isClosed) {
         try {
           controller.add(data as T);
         } catch (e, stackTrace) {
           _logger.e(
             'Type error casting data for event \'$event\'. Expected $T, got ${data?.runtimeType}. Error: $e',
             stackTrace: stackTrace
           );
           controller.addError(e, stackTrace);
         }
       }
     };

    if (_socket != null) {
      _socket!.on(event, listener);
      _logger.d('Registered listener for event: $event');
    } else {
       _logger.w('Cannot register listener for event \'$event\' - Socket is null');
    }
    
    controller.onCancel = () {
      if (_socket != null) {
        _socket!.off(event, listener);
        _logger.d('Unregistered listener for event: $event');
      }
      controller.close();
    };
    
    return controller.stream;
  }
  
  /// Emit an event to the server
  void emit(String event, [dynamic data]) {
    if (_socket != null && isConnected) {
      if (kDebugMode) {
         _logger.d('Emitting event: $event, Data: $data');
      } else {
         _logger.d('Emitting event: $event');
      }
      _socket!.emit(event, data);
    } else {
      _logger.w('Cannot emit event: $event - Socket not connected or null');
    }
  }
  
  /// Emit an event and wait for an acknowledgment
  void emitWithAck(String event, dynamic data, {Function? ack}) {
    if (_socket != null && isConnected) {
      if (kDebugMode) {
        _logger.d('Emitting event with ack: $event, Data: $data');
      } else {
        _logger.d('Emitting event with ack: $event');
      }
      _socket!.emitWithAck(event, data, ack: ack);
    } else {
      _logger.w('Cannot emit event with ack: $event - Socket not connected or null');
      ack?.call({'error': 'Socket not connected'});
    }
  }
  
  /// Enter background mode - currently no specific action needed for Socket.IO client
  void enterBackgroundMode() {
    _logger.d('Entering background mode (SocketManager - No specific action)');
  }
  
  /// Enter foreground mode - currently no specific action needed for Socket.IO client
  void enterForegroundMode() {
    _logger.d('Entering foreground mode (SocketManager - No specific action)');
  }
  
  /// Dispose resources
  void dispose() {
    _logger.d('Disposing SocketManager');
    disconnect();
    _connectionStateController.close();
  }
} 