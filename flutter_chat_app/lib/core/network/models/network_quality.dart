/// Represents the quality of the network connection
enum NetworkQuality {
  /// Excellent network quality with low latency (< 100ms)
  excellent,
  
  /// Good network quality with moderate latency (< 300ms)
  good,
  
  /// Fair network quality with higher latency (< 1000ms)
  fair,
  
  /// Poor network quality with high latency (< 3000ms)
  poor,
  
  /// Very poor network quality with very high latency (>= 3000ms)
  veryPoor,
  
  /// Network is disconnected
  offline
} 