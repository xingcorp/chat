import 'dart:async';
import 'package:logger/logger.dart';
import '../models/offline_message.dart';

/// Handler xử lý tin nhắn offline
class OfflineMessageHandler {
  final Logger _logger;
  
  // Danh sách tin nhắn đã gửi trong khi offline
  final List<OfflineMessage> _offlineMessages = [];
  
  // Timer cho việc sync offline message
  Timer? _offlineSyncTimer;
  
  // Hàm callback để gửi tin nhắn
  final Future<bool> Function(String, dynamic) _sendFunction;
  
  // Khoảng thời gian giữa các lần gửi (ms)
  final int _syncIntervalMs;
  
  // Maximum số lần thử lại cho mỗi tin nhắn
  final int _maxRetries;
  
  /// Constructor
  OfflineMessageHandler({
    required Future<bool> Function(String, dynamic) sendFunction, 
    Logger? logger,
    int syncIntervalMs = 300,
    int maxRetries = 3,
  }) : 
    _sendFunction = sendFunction,
    _logger = logger ?? Logger(),
    _syncIntervalMs = syncIntervalMs,
    _maxRetries = maxRetries;
  
  /// Lưu tin nhắn để gửi sau khi online
  void enqueueMessage(OfflineMessage message) {
    _offlineMessages.add(message);
    _logger.d('Đã lưu tin nhắn ${message.event} để gửi khi online');
  }
  
  /// Lưu tin nhắn để gửi sau khi online (tạo mới từ thông tin)
  void enqueueEvent(String event, dynamic data) {
    _offlineMessages.add(OfflineMessage(
      event: event,
      data: data,
      timestamp: DateTime.now(),
    ));
    
    _logger.d('Đã lưu tin nhắn $event để gửi khi online');
  }
  
  /// Đồng bộ tin nhắn khi online
  Future<void> syncMessages({
    required bool Function() isConnected,
    required Function(int) onProgress,
    required Function(int) onComplete,
  }) async {
    if (_offlineMessages.isEmpty) return;
    
    final totalMessages = _offlineMessages.length;
    _logger.i('Bắt đầu đồng bộ $totalMessages tin nhắn offline');
    
    onProgress(0);
    
    _offlineSyncTimer?.cancel();
    _offlineSyncTimer = Timer.periodic(Duration(milliseconds: _syncIntervalMs), (timer) {
      if (_offlineMessages.isEmpty) {
        timer.cancel();
        _logger.i('Đã đồng bộ xong tin nhắn offline');
        onComplete(totalMessages);
        return;
      }
      
      if (!isConnected()) {
        timer.cancel();
        _logger.w('Kết nối bị mất, dừng đồng bộ tin nhắn offline');
        onComplete(totalMessages - _offlineMessages.length);
        return;
      }
      
      _syncNextMessage();
      
      // Báo cáo tiến độ
      onProgress(totalMessages - _offlineMessages.length);
    });
  }
  
  /// Đồng bộ tin nhắn tiếp theo
  Future<void> _syncNextMessage() async {
    if (_offlineMessages.isEmpty) return;
    
    final message = _offlineMessages.first;
    
    _logger.d('Đồng bộ tin nhắn offline: ${message.event} (${_offlineMessages.length} còn lại)');
    
    try {
      final success = await _sendFunction(message.event, message.data);
      
      if (success) {
        _offlineMessages.removeAt(0);
      } else {
        message.retryCount++;
        
        if (message.retryCount >= _maxRetries) {
          _logger.w('Bỏ tin nhắn sau ${message.retryCount} lần thử: ${message.event}');
          _offlineMessages.removeAt(0);
        } else {
          // Di chuyển vào cuối hàng đợi để thử lại sau
          _offlineMessages.removeAt(0);
          _offlineMessages.add(message);
        }
      }
    } catch (e) {
      _logger.e('Lỗi khi đồng bộ tin nhắn offline: $e');
      
      message.retryCount++;
      if (message.retryCount >= _maxRetries) {
        _logger.w('Bỏ tin nhắn sau ${message.retryCount} lần thử: ${message.event}');
        _offlineMessages.removeAt(0);
      }
    }
  }
  
  /// Hủy đồng bộ
  void cancelSync() {
    _offlineSyncTimer?.cancel();
    _offlineSyncTimer = null;
  }
  
  /// Xóa tất cả tin nhắn đang chờ
  void clearMessages() {
    final count = _offlineMessages.length;
    _offlineMessages.clear();
    _logger.d('Đã xóa $count tin nhắn offline');
  }
  
  /// Lấy số lượng tin nhắn đang chờ
  int get pendingMessageCount => _offlineMessages.length;
  
  /// Kiểm tra có tin nhắn nào đang chờ không
  bool get hasPendingMessages => _offlineMessages.isNotEmpty;
  
  /// Thiết lập các xử lý khi dispose
  void dispose() {
    _offlineSyncTimer?.cancel();
    _offlineMessages.clear();
  }
} 