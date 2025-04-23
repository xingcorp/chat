import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../monitoring/analytics_service.dart';
import '../monitoring/logger_service.dart';
import 'models/socket_connection_state.dart';
import 'socket_quality_monitor.dart';
import 'socket_rate_limiter.dart';

/// Opciones de configuración para el cliente socket avanzado
class AdvancedSocketOptions {
  /// URL del servidor
  final String serverUrl;
  
  /// Opciones personalizadas para Socket.IO
  final Map<String, dynamic> socketOptions;
  
  /// Máximo de eventos por segundo (rate limiting)
  final int maxEventsPerSecond;
  
  /// Intervalo de comprobación de calidad (ms)
  final int qualityCheckIntervalMs;
  
  /// Tiempo de reconexión base (ms)
  final int reconnectionDelayMs;
  
  /// Intentos máximos de reconexión
  final int maxReconnectionAttempts;
  
  /// Tiempo de espera para ack (ms)
  final int ackTimeoutMs;
  
  const AdvancedSocketOptions({
    required this.serverUrl,
    this.socketOptions = const {},
    this.maxEventsPerSecond = 50,
    this.qualityCheckIntervalMs = 5000,
    this.reconnectionDelayMs = 1000,
    this.maxReconnectionAttempts = 10,
    this.ackTimeoutMs = 10000,
  });
}

/// Resultado de una operación de emisión con ack
class SocketResponse<T> {
  /// Datos de respuesta
  final T? data;
  
  /// Error (si ocurrió)
  final SocketError? error;
  
  /// Tiempo de respuesta (ms)
  final int responseTimeMs;
  
  /// Constructor para respuesta exitosa
  SocketResponse.success(this.data, this.responseTimeMs) : error = null;
  
  /// Constructor para respuesta con error
  SocketResponse.error(this.error, this.responseTimeMs) : data = null;
  
  /// Verifica si la respuesta fue exitosa
  bool get isSuccess => error == null;
}

/// Cliente WebSocket avanzado con monitoreo de rendimiento, reconexión automática,
/// monitoreo de calidad, limitación de tasa, y manejo eficiente de eventos
@injectable
class AdvancedSocketClient {
  /// Instancia Socket.io
  Socket? _socket;
  
  /// Opciones de configuración
  final AdvancedSocketOptions _options;
  
  /// Servicio de registro
  final LoggerService _logger;
  
  /// Servicio de analytics
  final AnalyticsService _analytics;
  
  /// Monitor de calidad de conexión
  late final SocketQualityMonitor _qualityMonitor;
  
  /// Limitador de tasa para eventos salientes
  late final SocketRateLimiter _rateLimiter;
  
  /// Estado actual de conexión
  SocketConnectionState _connectionState = SocketConnectionState.disconnected;
  
  /// Eventos pendientes a enviar cuando se establezca la conexión
  final List<_PendingEvent> _pendingEvents = [];
  
  /// Suscripciones activas para eventos
  final Map<String, List<StreamSubscription>> _eventSubscriptions = {};
  
  /// Cronómetros activos
  final List<Timer> _timers = [];
  
  /// Controlador para cambios de estado de conexión
  final StreamController<SocketConnectionState> _connectionStateController = 
      StreamController<SocketConnectionState>.broadcast();
  
  /// Stream de cambios en el estado de conexión
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  
  /// Controlador para cambios de calidad de conexión
  final StreamController<SocketQuality> _qualityController = 
      StreamController<SocketQuality>.broadcast();
      
  /// Stream de cambios en la calidad de conexión
  Stream<SocketQuality> get qualityStream => _qualityController.stream;
  
  /// Controlador para errores
  final StreamController<SocketError> _errorController = 
      StreamController<SocketError>.broadcast();
      
  /// Stream de errores
  Stream<SocketError> get errorStream => _errorController.stream;
  
  /// Constructor del cliente socket avanzado
  AdvancedSocketClient({
    required AdvancedSocketOptions options,
    required LoggerService logger,
    required AnalyticsService analytics,
  }) : _options = options,
       _logger = logger,
       _analytics = analytics {
    // Inicializar el monitor de calidad
    _qualityMonitor = SocketQualityMonitor();
    
    // Inicializar el limitador de tasa
    _rateLimiter = SocketRateLimiter(
      maxEvents: options.maxEventsPerSecond,
      timeWindowMs: 1000, // 1 segundo
    );
    
    // Iniciar comprobación periódica de calidad
    _startQualityCheck();
  }
  
  /// Conectar al servidor socket
  Future<bool> connect() async {
    if (_socket != null) {
      _logger.debug('Socket already exists, disconnecting first');
      disconnect();
    }
    
    _updateConnectionState(SocketConnectionState.connecting);
    
    try {
      _logger.info('Connecting to socket server: ${_options.serverUrl}');
      
      // Opciones predeterminadas
      final defaultOptions = {
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': _options.maxReconnectionAttempts,
        'reconnectionDelay': _options.reconnectionDelayMs,
        'reconnectionDelayMax': _options.reconnectionDelayMs * 5,
        'timeout': _options.ackTimeoutMs,
      };
      
      // Fusionar con opciones de usuario
      final mergedOptions = {...defaultOptions, ..._options.socketOptions};
      
      // Crear y conectar socket
      _socket = io(_options.serverUrl, mergedOptions);
      
      // Configurar manejadores de eventos
      _setupEventHandlers();
      
      // Iniciar monitoreo de rendimiento
      _startPerformanceMonitoring();
      
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error connecting to socket server', e, stackTrace);
      _analytics.logError(
        errorType: 'socket_connection_error',
        errorMessage: e.toString(),
        errorDetails: 'URL: ${_options.serverUrl}'
      );
      
      _updateConnectionState(SocketConnectionState.error);
      _notifyError(
        SocketErrorType.networkError,
        'Failed to connect: $e'
      );
      
      return false;
    }
  }
  
  /// Desconectar del servidor socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateConnectionState(SocketConnectionState.disconnectedByUser);
    _logger.info('Disconnected from socket server');
  }
  
  /// Configurar manejadores de eventos socket
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      _logger.info('Socket connected');
      _updateConnectionState(SocketConnectionState.connected);
      _processPendingEvents();
      
      // Enviar ping para medir latencia inicial
      _measureLatency();
      
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_connected',
        parameters: {'url': _options.serverUrl}
      );
    });
    
    _socket?.onDisconnect((_) {
      _logger.info('Socket disconnected');
      if (_connectionState != SocketConnectionState.disconnectedByUser) {
        _updateConnectionState(SocketConnectionState.disconnectedByServer);
        
        _analytics.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_disconnected',
          parameters: {'reason': 'server_disconnect'}
        );
      }
    });
    
    _socket?.onConnectError((error) {
      _logger.error('Socket connection error', error);
      _updateConnectionState(SocketConnectionState.error);
      
      _notifyError(
        SocketErrorType.networkError,
        'Connection error: $error'
      );
      
      _analytics.logError(
        errorType: 'socket_connection_error',
        errorMessage: error.toString(),
        errorDetails: 'URL: ${_options.serverUrl}'
      );
    });
    
    _socket?.onError((error) {
      _logger.error('Socket error', error);
      
      _notifyError(
        SocketErrorType.unknown,
        'Socket error: $error'
      );
      
      _analytics.logError(
        errorType: 'socket_error',
        errorMessage: error.toString()
      );
    });
    
    // Usar el evento 'reconnect_attempt' en lugar de onReconnecting
    _socket?.on('reconnect_attempt', (attempt) {
      _logger.info('Socket reconnecting (attempt: $attempt)');
      _updateConnectionState(SocketConnectionState.reconnecting);
      
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_reconnecting',
        parameters: {'attempt': attempt}
      );
    });
    
    _socket?.onReconnect((_) {
      _logger.info('Socket reconnected');
      _updateConnectionState(SocketConnectionState.connected);
      _processPendingEvents();
      
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_reconnected',
        parameters: {}
      );
    });
    
    _socket?.onReconnectFailed((_) {
      _logger.error('Socket reconnect failed');
      _updateConnectionState(SocketConnectionState.error);
      
      _notifyError(
        SocketErrorType.networkError,
        'Reconnection attempts failed'
      );
      
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_reconnect_failed',
        parameters: {}
      );
    });
  }
  
  /// Iniciar monitoreo de rendimiento
  void _startPerformanceMonitoring() {
    final timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_connectionState == SocketConnectionState.connected) {
        _measureLatency();
      }
    });
    
    _timers.add(timer);
  }
  
  /// Iniciar comprobación periódica de calidad
  void _startQualityCheck() {
    final timer = Timer.periodic(
      Duration(milliseconds: _options.qualityCheckIntervalMs), 
      (_) => _checkConnectionQuality()
    );
    
    _timers.add(timer);
  }
  
  /// Medir latencia actual
  void _measureLatency() {
    if (_connectionState != SocketConnectionState.connected || _socket == null) return;
    
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Usar característica de ping de socket.io
    _socket!.emit('ping', (_) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final latency = endTime - startTime;
      
      _qualityMonitor.addLatencyMeasurement(latency);
      
      // Registrar latencia muy alta
      if (latency > 500) {
        _analytics.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_high_latency',
          parameters: {'value': latency}
        );
      }
    });
  }
  
  /// Comprobar calidad de conexión y notificar cambios
  void _checkConnectionQuality() {
    if (_connectionState != SocketConnectionState.connected) return;
    
    // Obtener calidad actual
    final oldQuality = _qualityMonitor.currentQuality;
    
    // Actualizar calidad (recalculará según mediciones recientes)
    _qualityMonitor.updateMetrics();
    
    // Obtener nueva calidad
    final newQuality = _qualityMonitor.currentQuality;
    
    // Si cambió la calidad, notificar
    if (oldQuality != newQuality) {
      _qualityController.add(newQuality);
      
      // Registrar cambios de calidad (excepto conexión inicial)
      if (oldQuality != SocketQuality.unknown) {
        _analytics.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_quality_change',
          parameters: {
            'from': oldQuality.toString(),
            'to': newQuality.toString(),
            'metrics': _qualityMonitor.getSummary(),
          }
        );
      }
    }
  }
  
  /// Registrar un listener para eventos socket
  StreamSubscription<T> on<T>(String event, void Function(T data) callback) {
    final controller = StreamController<T>.broadcast();
    
    // Suscribirse al evento socket
    if (_socket != null) {
      _socket!.on(event, (data) {
        try {
          if (!controller.isClosed) {
            controller.add(data as T);
          }
        } catch (e, stackTrace) {
          _logger.error('Error in socket event handler: $event', e, stackTrace);
        }
      });
    }
    
    // Crear suscripción
    final subscription = controller.stream.listen((data) {
      try {
        callback(data);
      } catch (e, stackTrace) {
        _logger.error('Error in event callback: $event', e, stackTrace);
      }
    });
    
    // Guardar suscripción para limpieza
    _eventSubscriptions[event] = [...(_eventSubscriptions[event] ?? []), subscription];
    
    // Configurar limpieza al cancelar
    subscription.onDone(() {
      controller.close();
      _eventSubscriptions[event]?.remove(subscription);
    });
    
    return subscription;
  }
  
  /// Quitar un listener para eventos socket
  void off(String event) {
    _socket?.off(event);
    
    // Cancelar todas las suscripciones
    _eventSubscriptions[event]?.forEach((subscription) {
      subscription.cancel();
    });
    
    _eventSubscriptions.remove(event);
  }
  
  /// Emitir un evento al servidor
  bool emit(String event, dynamic data) {
    if (_connectionState != SocketConnectionState.connected) {
      _logger.debug('Socket not connected, adding event to pending list: $event');
      _pendingEvents.add(_PendingEvent(event, data));
      return false;
    }
    
    // Comprobar limitación de tasa
    if (_rateLimiter.shouldLimit(event)) {
      _logger.warning('Rate limiting socket event: $event');
      
      _notifyError(
        SocketErrorType.rateLimited,
        'Rate limit exceeded for event: $event'
      );
      
      // Registrar eventos limitados
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_rate_limited',
        parameters: {'event': event}
      );
      
      return false;
    }
    
    try {
      // Registrar el evento para limitación de tasa
      _rateLimiter.recordEvent(event);
      
      // Emitir el evento
      _socket?.emit(event, data);
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error emitting socket event: $event', e, stackTrace);
      
      _notifyError(
        SocketErrorType.messagingError,
        'Failed to emit event: $e'
      );
      
      return false;
    }
  }
  
  /// Emitir un evento y obtener una respuesta
  Future<SocketResponse<T>> emitWithAck<T>(
    String event,
    dynamic data, {
    Duration? timeout
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    if (_connectionState != SocketConnectionState.connected) {
      return SocketResponse<T>.error(
        SocketError(
          type: SocketErrorType.networkError,
          message: 'Socket not connected',
        ),
        0
      );
    }
    
    // Comprobar limitación de tasa
    if (_rateLimiter.shouldLimit(event)) {
      _logger.warning('Rate limiting socket event with ack: $event');
      
      return SocketResponse<T>.error(
        SocketError(
          type: SocketErrorType.rateLimited,
          message: 'Rate limit exceeded for event: $event',
        ),
        0
      );
    }
    
    try {
      // Registrar el evento para limitación de tasa
      _rateLimiter.recordEvent(event);
      
      final timeoutDuration = timeout ?? Duration(milliseconds: _options.ackTimeoutMs);
      final completer = Completer<SocketResponse<T>>();
      
      // Configurar timeout
      final timeoutTimer = Timer(timeoutDuration, () {
        if (!completer.isCompleted) {
          final responseTime = DateTime.now().millisecondsSinceEpoch - startTime;
          
          completer.complete(SocketResponse<T>.error(
            SocketError(
              type: SocketErrorType.timeout,
              message: 'Timeout waiting for response',
            ),
            responseTime
          ));
          
          // Registrar timeouts para análisis
          _analytics.logEvent(
            AnalyticsEvent.custom,
            customEventName: 'socket_ack_timeout',
            parameters: {'event': event}
          );
          
          // Incrementar contador de pérdida de paquetes
          _qualityMonitor.incrementPacketLoss();
        }
      });
      
      // Emitir con reconocimiento
      _socket?.emitWithAck(event, data, ack: (response) {
        if (!completer.isCompleted) {
          final responseTime = DateTime.now().millisecondsSinceEpoch - startTime;
          timeoutTimer.cancel();
          
          if (response is Map && response.containsKey('error')) {
            final error = SocketError(
              type: SocketErrorType.serverError,
              message: response['error'] is String 
                ? response['error'] 
                : 'Server error',
              details: response['error']
            );
            
            completer.complete(SocketResponse<T>.error(error, responseTime));
          } else {
            completer.complete(SocketResponse<T>.success(response as T, responseTime));
          }
        }
      });
      
      return await completer.future;
    } catch (e, stackTrace) {
      final responseTime = DateTime.now().millisecondsSinceEpoch - startTime;
      
      _logger.error('Error emitting socket event with ack: $event', e, stackTrace);
      
      return SocketResponse<T>.error(
        SocketError(
          type: SocketErrorType.unknown,
          message: 'Error: $e',
        ),
        responseTime
      );
    }
  }
  
  /// Procesar eventos pendientes de envío durante desconexión
  void _processPendingEvents() {
    if (_pendingEvents.isEmpty) return;
    
    _logger.debug('Processing ${_pendingEvents.length} pending events');
    
    // Procesar todos los eventos pendientes
    final events = List<_PendingEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    
    for (final event in events) {
      emit(event.name, event.data);
    }
  }
  
  /// Actualizar estado de conexión y notificar
  void _updateConnectionState(SocketConnectionState state) {
    if (_connectionState == state) return;
    
    _connectionState = state;
    _connectionStateController.add(state);
    
    // Si se desconectó, actualizar calidad
    if (state == SocketConnectionState.disconnected || 
        state == SocketConnectionState.disconnectedByServer ||
        state == SocketConnectionState.disconnectedByUser) {
      _qualityMonitor.resetMetrics();
      _qualityController.add(SocketQuality.unknown);
    }
  }
  
  /// Notificar un error
  void _notifyError(SocketErrorType type, String message, {dynamic details}) {
    final error = SocketError(
      type: type,
      message: message,
      details: details,
    );
    
    _errorController.add(error);
  }
  
  /// Obtener el estado actual de conexión
  SocketConnectionState get currentState => _connectionState;
  
  /// Verificar si el socket está conectado
  bool get isConnected => 
      _connectionState == SocketConnectionState.connected;
  
  /// Obtener la calidad actual de conexión
  SocketQuality get currentQuality => _qualityMonitor.currentQuality;
  
  /// Establecer límite de tasa para un evento específico
  void setEventRateLimit(String event, int maxPerSecond) {
    _rateLimiter.setCustomRateLimit(event, maxPerSecond, 1000);
  }
  
  /// Bloquear un evento específico
  void blockEvent(String event) {
    _rateLimiter.blockEvent(event);
  }
  
  /// Desbloquear un evento previamente bloqueado
  void unblockEvent(String event) {
    _rateLimiter.unblockEvent(event);
  }
  
  /// Entrar en modo de fondo (ahorra batería)
  void enterBackgroundMode() {
    _logger.debug('Entering background mode');
    
    // Cancelar timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    // Desconectar para ahorrar batería (opcional)
    if (isConnected) {
      disconnect();
    }
  }
  
  /// Salir del modo de fondo
  void enterForegroundMode() {
    _logger.debug('Entering foreground mode');
    
    // Reactivar timers
    _startQualityCheck();
    _startPerformanceMonitoring();
    
    // Reconectar si es necesario
    if (_connectionState != SocketConnectionState.connected &&
        _connectionState != SocketConnectionState.connecting) {
      connect();
    }
  }
  
  /// Liberar recursos
  void dispose() {
    _logger.debug('Disposing AdvancedSocketClient');
    
    // Desconectar socket
    disconnect();
    
    // Cancelar todos los timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    // Cancelar todas las suscripciones de eventos
    for (final subscriptions in _eventSubscriptions.values) {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    }
    _eventSubscriptions.clear();
    
    // Cerrar controladores
    _connectionStateController.close();
    _qualityController.close();
    _errorController.close();
  }
}

/// Representa un evento pendiente para enviar cuando se establezca la conexión
class _PendingEvent {
  final String name;
  final dynamic data;
  
  _PendingEvent(this.name, this.data);
}

/// Error relacionado con el socket
class SocketError {
  /// Tipo de error
  final SocketErrorType type;
  
  /// Mensaje de error
  final String message;
  
  /// Detalles adicionales
  final dynamic details;
  
  /// Marca de tiempo cuando ocurrió
  final DateTime timestamp;
  
  /// Constructor
  SocketError({
    required this.type,
    required this.message,
    this.details,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() => 'SocketError($type): $message';
}

/// Tipos de errores socket
enum SocketErrorType {
  /// Error de red
  networkError,
  
  /// Timeout
  timeout,
  
  /// Error de autenticación
  authError,
  
  /// Limitación de tasa
  rateLimited,
  
  /// Error desde el servidor
  serverError,
  
  /// Error al enviar mensaje
  messagingError,
  
  /// Error desconocido
  unknown,
} 