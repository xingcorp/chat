import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:injectable/injectable.dart';

/// Class quản lý thông tin rate limit
class RateLimitInfo {
  /// Số lượng tin nhắn tối đa trong khoảng thời gian
  final int limit;
  
  /// Số lượng tin nhắn đã sử dụng
  final int used;
  
  /// Thời gian còn lại trước khi reset (ms)
  final int resetTimeMs;
  
  /// Constructor
  RateLimitInfo({
    required this.limit,
    required this.used,
    required this.resetTimeMs,
  });
  
  /// Số lượng tin nhắn còn lại có thể gửi
  int get remaining => limit - used;
  
  /// Kiểm tra xem có bị rate limit không
  bool get isLimited => used >= limit;
  
  @override
  String toString() => 'RateLimitInfo(limit: $limit, used: $used, remaining: $remaining, resetIn: ${resetTimeMs}ms)';
}

/// Kết quả của việc kiểm tra rate limit
class RateLimitResult {
  /// Có được phép gửi không
  final bool allowed;
  
  /// Thông tin rate limit
  final RateLimitInfo info;
  
  /// Constructor
  RateLimitResult({
    required this.allowed,
    required this.info,
  });
}

/// Service xử lý rate limiting cho Socket.IO
@singleton
class SocketRateLimiter {
  /// Logger
  final Logger _logger = Logger();
  
  /// Cấu hình rate limit mặc định (tin nhắn/phút)
  final int _defaultRateLimit;
  
  /// Rate limits theo event type
  final Map<String, int> _eventRateLimits;
  
  /// Độ dài cửa sổ thời gian (ms)
  final int _windowSizeMs;
  
  /// Timer tự động dọn dẹp timestamp cũ
  Timer? _cleanupTimer;
  
  /// Map chứa timestamp của tin nhắn theo loại event
  final Map<String, Queue<DateTime>> _messageTimestamps = {};
  
  /// Map chứa queue các tin nhắn đang chờ do rate limit
  final Map<String, Queue<_PendingMessage>> _pendingMessages = {};
  
  /// Map lưu trữ timer xử lý tin nhắn đang chờ
  final Map<String, Timer> _processingTimers = {};
  
  /// Constructor
  SocketRateLimiter({
    int defaultRateLimit = 120, // 120 tin nhắn/phút
    Map<String, int>? eventRateLimits,
    int windowSizeMs = 60000, // 1 phút
    int cleanupIntervalMs = 30000, // 30 giây
  }) : _defaultRateLimit = defaultRateLimit,
       _eventRateLimits = eventRateLimits ?? {},
       _windowSizeMs = windowSizeMs {
    
    // Khởi tạo timer dọn dẹp timestamp cũ
    _cleanupTimer = Timer.periodic(Duration(milliseconds: cleanupIntervalMs), (_) {
      _cleanupOldTimestamps();
    });
  }
  
  /// Kiểm tra rate limit cho một event
  RateLimitResult checkRateLimit(String eventType) {
    final rateLimit = _eventRateLimits[eventType] ?? _defaultRateLimit;
    
    // Tạo queue nếu chưa có
    if (!_messageTimestamps.containsKey(eventType)) {
      _messageTimestamps[eventType] = Queue<DateTime>();
    }
    
    // Lấy queue timestamp của event này
    final timestampQueue = _messageTimestamps[eventType]!;
    
    // Xóa timestamp cũ
    final now = DateTime.now();
    final threshold = now.subtract(Duration(milliseconds: _windowSizeMs));
    
    while (timestampQueue.isNotEmpty && timestampQueue.first.isBefore(threshold)) {
      timestampQueue.removeFirst();
    }
    
    // Kiểm tra có vượt quá giới hạn không
    final used = timestampQueue.length;
    final isLimited = used >= rateLimit;
    
    // Tính thời gian còn lại trước khi reset
    int resetTimeMs = _windowSizeMs;
    if (timestampQueue.isNotEmpty) {
      resetTimeMs = max(0, _windowSizeMs - now.difference(timestampQueue.first).inMilliseconds);
    }
    
    final info = RateLimitInfo(
      limit: rateLimit,
      used: used,
      resetTimeMs: resetTimeMs,
    );
    
    if (isLimited) {
      _logger.w('Rate limit cho $eventType: $used/$rateLimit tin nhắn trong ${_windowSizeMs}ms');
    }
    
    return RateLimitResult(
      allowed: !isLimited,
      info: info,
    );
  }
  
  /// Ghi nhận một tin nhắn đã gửi
  void recordMessage(String eventType) {
    // Tạo queue nếu chưa có
    if (!_messageTimestamps.containsKey(eventType)) {
      _messageTimestamps[eventType] = Queue<DateTime>();
    }
    
    // Thêm timestamp mới
    _messageTimestamps[eventType]!.add(DateTime.now());
  }
  
  /// Thêm tin nhắn vào hàng đợi
  void enqueueMessage(String eventType, dynamic data, Function(dynamic) sender) {
    // Tạo queue nếu chưa có
    if (!_pendingMessages.containsKey(eventType)) {
      _pendingMessages[eventType] = Queue<_PendingMessage>();
    }
    
    // Thêm tin nhắn vào queue
    _pendingMessages[eventType]!.add(_PendingMessage(
      data: data,
      timestamp: DateTime.now(),
      sender: sender,
    ));
    
    _logger.d('Đã thêm tin nhắn $eventType vào hàng đợi, hiện có ${_pendingMessages[eventType]!.length} tin nhắn đang chờ');
    
    // Lên lịch xử lý queue nếu chưa có
    _scheduleQueueProcessing(eventType);
  }
  
  /// Lên lịch xử lý queue
  void _scheduleQueueProcessing(String eventType) {
    // Nếu đã có timer đang chạy, bỏ qua
    if (_processingTimers.containsKey(eventType)) {
      return;
    }
    
    // Tính thời gian cần đợi
    final result = checkRateLimit(eventType);
    final delayMs = result.allowed ? 100 : result.info.resetTimeMs + 100; // Thêm 100ms để đảm bảo
    
    _logger.d('Lên lịch xử lý queue cho $eventType sau ${delayMs}ms');
    
    // Tạo timer mới
    _processingTimers[eventType] = Timer(Duration(milliseconds: delayMs), () {
      _processQueue(eventType);
      _processingTimers.remove(eventType);
    });
  }
  
  /// Xử lý queue tin nhắn đang chờ
  void _processQueue(String eventType) {
    if (!_pendingMessages.containsKey(eventType) || _pendingMessages[eventType]!.isEmpty) {
      return;
    }
    
    final result = checkRateLimit(eventType);
    if (!result.allowed) {
      // Vẫn chưa được phép, lên lịch lại
      _scheduleQueueProcessing(eventType);
      return;
    }
    
    // Lấy tin nhắn đầu tiên
    final message = _pendingMessages[eventType]!.removeFirst();
    
    // Gửi tin nhắn
    try {
      message.sender(message.data);
      recordMessage(eventType);
      
      _logger.d('Đã gửi tin nhắn $eventType từ hàng đợi, còn lại ${_pendingMessages[eventType]!.length} tin nhắn');
      
      // Nếu còn tin nhắn trong queue, lên lịch xử lý tiếp
      if (_pendingMessages[eventType]!.isNotEmpty) {
        _scheduleQueueProcessing(eventType);
      }
    } catch (e) {
      _logger.e('Lỗi khi gửi tin nhắn từ hàng đợi: $e');
      
      // Nếu lỗi, đưa tin nhắn vào lại queue nếu chưa quá số lần thử
      if (message.retryCount < 3) {
        message.retryCount++;
        _pendingMessages[eventType]!.addFirst(message);
        _scheduleQueueProcessing(eventType);
      } else {
        _logger.w('Bỏ qua tin nhắn $eventType sau ${message.retryCount} lần thử');
        
        // Xử lý tin nhắn tiếp theo nếu còn
        if (_pendingMessages[eventType]!.isNotEmpty) {
          _scheduleQueueProcessing(eventType);
        }
      }
    }
  }
  
  /// Dọn dẹp timestamp cũ
  void _cleanupOldTimestamps() {
    final now = DateTime.now();
    final threshold = now.subtract(Duration(milliseconds: _windowSizeMs));
    
    for (final eventType in _messageTimestamps.keys) {
      final queue = _messageTimestamps[eventType]!;
      
      while (queue.isNotEmpty && queue.first.isBefore(threshold)) {
        queue.removeFirst();
      }
    }
  }
  
  /// Đặt rate limit cho một event cụ thể
  void setEventRateLimit(String eventType, int limit) {
    _eventRateLimits[eventType] = limit;
    _logger.i('Đặt rate limit cho $eventType: $limit tin nhắn/${_windowSizeMs}ms');
  }
  
  /// Lấy thông tin rate limit cho một event
  RateLimitInfo getRateLimitInfo(String eventType) {
    final result = checkRateLimit(eventType);
    return result.info;
  }
  
  /// Hủy tất cả hàng đợi
  void clearQueues() {
    _pendingMessages.clear();
    
    // Hủy tất cả các timer
    for (final timer in _processingTimers.values) {
      timer.cancel();
    }
    _processingTimers.clear();
    
    _logger.i('Đã xóa tất cả hàng đợi tin nhắn');
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _cleanupTimer?.cancel();
    
    // Hủy tất cả các timer
    for (final timer in _processingTimers.values) {
      timer.cancel();
    }
    
    _messageTimestamps.clear();
    _pendingMessages.clear();
    _processingTimers.clear();
  }
}

/// Class lưu trữ thông tin tin nhắn đang chờ
class _PendingMessage {
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// Thời gian tạo
  final DateTime timestamp;
  
  /// Function gửi tin nhắn
  final Function(dynamic) sender;
  
  /// Số lần thử lại
  int retryCount = 0;
  
  /// Constructor
  _PendingMessage({
    required this.data,
    required this.timestamp,
    required this.sender,
  });
} 