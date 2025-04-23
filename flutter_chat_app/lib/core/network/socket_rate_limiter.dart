import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:injectable/injectable.dart';

/// Resultado de verificación de límite de tasa
class RateLimitResult {
  /// Si se permite el evento
  final bool allowed;
  
  /// Información adicional sobre el límite
  final Map<String, dynamic> info;
  
  /// Constructor para resultado permitido
  RateLimitResult.allowed()
      : allowed = true,
        info = {'status': 'allowed'};
  
  /// Constructor para resultado limitado
  RateLimitResult.limited(int currentCount, int maxAllowed, int timeWindowMs)
      : allowed = false,
        info = {
          'status': 'limited',
          'current_count': currentCount,
          'max_allowed': maxAllowed,
          'time_window_ms': timeWindowMs,
          'retry_after_ms': timeWindowMs,
        };
  
  /// Constructor para evento bloqueado
  RateLimitResult.blocked()
      : allowed = false,
        info = {'status': 'blocked'};
}

/// Información sobre el límite de tasa para un tipo de evento
class RateLimitInfo {
  /// Número máximo permitido
  final int maxEvents;
  
  /// Ventana de tiempo (ms)
  final int timeWindowMs;
  
  /// Conteo actual
  final int currentCount;
  
  /// Marca de tiempo del próximo restablecimiento
  final int nextResetTimestamp;
  
  /// Constructor
  RateLimitInfo({
    required this.maxEvents,
    required this.timeWindowMs,
    required this.currentCount,
    required this.nextResetTimestamp,
  });
  
  /// Convierte a Map para serialización
  Map<String, dynamic> toMap() {
    return {
      'max_events': maxEvents,
      'time_window_ms': timeWindowMs,
      'current_count': currentCount,
      'next_reset_ms': nextResetTimestamp - DateTime.now().millisecondsSinceEpoch,
      'limit_percent': (currentCount / maxEvents * 100).round(),
    };
  }
}

/// Implementación de limitador de tasa para eventos de socket
class SocketRateLimiter {
  /// Máximo de eventos por período predeterminado
  final int _defaultMaxEvents;
  
  /// Ventana de tiempo predeterminada (ms)
  final int _defaultTimeWindowMs;
  
  /// Historial de eventos por tipo
  final Map<String, Queue<int>> _eventHistory = {};
  
  /// Límites personalizados por tipo de evento
  final Map<String, _RateLimit> _customLimits = {};
  
  /// Eventos bloqueados explícitamente
  final Set<String> _blockedEvents = {};
  
  /// Cola de mensajes por tipo de evento
  final Map<String, Queue<_QueuedMessage>> _messageQueues = {};
  
  /// Temporizadores para procesar colas
  final Map<String, DateTime> _queueProcessingTimers = {};
  
  /// Constructor
  SocketRateLimiter({
    int maxEvents = 30,
    int timeWindowMs = 1000,
  })  : _defaultMaxEvents = maxEvents,
        _defaultTimeWindowMs = timeWindowMs;
  
  /// Verificar si un evento debe ser limitado
  RateLimitResult checkRateLimit(String eventType) {
    // Verificar si está bloqueado
    if (_blockedEvents.contains(eventType)) {
      return RateLimitResult.blocked();
    }
    
    // Limpiar eventos antiguos
    _cleanupOldEvents(eventType);
    
    // Obtener límite para este tipo
    final rateLimit = _getLimitForEventType(eventType);
    
    // Verificar conteo actual
    final currentCount = _getCurrentCount(eventType);
    
    if (currentCount >= rateLimit.maxEvents) {
      return RateLimitResult.limited(
        currentCount,
        rateLimit.maxEvents,
        rateLimit.timeWindowMs,
      );
    }
    
    return RateLimitResult.allowed();
  }
  
  /// Registrar un evento
  void recordEvent(String eventType) {
    if (!_eventHistory.containsKey(eventType)) {
      _eventHistory[eventType] = Queue<int>();
    }
    
    _eventHistory[eventType]!.add(DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Registrar un mensaje (para estadísticas)
  void recordMessage(String eventType) {
    recordEvent(eventType);
  }
  
  /// Poner en cola un mensaje para enviarlo más tarde si está limitado
  void enqueueMessage(String eventType, dynamic data, Function(dynamic) sendCallback) {
    if (!_messageQueues.containsKey(eventType)) {
      _messageQueues[eventType] = Queue<_QueuedMessage>();
    }
    
    final message = _QueuedMessage(
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sendCallback: sendCallback,
    );
    
    _messageQueues[eventType]!.add(message);
    
    // Programar procesamiento de cola
    _scheduleQueueProcessing(eventType);
  }
  
  /// Programar procesamiento de cola
  void _scheduleQueueProcessing(String eventType) {
    // Si ya hay un temporizador programado y aún no ha vencido, no hacer nada
    final now = DateTime.now();
    if (_queueProcessingTimers.containsKey(eventType) && 
        _queueProcessingTimers[eventType]!.isAfter(now)) {
      return;
    }
    
    // Calcular tiempo para procesar el siguiente mensaje
    final rateLimit = _getLimitForEventType(eventType);
    final currentCount = _getCurrentCount(eventType);
    
    if (currentCount < rateLimit.maxEvents) {
      // Podemos procesar inmediatamente
      _processQueue(eventType);
      return;
    }
    
    // Calcular tiempo para el próximo procesamiento
    final oldestTimestamp = _getOldestEventTimestamp(eventType);
    final nextProcessTime = oldestTimestamp + rateLimit.timeWindowMs;
    
    // Actualizar el temporizador
    _queueProcessingTimers[eventType] = DateTime.fromMillisecondsSinceEpoch(nextProcessTime);
    
    // Programar el procesamiento
    Future.delayed(
      Duration(milliseconds: nextProcessTime - now.millisecondsSinceEpoch + 10),
      () => _processQueue(eventType),
    );
  }
  
  /// Procesar cola de mensajes
  void _processQueue(String eventType) {
    if (!_messageQueues.containsKey(eventType) || 
        _messageQueues[eventType]!.isEmpty) {
      return;
    }
    
    final queue = _messageQueues[eventType]!;
    
    // Intentar enviar mensajes de la cola mientras esté permitido
    while (queue.isNotEmpty) {
      if (checkRateLimit(eventType).allowed) {
        final message = queue.removeFirst();
        recordEvent(eventType);
        message.sendCallback(message.data);
      } else {
        break;
      }
    }
    
    // Si aún quedan mensajes, reprogramar
    if (queue.isNotEmpty) {
      _scheduleQueueProcessing(eventType);
    }
  }
  
  /// Establecer un límite de tasa personalizado para un tipo de evento
  void setCustomRateLimit(String eventType, int maxEvents, int timeWindowMs) {
    _customLimits[eventType] = _RateLimit(
      maxEvents: maxEvents, 
      timeWindowMs: timeWindowMs
    );
    
    // Limpiar historial existente
    if (_eventHistory.containsKey(eventType)) {
      _eventHistory[eventType]!.clear();
    }
  }
  
  /// Bloquear un tipo de evento específico
  void blockEvent(String eventType) {
    _blockedEvents.add(eventType);
  }
  
  /// Desbloquear un tipo de evento
  void unblockEvent(String eventType) {
    _blockedEvents.remove(eventType);
  }
  
  /// Obtener información sobre el límite de tasa actual
  RateLimitInfo getRateLimitInfo(String eventType) {
    _cleanupOldEvents(eventType);
    
    final rateLimit = _getLimitForEventType(eventType);
    final currentCount = _getCurrentCount(eventType);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Calcular cuándo se restablecerá el límite
    int nextResetTimestamp = now + rateLimit.timeWindowMs;
    
    if (_eventHistory.containsKey(eventType) && _eventHistory[eventType]!.isNotEmpty) {
      final oldestTimestamp = _eventHistory[eventType]!.first;
      nextResetTimestamp = oldestTimestamp + rateLimit.timeWindowMs;
    }
    
    return RateLimitInfo(
      maxEvents: rateLimit.maxEvents,
      timeWindowMs: rateLimit.timeWindowMs,
      currentCount: currentCount,
      nextResetTimestamp: nextResetTimestamp,
    );
  }
  
  /// Comprobar si se debe limitar
  bool shouldLimit(String eventType) {
    return !checkRateLimit(eventType).allowed;
  }
  
  /// Obtener el límite configurado para un tipo de evento
  _RateLimit _getLimitForEventType(String eventType) {
    return _customLimits[eventType] ?? 
           _RateLimit(maxEvents: _defaultMaxEvents, timeWindowMs: _defaultTimeWindowMs);
  }
  
  /// Obtener el conteo actual para un tipo de evento
  int _getCurrentCount(String eventType) {
    return _eventHistory[eventType]?.length ?? 0;
  }
  
  /// Obtener el timestamp del evento más antiguo
  int _getOldestEventTimestamp(String eventType) {
    if (!_eventHistory.containsKey(eventType) || _eventHistory[eventType]!.isEmpty) {
      return 0;
    }
    return _eventHistory[eventType]!.first;
  }
  
  /// Limpiar eventos antiguos fuera de la ventana de tiempo
  void _cleanupOldEvents(String eventType) {
    if (!_eventHistory.containsKey(eventType)) return;
    
    final queue = _eventHistory[eventType]!;
    if (queue.isEmpty) return;
    
    final rateLimit = _getLimitForEventType(eventType);
    final cutoffTime = DateTime.now().millisecondsSinceEpoch - rateLimit.timeWindowMs;
    
    // Eliminar eventos antiguos
    while (queue.isNotEmpty && queue.first < cutoffTime) {
      queue.removeFirst();
    }
  }
  
  /// Reiniciar todos los contadores
  void reset() {
    _eventHistory.clear();
    _queueProcessingTimers.clear();
    
    // Mantener los límites personalizados y bloqueos
  }
}

/// Clase interna para definir un límite de tasa
class _RateLimit {
  final int maxEvents;
  final int timeWindowMs;
  
  _RateLimit({required this.maxEvents, required this.timeWindowMs});
}

/// Clase interna para mensajes en cola
class _QueuedMessage {
  final dynamic data;
  final int timestamp;
  final Function(dynamic) sendCallback;
  
  _QueuedMessage({
    required this.data, 
    required this.timestamp, 
    required this.sendCallback
  });
} 