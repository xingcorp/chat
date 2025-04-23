import 'dart:math';

/// Chiến lược backoff thông minh cho kết nối lại
/// Sử dụng exponential backoff với jitter để tránh thundering herd
class SmartBackoffStrategy {
  /// Delay cơ bản (ms)
  final int baseDelayMs;
  
  /// Delay tối đa (ms)
  final int maxDelayMs;
  
  /// Hệ số tăng (multiplicative factor)
  final double factor;
  
  /// Tỷ lệ jitter (0.0 - 1.0)
  final double jitterFactor;
  
  /// Số lần thử hiện tại
  int _attemptCount = 0;
  
  /// Giá trị delay cuối cùng được tính toán
  int _lastCalculatedDelay = 0;
  
  /// Random generator
  final Random _random = Random();
  
  /// Constructor
  SmartBackoffStrategy({
    this.baseDelayMs = 1000,
    this.maxDelayMs = 60000,
    this.factor = 1.5,
    this.jitterFactor = 0.2,
  });
  
  /// Reset số lần thử về 0
  void reset() {
    _attemptCount = 0;
    _lastCalculatedDelay = 0;
  }
  
  /// Tăng số lần thử và trả về thời gian delay tiếp theo (ms)
  int nextDelay() {
    _attemptCount++;
    
    // Tính toán delay cơ bản theo hàm mũ
    final baseDelay = baseDelayMs * pow(factor, _attemptCount - 1).toInt();
    
    // Áp dụng max delay
    final cappedDelay = min(baseDelay, maxDelayMs);
    
    // Áp dụng jitter để tránh thundering herd
    // Phạm vi jitter: [(1-jitterFactor)*delay, (1+jitterFactor)*delay]
    final jitterMin = (cappedDelay * (1 - jitterFactor)).toInt();
    final jitterMax = (cappedDelay * (1 + jitterFactor)).toInt();
    
    final jitterRange = jitterMax - jitterMin;
    final jitter = jitterRange > 0 ? _random.nextInt(jitterRange) : 0;
    
    _lastCalculatedDelay = jitterMin + jitter;
    return _lastCalculatedDelay;
  }
  
  /// Lấy thời gian delay hiện tại mà không tăng số lần thử
  int get currentDelay => _lastCalculatedDelay;
  
  /// Lấy số lần thử hiện tại
  int get attemptCount => _attemptCount;
  
  /// Kiểm tra xem đã vượt quá số lần thử tối đa chưa
  bool exceedsMaxAttempts(int maxAttempts) => _attemptCount >= maxAttempts;
}

/// Factory tạo các chiến lược backoff phổ biến
class BackoffStrategyFactory {
  /// Tạo chiến lược backoff cho kết nối lại WebSocket
  static SmartBackoffStrategy createForWebSocketReconnect() {
    return SmartBackoffStrategy(
      baseDelayMs: 1000,       // 1s ban đầu
      maxDelayMs: 45000,       // Tối đa 45s
      factor: 1.5,             // Tăng gấp 1.5 lần mỗi lần thử
      jitterFactor: 0.3,       // Jitter ±30%
    );
  }
  
  /// Tạo chiến lược backoff cho polling requests
  static SmartBackoffStrategy createForPollingRequests() {
    return SmartBackoffStrategy(
      baseDelayMs: 500,        // 500ms ban đầu
      maxDelayMs: 10000,       // Tối đa 10s
      factor: 1.3,             // Tăng nhẹ hơn
      jitterFactor: 0.1,       // Jitter ±10%
    );
  }
  
  /// Tạo chiến lược backoff cho API retries
  static SmartBackoffStrategy createForApiRetries() {
    return SmartBackoffStrategy(
      baseDelayMs: 300,        // 300ms ban đầu
      maxDelayMs: 5000,        // Tối đa 5s
      factor: 2.0,             // Tăng nhanh hơn cho API
      jitterFactor: 0.1,       // Jitter ±10%
    );
  }
} 