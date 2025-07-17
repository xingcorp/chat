import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:logger/logger.dart';

/// Resultado de verificación de límite de tasa
class RateLimitResult {
  /// Si se permite el evento
  final bool allowed;
  
  /// Información adicional sobre el límite
  final RateLimitInfo info;
  
  /// Constructor
  const RateLimitResult({
    required this.allowed,
    required this.info,
  });
}

/// Información sobre el límite de tasa para un tipo de evento
class RateLimitInfo {
  /// Giới hạn số tin nhắn trong khoảng thời gian
  final int limit;
  
  /// Số tin nhắn đã gửi trong khoảng thời gian
  final int used;
  
  /// Thời gian còn lại trước khi reset (ms)
  final int resetInMs;
  
  /// Constructor
  const RateLimitInfo({
    required this.limit,
    required this.used,
    required this.resetInMs,
  });
  
  /// Số tin nhắn còn lại có thể gửi
  int get remaining => limit - used;
  
  /// Có bị rate limit không
  bool get isLimited => used >= limit;
}

/// Implementación de limitador de tasa para eventos de socket
class SocketRateLimiter {
  /// Logger
  final Logger _logger;
  
  /// Giới hạn tin nhắn mặc định cho mỗi loại
  final int _defaultLimit;
  
  /// Thời gian window (ms) mặc định
  final int _defaultWindowMs;
  
  /// Thời gian chờ backoff (ms) mặc định
  final int _defaultBackoffMs;
  
  /// Queue lưu trữ các tin nhắn bị rate limit
  final _messageQueue = Queue<_QueuedMessage>();
  
  /// Map lưu trữ giới hạn tùy chỉnh cho từng loại sự kiện
  final Map<String, int> _customLimits = {};
  
  /// Map lưu trữ lịch sử gửi tin nhắn
  final Map<String, List<int>> _messageHistory = {};
  
  /// Timer xử lý hàng đợi
  Timer? _queueProcessingTimer;
  
  /// Constructor
  SocketRateLimiter({
    Logger? logger,
    int defaultLimit = 10,
    int defaultWindowMs = 1000,
    int defaultBackoffMs = 50,
  }) : 
    _logger = logger ?? Logger(),
    _defaultLimit = defaultLimit,
    _defaultWindowMs = defaultWindowMs,
    _defaultBackoffMs = defaultBackoffMs;
  
  /// Kiểm tra có vượt quá rate limit không
  RateLimitResult checkRateLimit(String eventType) {
    // Lấy giới hạn cho loại sự kiện này
    final limit = _customLimits[eventType] ?? _defaultLimit;
    
    // Lấy lịch sử gửi
    final history = _getMessageHistory(eventType);
    
    // Lọc các tin nhắn trong window hiện tại
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStartTime = now - _defaultWindowMs;
    
    // Chỉ giữ lại lịch sử gửi trong window hiện tại
    history.removeWhere((timestamp) => timestamp < windowStartTime);
    
    // Đếm số tin nhắn đã gửi trong window
    final used = history.length;
    
    // Tính thời gian còn lại trước khi reset
    final oldestTimestamp = history.isEmpty ? now : history.first;
    final resetInMs = math.max(0, _defaultWindowMs - (now - oldestTimestamp));
    
    // Tạo thông tin rate limit
    final info = RateLimitInfo(
      limit: limit,
      used: used,
      resetInMs: resetInMs,
    );
    
    // Kiểm tra có cho phép gửi không
    final allowed = used < limit;
    
    return RateLimitResult(allowed: allowed, info: info);
  }
  
  /// Lấy lịch sử gửi tin nhắn cho một loại sự kiện
  List<int> _getMessageHistory(String eventType) {
    if (!_messageHistory.containsKey(eventType)) {
      _messageHistory[eventType] = [];
    }
    return _messageHistory[eventType]!;
  }
  
  /// Ghi nhận tin nhắn đã gửi
  void recordMessage(String eventType) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _getMessageHistory(eventType).add(now);
  }
  
  /// Thêm tin nhắn vào hàng đợi để gửi sau
  void enqueueMessage(String eventType, dynamic data, Function(dynamic) sendCallback) {
    // Thêm vào hàng đợi
    _messageQueue.add(_QueuedMessage(
      eventType: eventType,
      data: data,
      sendCallback: sendCallback,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    
    _logger.d('Đã thêm vào hàng đợi: $eventType (độ dài hàng đợi: ${_messageQueue.length})');
    
    // Bắt đầu xử lý hàng đợi nếu chưa chạy
    _startQueueProcessing();
  }
  
  /// Bắt đầu xử lý hàng đợi
  void _startQueueProcessing() {
    if (_queueProcessingTimer != null) {
      return; // Đã chạy rồi
    }
    
    _queueProcessingTimer = Timer.periodic(
      Duration(milliseconds: _defaultBackoffMs),
      (_) => _processQueue(),
    );
  }
  
  /// Xử lý hàng đợi
  void _processQueue() {
    if (_messageQueue.isEmpty) {
      _queueProcessingTimer?.cancel();
      _queueProcessingTimer = null;
      return;
    }
    
    // Lấy tin nhắn đầu tiên
    final message = _messageQueue.first;
    
    // Kiểm tra rate limit
    final result = checkRateLimit(message.eventType);
    
    if (result.allowed) {
      // Gửi tin nhắn
      _messageQueue.removeFirst();
      
      // Gửi tin nhắn
      message.sendCallback(message.data);
      
      // Ghi nhận đã gửi
      recordMessage(message.eventType);
      
      _logger.d('Đã gửi tin nhắn từ hàng đợi: ${message.eventType}');
    }
  }
  
  /// Lấy thông tin rate limit cho một sự kiện
  RateLimitInfo getRateLimitInfo(String eventType) {
    final result = checkRateLimit(eventType);
    return result.info;
  }
  
  /// Thiết lập giới hạn tùy chỉnh cho một sự kiện
  void setEventRateLimit(String eventType, int limit) {
    if (limit <= 0) {
      _customLimits.remove(eventType);
    } else {
      _customLimits[eventType] = limit;
    }
    
    _logger.d('Đã thiết lập rate limit cho $eventType: $limit');
  }
  
  /// Xóa tất cả lịch sử gửi tin nhắn
  void clearHistory() {
    _messageHistory.clear();
  }
  
  /// Xóa hàng đợi tin nhắn
  void clearQueue() {
    _messageQueue.clear();
    _queueProcessingTimer?.cancel();
    _queueProcessingTimer = null;
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _queueProcessingTimer?.cancel();
    _messageQueue.clear();
    _messageHistory.clear();
  }
}

/// Clase interna para mensajes en cola
class _QueuedMessage {
  /// Loại sự kiện
  final String eventType;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// Callback để gửi tin nhắn
  final Function(dynamic) sendCallback;
  
  /// Thời gian tạo
  final int timestamp;
  
  /// Constructor
  _QueuedMessage({
    required this.eventType,
    required this.data,
    required this.sendCallback,
    required this.timestamp,
  });
} 