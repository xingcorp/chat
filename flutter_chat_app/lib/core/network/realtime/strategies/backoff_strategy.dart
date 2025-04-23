import 'dart:math' as math;

/// Chiến lược kết nối lại với exponential backoff và jitter ngẫu nhiên
class BackoffStrategy {
  /// Thời gian chờ tối thiểu (ms)
  final int minDelayMs;
  
  /// Thời gian chờ tối đa (ms)
  final int maxDelayMs;
  
  /// Hệ số nhân cho mỗi lần thử lại
  final double factor;
  
  /// Lượng jitter ngẫu nhiên tối đa (0.0 - 1.0)
  final double jitter;
  
  /// Số lần thử lại hiện tại
  int _attemptCount = 0;
  
  /// Random generator cho jitter
  final math.Random _random = math.Random();

  /// Constructor
  BackoffStrategy({
    this.minDelayMs = 1000,    // 1 giây
    this.maxDelayMs = 300000,  // 5 phút
    this.factor = 2.0,         // Nhân đôi mỗi lần thử
    this.jitter = 0.2,         // 20% ngẫu nhiên
  }) : assert(minDelayMs > 0),
       assert(maxDelayMs > minDelayMs),
       assert(factor > 1.0),
       assert(jitter >= 0.0 && jitter <= 1.0);
  
  /// Đặt lại bộ đếm thử lại
  void reset() {
    _attemptCount = 0;
  }
  
  /// Tăng số lần thử và lấy thời gian chờ tiếp theo (ms)
  int getNextDelay() {
    _attemptCount++;
    
    // Tính thời gian chờ cơ bản với exponential backoff
    final double baseDelay = minDelayMs * math.pow(factor, _attemptCount - 1).toDouble();
    final int calculatedDelay = baseDelay.round();
    
    // Giới hạn trong khoảng min-max
    final int boundedDelay = math.min(maxDelayMs, calculatedDelay);
    
    // Thêm jitter ngẫu nhiên để tránh "thundering herd problem"
    final int jitterAmount = (boundedDelay * jitter * _random.nextDouble()).round();
    
    // Jitter có thể tăng hoặc giảm, nhưng đảm bảo không nhỏ hơn minDelayMs
    final int finalDelay = math.max(minDelayMs, boundedDelay - jitterAmount + (jitterAmount * 2 * _random.nextDouble()).round());
    
    return finalDelay;
  }
  
  /// Lấy số lần thử hiện tại
  int get attemptCount => _attemptCount;
  
  /// Kiểm tra xem đã vượt quá thời gian tối đa chưa
  bool isMaxDelayReached() {
    if (_attemptCount == 0) return false;
    
    final double baseDelay = minDelayMs * math.pow(factor, _attemptCount - 1).toDouble();
    return baseDelay >= maxDelayMs;
  }
} 