import 'dart:collection';

/// Calidad de la conexión basada en diferentes métricas
enum SocketQuality {
  /// Excelente calidad, latencia baja, sin pérdida de paquetes
  excellent,
  
  /// Buena calidad, latencia aceptable
  good,
  
  /// Calidad regular, latencia alta pero usable
  fair,
  
  /// Calidad pobre, problemas de conexión
  poor,
  
  /// Sin conexión o calidad muy baja
  critical,
  
  /// Calidad desconocida (estado inicial)
  unknown,
}

/// Monitorea la calidad de conexión del socket basándose en diferentes métricas
class SocketQualityMonitor {
  /// Número máximo de muestras de latencia a mantener
  static const int _maxLatencyMeasurements = 20;
  
  /// Muestras de latencia (ms)
  final Queue<int> _latencyMeasurements = Queue<int>();
  
  /// Contador de paquetes perdidos
  int _packetLossCount = 0;
  
  /// Tiempo de la última actualización de métrica
  int _lastUpdateTime = 0;
  
  /// Calidad actual de la conexión
  SocketQuality _currentQuality = SocketQuality.unknown;
  
  /// Obtener la calidad actual
  SocketQuality get currentQuality => _currentQuality;
  
  /// Obtener la latencia promedio
  double get averageLatency {
    if (_latencyMeasurements.isEmpty) return 0;
    final sum = _latencyMeasurements.reduce((a, b) => a + b);
    return sum / _latencyMeasurements.length;
  }
  
  /// Obtener la latencia mínima
  int get minLatency {
    if (_latencyMeasurements.isEmpty) return 0;
    return _latencyMeasurements.reduce((a, b) => a < b ? a : b);
  }
  
  /// Obtener la latencia máxima
  int get maxLatency {
    if (_latencyMeasurements.isEmpty) return 0;
    return _latencyMeasurements.reduce((a, b) => a > b ? a : b);
  }
  
  /// Obtener tasa de pérdida de paquetes (%)
  double get packetLossRate {
    final totalMeasurements = _latencyMeasurements.length + _packetLossCount;
    if (totalMeasurements == 0) return 0;
    return (_packetLossCount / totalMeasurements) * 100;
  }
  
  /// Añadir una nueva medición de latencia
  void addLatencyMeasurement(int latencyMs) {
    _latencyMeasurements.add(latencyMs);
    
    // Limitar el número de mediciones
    if (_latencyMeasurements.length > _maxLatencyMeasurements) {
      _latencyMeasurements.removeFirst();
    }
    
    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Incrementar el contador de pérdida de paquetes
  void incrementPacketLoss() {
    _packetLossCount++;
    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Actualizar métricas y recalcular calidad
  void updateMetrics() {
    // Si no hay mediciones, la calidad es desconocida
    if (_latencyMeasurements.isEmpty) {
      _currentQuality = SocketQuality.unknown;
      return;
    }
    
    // Calcular latencia promedio
    final avgLatency = averageLatency;
    
    // Calcular tasa de pérdida
    final lossRate = packetLossRate;
    
    // Determinar calidad basada en latencia y pérdida
    if (avgLatency < 100 && lossRate < 0.1) {
      _currentQuality = SocketQuality.excellent;
    } else if (avgLatency < 200 && lossRate < 0.5) {
      _currentQuality = SocketQuality.good;
    } else if (avgLatency < 500 && lossRate < 2) {
      _currentQuality = SocketQuality.fair;
    } else if (avgLatency < 1000 && lossRate < 5) {
      _currentQuality = SocketQuality.poor;
    } else {
      _currentQuality = SocketQuality.critical;
    }
  }
  
  /// Reiniciar todas las métricas
  void resetMetrics() {
    _latencyMeasurements.clear();
    _packetLossCount = 0;
    _currentQuality = SocketQuality.unknown;
    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Obtener un resumen de las métricas actuales
  Map<String, dynamic> getSummary() {
    return {
      'quality': _currentQuality.toString(),
      'latency': {
        'average': averageLatency,
        'min': minLatency,
        'max': maxLatency,
        'samples': _latencyMeasurements.length,
      },
      'packetLoss': {
        'count': _packetLossCount,
        'rate': packetLossRate,
      },
      'lastUpdate': _lastUpdateTime,
    };
  }
} 