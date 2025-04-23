import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../monitoring/analytics_service.dart';
import 'models/socket_connection_state.dart';
import 'models/socket_error.dart';

/// Una implementación optimizada del cliente Socket.IO que proporciona
/// comunicación en tiempo real, gestión mejorada de estados y monitoreo de rendimiento.
@injectable
class SocketIOClient {
  /// Instancia del Socket.IO
  io.Socket? _socket;
  
  /// URL del servidor para la conexión WebSocket
  final String _serverUrl;
  
  /// Opciones de conexión para Socket.IO
  final Map<String, dynamic> _options;

  /// Instancia del logger
  final Logger _logger;
  
  /// Servicio de analytics para seguimiento de rendimiento
  final AnalyticsService? _analytics;
  
  /// Controlador del estado de la conexión
  final StreamController<SocketConnectionState> _connectionStateController = 
      StreamController<SocketConnectionState>.broadcast();
  
  /// Stream de cambios en el estado de conexión
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  
  /// Estado actual de la conexión
  SocketConnectionState _currentState = SocketConnectionState.disconnected;
  
  /// Obtener el estado actual de la conexión
  SocketConnectionState get currentState => _currentState;
  
  /// Si el socket está conectado
  bool get isConnected => currentState == SocketConnectionState.connected;
  
  /// Si el socket está conectando
  bool get isConnecting => currentState == SocketConnectionState.connecting;
  
  /// Si el socket está desconectado
  bool get isDisconnected => 
      currentState == SocketConnectionState.disconnected || 
      currentState == SocketConnectionState.disconnectedByUser || 
      currentState == SocketConnectionState.disconnectedByServer || 
      currentState == SocketConnectionState.error;

  /// Registro de eventos pendientes cuando está desconectado
  final List<_PendingEvent> _pendingEvents = [];
  
  /// Marca de tiempo de la última actividad
  int _lastActivityTimestamp = 0;
  
  /// Temporizador para verificar el estado de salud
  Timer? _healthCheckTimer;
  
  /// Tiempo de ping promedio (latencia)
  int _averagePingTime = 0;
  
  /// Historial de tiempos de ping para calcular promedios
  final List<int> _pingTimes = [];
  
  /// Recuento total de intentos de reconexión
  int _reconnectionAttempts = 0;
  
  /// Constructor
  SocketIOClient({
    required String serverUrl,
    Map<String, dynamic> options = const {},
    Logger? logger,
    AnalyticsService? analytics,
  }) : _serverUrl = serverUrl,
       _options = options,
       _logger = logger ?? Logger(),
       _analytics = analytics {
    // Iniciar verificación de estado
    _startHealthCheck();
  }
  
  /// Conectar al servidor WebSocket
  Future<void> connect() async {
    if (_socket != null) {
      _logger.d('Socket already exists, disconnecting first');
      await disconnect();
    }
    
    _updateConnectionState(SocketConnectionState.connecting);
    
    try {
      // Opciones de conexión predeterminadas
      final defaultOptions = {
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'timeout': 10000,
      };
      
      // Fusionar con opciones personalizadas
      final mergedOptions = {...defaultOptions, ..._options};
      
      // Crear instancia Socket.IO
      _socket = io.io(_serverUrl, mergedOptions);
      
      // Configurar manejadores de eventos
      _setupEventHandlers();
      
      // Conectar
      _socket!.connect();

      _logger.i('Socket.IO connecting to $_serverUrl');
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_connect_attempt',
          parameters: {'url': _serverUrl}
        );
      }
      
      // Actualizar timestamp de actividad
      _updateActivityTimestamp();
    } catch (e, stackTrace) {
      _logger.e('Error connecting to socket', error: e, stackTrace: stackTrace);
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logError(
          errorType: 'socket_connect_error',
          errorMessage: e.toString(),
          errorDetails: 'URL: $_serverUrl'
        );
      }
      
      rethrow;
    }
  }
  
  /// Desconectar del servidor WebSocket
  Future<void> disconnect() async {
    if (_socket != null) {
      _logger.d('Disconnecting socket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _updateConnectionState(SocketConnectionState.disconnectedByUser);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_disconnect',
          parameters: {'reason': 'user_request'}
        );
      }
    }
  }
  
  /// Configurar manejadores de eventos Socket.IO
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      _logger.i('Socket connected');
      _updateConnectionState(SocketConnectionState.connected);
      
      // Procesar eventos pendientes
      _processPendingEvents();
      
      // Medir latencia inicial
      _measureLatency();
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_connected',
          parameters: {'url': _serverUrl}
        );
      }
    });
    
    _socket?.onDisconnect((_) {
      _logger.i('Socket disconnected');
      if (currentState != SocketConnectionState.disconnectedByUser) {
        _updateConnectionState(SocketConnectionState.disconnectedByServer);
        
        if (_analytics != null) {
          _analytics!.logEvent(
            AnalyticsEvent.custom,
            customEventName: 'socket_disconnected',
            parameters: {'reason': 'server_disconnect'}
          );
        }
      }
    });
    
    _socket?.onConnectError((error) {
      _logger.e('Socket connect error: $error');
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logError(
          errorType: 'socket_connect_error',
          errorMessage: error.toString(),
          errorDetails: 'URL: $_serverUrl'
        );
      }
    });
    
    _socket?.onError((error) {
      _logger.e('Socket error: $error');
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logError(
          errorType: 'socket_error',
          errorMessage: error.toString()
        );
      }
    });
    
    _socket?.onReconnect((_) {
      _logger.i('Socket reconnected');
      _updateConnectionState(SocketConnectionState.connected);
      
      // Procesar eventos pendientes después de la reconexión
      _processPendingEvents();
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_reconnected',
          parameters: {}
        );
      }
    });
    
    // Usar el evento 'reconnect_attempt' que es el equivalente correcto
    _socket?.on('reconnect_attempt', (attempt) {
      _reconnectionAttempts++;
      _logger.i('Socket reconnecting (attempt: $attempt)');
      _updateConnectionState(SocketConnectionState.reconnecting);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_reconnecting',
          parameters: {'attempt': attempt}
        );
      }
    });
    
    _socket?.onReconnectFailed((_) {
      _logger.e('Socket reconnect failed');
      _updateConnectionState(SocketConnectionState.error);
      
      if (_analytics != null) {
        _analytics!.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_reconnect_failed',
          parameters: {}
        );
      }
    });
    
    // Agregar manejador de ping-pong para medir latencia
    _socket?.on('pong', (data) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      if (data is Map && data.containsKey('start')) {
        final startTime = data['start'] as int;
        final latency = endTime - startTime;
        _recordPingTime(latency);
      }
    });
  }
  
  /// Actualizar estado de conexión
  void _updateConnectionState(SocketConnectionState state) {
    if (!_connectionStateController.isClosed && _currentState != state) {
      _logger.d('Socket state changed: $state');
      _currentState = state;
      _connectionStateController.add(_currentState);
      _updateActivityTimestamp();
    }
  }
  
  /// Actualizar marca de tiempo de la última actividad
  void _updateActivityTimestamp() {
    _lastActivityTimestamp = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Registrar un oyente para eventos de socket
  Stream<T> on<T>(String event) {
    final controller = StreamController<T>.broadcast();
    
    if (_socket != null) {
      _socket!.on(event, (data) {
        _updateActivityTimestamp();
        if (!controller.isClosed) {
          controller.add(data as T);
        }
      });
    }
    
    controller.onCancel = () {
      _socket?.off(event);
    };
    
    return controller.stream;
  }
  
  /// Emitir un evento al servidor
  void emit(String event, [dynamic data]) {
    _updateActivityTimestamp();
    
    if (_socket != null && isConnected) {
      _logger.d('Emitting event: $event');
      _socket!.emit(event, data);
    } else {
      _logger.w('Cannot emit event: $event - Socket not connected');
      // Guardar evento para enviarlo cuando se conecte
      _pendingEvents.add(_PendingEvent(event, data));
    }
  }
  
  /// Emitir un evento y esperar un reconocimiento
  void emitWithAck(String event, dynamic data, {Function? ack}) {
    _updateActivityTimestamp();
    
    if (_socket != null && isConnected) {
      _logger.d('Emitting event with ack: $event');
      _socket!.emitWithAck(event, data, ack: ack);
    } else {
      _logger.w('Cannot emit event with ack: $event - Socket not connected');
      // No guardamos eventos con ack pendientes porque no podemos garantizar que se procesen correctamente
    }
  }
  
  /// Procesar eventos pendientes después de conectar
  void _processPendingEvents() {
    if (_pendingEvents.isEmpty) return;
    
    _logger.d('Processing ${_pendingEvents.length} pending events');
    
    // Procesar todos los eventos pendientes
    final eventsToProcess = List<_PendingEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    
    // Emit each pending event
    for (final pendingEvent in eventsToProcess) {
      emit(pendingEvent.event, pendingEvent.data);
    }
  }
  
  /// Medir latencia actual
  void _measureLatency() {
    if (!isConnected || _socket == null) return;
    
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Usar el mecanismo de ping-pong de socket.io
    _socket!.emit('ping', {'start': startTime});
  }
  
  /// Registrar tiempo de ping para cálculos de latencia
  void _recordPingTime(int pingTime) {
    _pingTimes.add(pingTime);
    
    // Mantener solo los últimos 10 valores
    if (_pingTimes.length > 10) {
      _pingTimes.removeAt(0);
    }
    
    // Calcular promedio
    if (_pingTimes.isNotEmpty) {
      final sum = _pingTimes.reduce((a, b) => a + b);
      _averagePingTime = sum ~/ _pingTimes.length;
    }
    
    // Registrar latencia alta
    if (pingTime > 300 && _analytics != null) {
      _analytics!.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_high_latency',
        parameters: {'latency_ms': pingTime}
      );
    }
  }
  
  /// Iniciar verificación periódica de estado
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performHealthCheck();
    });
  }
  
  /// Realizar verificación de estado
  void _performHealthCheck() {
    // Solo verificar si estamos conectados
    if (!isConnected) return;
    
    // Verificar inactividad
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastActivity = currentTime - _lastActivityTimestamp;
    
    // Si no ha habido actividad en 2 minutos, medir latencia
    if (timeSinceLastActivity > 120000) {
      _measureLatency();
    }
    
    // Registrar estadísticas de rendimiento si analytics está disponible
    if (_analytics != null && _reconnectionAttempts > 0) {
      _analytics!.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_performance_stats',
        parameters: {
          'avg_latency': _averagePingTime,
          'reconnection_attempts': _reconnectionAttempts,
          'connection_uptime': currentTime - _lastActivityTimestamp,
        }
      );
    }
  }
  
  /// Entrar en modo de fondo para reducir el uso de recursos
  void enterBackgroundMode() {
    _logger.d('Entering background mode');
    // Desconectar para ahorrar batería, guardar eventos pendientes
    disconnect();
  }
  
  /// Entrar en modo de primer plano para restaurar la operación normal
  void enterForegroundMode() {
    _logger.d('Entering foreground mode');
    // Reconectar si estábamos conectados anteriormente
    connect();
  }
  
  /// Obtener la latencia promedio actual (ping)
  int get averageLatency => _averagePingTime;
  
  /// Obtener el número total de intentos de reconexión
  int get totalReconnectionAttempts => _reconnectionAttempts;
  
  /// Liberar recursos
  void dispose() {
    _logger.d('Disposing SocketIOClient');
    disconnect();
    _connectionStateController.close();
    _healthCheckTimer?.cancel();
  }
}

/// Clase para mantener eventos pendientes
class _PendingEvent {
  final String event;
  final dynamic data;
  
  _PendingEvent(this.event, this.data);
} 