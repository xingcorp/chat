import 'dart:math';

/// Represents the quality of a socket connection
enum SocketConnectionQuality {
  /// Connection is excellent with low latency and high reliability
  excellent,
  
  /// Connection is good with acceptable latency and reliability
  good,
  
  /// Connection has moderate issues with latency or reliability
  fair,
  
  /// Connection has significant issues with latency or reliability
  poor,
  
  /// Connection is barely usable with high latency or frequent drops
  critical,
  
  /// Connection is not available
  none
}

/// Manages the monitoring and analysis of socket connection quality
class SocketConnectionQualityMonitor {
  /// The current quality of the connection
  SocketConnectionQuality _currentQuality = SocketConnectionQuality.none;
  
  /// Recent latency measurements in milliseconds
  final List<int> _latencyMeasurements = [];
  
  /// Maximum number of latency measurements to store
  final int _maxMeasurements = 10;
  
  /// Recent packet loss rate (0.0 to 1.0)
  double _packetLossRate = 0.0;
  
  /// Recent connection stability score (0.0 to 1.0)
  double _stabilityScore = 1.0;
  
  /// Recent jitter measurements in milliseconds
  final List<int> _jitterMeasurements = [];
  
  /// Time of the last quality update
  DateTime _lastUpdate = DateTime.now();
  
  /// Get the current connection quality
  SocketConnectionQuality get quality => _currentQuality;
  
  /// Get the average latency in milliseconds
  int get averageLatency {
    if (_latencyMeasurements.isEmpty) return 0;
    return _latencyMeasurements.reduce((a, b) => a + b) ~/ _latencyMeasurements.length;
  }
  
  /// Get the current packet loss rate (0.0 to 1.0)
  double get packetLossRate => _packetLossRate;
  
  /// Get the current stability score (0.0 to 1.0)
  double get stabilityScore => _stabilityScore;
  
  /// Get the average jitter in milliseconds
  int get averageJitter {
    if (_jitterMeasurements.isEmpty) return 0;
    return _jitterMeasurements.reduce((a, b) => a + b) ~/ _jitterMeasurements.length;
  }
  
  /// Get time since last quality update in milliseconds
  int get timeSinceLastUpdate {
    return DateTime.now().difference(_lastUpdate).inMilliseconds;
  }
  
  /// Add a new latency measurement
  void addLatencyMeasurement(int latencyMs) {
    _latencyMeasurements.add(latencyMs);
    if (_latencyMeasurements.length > _maxMeasurements) {
      _latencyMeasurements.removeAt(0);
    }
    
    // Calculate jitter if we have at least 2 measurements
    if (_latencyMeasurements.length >= 2) {
      final jitter = (_latencyMeasurements.last - _latencyMeasurements[_latencyMeasurements.length - 2]).abs();
      _jitterMeasurements.add(jitter);
      if (_jitterMeasurements.length > _maxMeasurements) {
        _jitterMeasurements.removeAt(0);
      }
    }
    
    _updateQuality();
  }
  
  /// Update the packet loss rate
  void updatePacketLossRate(double rate) {
    _packetLossRate = max(0.0, min(1.0, rate));
    _updateQuality();
  }
  
  /// Update the stability score
  void updateStabilityScore(double score) {
    _stabilityScore = max(0.0, min(1.0, score));
    _updateQuality();
  }
  
  /// Set connection to disconnected state
  void setDisconnected() {
    _currentQuality = SocketConnectionQuality.none;
    _lastUpdate = DateTime.now();
  }
  
  /// Reset all metrics
  void reset() {
    _latencyMeasurements.clear();
    _jitterMeasurements.clear();
    _packetLossRate = 0.0;
    _stabilityScore = 1.0;
    _currentQuality = SocketConnectionQuality.none;
    _lastUpdate = DateTime.now();
  }
  
  /// Update the quality assessment based on current metrics
  void _updateQuality() {
    final avgLatency = averageLatency;
    final avgJitter = averageJitter;
    
    // Calculate a score based on all metrics (0-100)
    int score = 100;
    
    // Latency impact (0-40 points)
    if (avgLatency > 0) {
      if (avgLatency < 50) {
        // Excellent: 0-50ms
        score -= 0;
      } else if (avgLatency < 100) {
        // Good: 50-100ms
        score -= 10;
      } else if (avgLatency < 200) {
        // Fair: 100-200ms
        score -= 20;
      } else if (avgLatency < 500) {
        // Poor: 200-500ms
        score -= 30;
      } else {
        // Critical: >500ms
        score -= 40;
      }
    }
    
    // Packet loss impact (0-30 points)
    if (_packetLossRate > 0) {
      if (_packetLossRate < 0.01) {
        // Excellent: <1%
        score -= 0;
      } else if (_packetLossRate < 0.03) {
        // Good: 1-3%
        score -= 10;
      } else if (_packetLossRate < 0.08) {
        // Fair: 3-8%
        score -= 15;
      } else if (_packetLossRate < 0.15) {
        // Poor: 8-15%
        score -= 20;
      } else {
        // Critical: >15%
        score -= 30;
      }
    }
    
    // Stability impact (0-20 points)
    if (_stabilityScore < 1.0) {
      score -= (20 * (1.0 - _stabilityScore)).round();
    }
    
    // Jitter impact (0-10 points)
    if (avgJitter > 0) {
      if (avgJitter < 10) {
        // Excellent: <10ms
        score -= 0;
      } else if (avgJitter < 30) {
        // Good: 10-30ms
        score -= 3;
      } else if (avgJitter < 50) {
        // Fair: 30-50ms
        score -= 5;
      } else if (avgJitter < 100) {
        // Poor: 50-100ms
        score -= 8;
      } else {
        // Critical: >100ms
        score -= 10;
      }
    }
    
    // Determine quality based on score
    if (score >= 90) {
      _currentQuality = SocketConnectionQuality.excellent;
    } else if (score >= 75) {
      _currentQuality = SocketConnectionQuality.good;
    } else if (score >= 50) {
      _currentQuality = SocketConnectionQuality.fair;
    } else if (score >= 30) {
      _currentQuality = SocketConnectionQuality.poor;
    } else {
      _currentQuality = SocketConnectionQuality.critical;
    }
    
    _lastUpdate = DateTime.now();
  }
  
  /// Get a description of the current connection quality
  String getQualityDescription() {
    switch (_currentQuality) {
      case SocketConnectionQuality.excellent:
        return 'Excellent';
      case SocketConnectionQuality.good:
        return 'Good';
      case SocketConnectionQuality.fair:
        return 'Fair';
      case SocketConnectionQuality.poor:
        return 'Poor';
      case SocketConnectionQuality.critical:
        return 'Critical';
      case SocketConnectionQuality.none:
        return 'No Connection';
    }
  }
  
  /// Get a summary of the connection metrics
  String getMetricsSummary() {
    return 'Latency: ${averageLatency}ms, Jitter: ${averageJitter}ms, Packet Loss: ${(_packetLossRate * 100).toStringAsFixed(1)}%, Stability: ${(_stabilityScore * 100).toStringAsFixed(1)}%';
  }
} 