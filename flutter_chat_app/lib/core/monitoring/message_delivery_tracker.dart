import 'dart:async';

import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

/// Status của việc gửi tin nhắn trong monitoring
enum MessageDeliveryStatus {
  /// Đang chuẩn bị gửi
  preparing,

  /// Đang chờ kết nối
  waitingForConnection,

  /// Đang gửi
  sending,

  /// Đã gửi thành công lên server
  sent,

  /// Đã nhận bởi người nhận
  delivered,

  /// Đã đọc bởi người nhận
  read,

  /// Thất bại khi gửi
  failed,
}

/// Class theo dõi hiệu suất gửi và nhận tin nhắn
@singleton
class MessageDeliveryTracker {
  /// Logger
  final _logger = Logger();
  
  /// Performance monitor để tạo traces
  final PerformanceMonitor _performanceMonitor;
  
  /// Map lưu thông tin gửi nhận message
  final Map<String, MessageDeliveryInfo> _messageTraces = {};
  
  /// UUID generator
  final _uuid = const Uuid();
  
  /// Constructor
  MessageDeliveryTracker(this._performanceMonitor);

  // Backward compatibility methods for tests

  /// Start tracking a message (backward compatibility)
  Future<String> startTracking(String messageId, String chatId) async {
    return trackNewMessage(chatId, messageId: messageId);
  }

  /// Update message status (backward compatibility)
  Future<void> updateStatus(String messageId, MessageDeliveryStatus status) async {
    await updateMessageStatus(messageId, status);
  }

  /// Complete message tracking (backward compatibility)
  Future<void> completeTracking(String messageId, {bool success = true}) async {
    final status = success ? MessageDeliveryStatus.read : MessageDeliveryStatus.failed;
    await updateMessageStatus(messageId, status);
  }
  
  /// Khởi tạo
  Future<void> initialize() async {
    try {
      _logger.i('Khởi tạo Message Delivery Tracker');
    } catch (e) {
      _logger.e('Lỗi khi khởi tạo Message Delivery Tracker: $e');
    }
  }
  
  /// Bắt đầu theo dõi tin nhắn mới
  String trackNewMessage(String chatId, {String? messageId}) {
    final id = messageId ?? _uuid.v4();
    
    // Tạo thông tin theo dõi mới
    final deliveryInfo = MessageDeliveryInfo(
      messageId: id,
      chatId: chatId,
      createdAt: DateTime.now(),
    );
    
    // Lưu vào map
    _messageTraces[id] = deliveryInfo;
    
    // Tạo custom trace
    _performanceMonitor.startTrace(
      TraceType.custom,
      customTraceName: 'message_delivery_$id',
      attributes: {
        'message_id': id,
        'chat_id': chatId,
      },
    );
    
    _logger.t('Bắt đầu theo dõi tin nhắn: $id trong chat: $chatId');
    
    return id;
  }
  
  /// Cập nhật trạng thái của tin nhắn
  Future<void> updateMessageStatus(
    String messageId,
    MessageDeliveryStatus status, {
    Map<String, dynamic>? additionalData,
  }) async {
    final deliveryInfo = _messageTraces[messageId];
    if (deliveryInfo == null) {
      _logger.w('Không tìm thấy thông tin gửi nhận cho tin nhắn: $messageId');
      return;
    }
    
    try {
      final now = DateTime.now();
      
      switch (status) {
        case MessageDeliveryStatus.preparing:
          deliveryInfo.preparingAt = now;
          break;
        case MessageDeliveryStatus.waitingForConnection:
          deliveryInfo.waitingForConnectionAt = now;
          break;
        case MessageDeliveryStatus.sending:
          deliveryInfo.sendingAt = now;
          break;
        case MessageDeliveryStatus.sent:
          deliveryInfo.sentAt = now;
          break;
        case MessageDeliveryStatus.delivered:
          deliveryInfo.deliveredAt = now;
          break;
        case MessageDeliveryStatus.read:
          deliveryInfo.readAt = now;
          _completeMessageDeliveryTrace(messageId);
          break;
        case MessageDeliveryStatus.failed:
          deliveryInfo.failedAt = now;
          _completeMessageDeliveryTrace(messageId, isFailed: true);
          break;
      }
      
      // Thêm thông tin bổ sung
      if (additionalData != null) {
        deliveryInfo.additionalData.addAll(additionalData);
      }
      
      // Cập nhật trạng thái hiện tại
      deliveryInfo.currentStatus = status;
      
      // Cập nhật metrics cho trace
      _updateTraceMetrics(messageId);
      
      _logger.t('Cập nhật trạng thái tin nhắn $messageId: $status');
    } catch (e) {
      _logger.e('Lỗi khi cập nhật trạng thái tin nhắn: $e');
    }
  }
  
  /// Cập nhật thông tin kích thước tin nhắn
  Future<void> setMessageSize(String messageId, int sizeInBytes) async {
    final deliveryInfo = _messageTraces[messageId];
    if (deliveryInfo == null) return;
    
    deliveryInfo.messageSizeBytes = sizeInBytes;
    
    await _performanceMonitor.addTraceMetric(
      TraceType.custom,
      customTraceName: 'message_delivery_$messageId',
      metricName: 'message_size_bytes',
      value: sizeInBytes,
    );
  }
  
  /// Cập nhật thông tin loại kết nối
  Future<void> setConnectionType(String messageId, String connectionType) async {
    final deliveryInfo = _messageTraces[messageId];
    if (deliveryInfo == null) return;
    
    deliveryInfo.connectionType = connectionType;
    
    await _performanceMonitor.addTraceAttribute(
      TraceType.custom,
      customTraceName: 'message_delivery_$messageId',
      attributeName: 'connection_type',
      value: connectionType,
    );
  }
  
  /// Cập nhật metrics cho trace
  Future<void> _updateTraceMetrics(String messageId) async {
    final deliveryInfo = _messageTraces[messageId];
    if (deliveryInfo == null) return;
    
    final metrics = <String, int>{};
    final attributes = <String, String>{};
    
    // Thêm metrics thời gian
    if (deliveryInfo.preparingAt != null && deliveryInfo.sendingAt != null) {
      final preparingTimeMs = deliveryInfo.sendingAt!.difference(deliveryInfo.preparingAt!).inMilliseconds;
      metrics['preparing_time_ms'] = preparingTimeMs;
    }
    
    if (deliveryInfo.sendingAt != null && deliveryInfo.sentAt != null) {
      final sendingTimeMs = deliveryInfo.sentAt!.difference(deliveryInfo.sendingAt!).inMilliseconds;
      metrics['sending_time_ms'] = sendingTimeMs;
    }
    
    if (deliveryInfo.sentAt != null && deliveryInfo.deliveredAt != null) {
      final deliveryTimeMs = deliveryInfo.deliveredAt!.difference(deliveryInfo.sentAt!).inMilliseconds;
      metrics['delivery_time_ms'] = deliveryTimeMs;
    }
    
    if (deliveryInfo.deliveredAt != null && deliveryInfo.readAt != null) {
      final readTimeMs = deliveryInfo.readAt!.difference(deliveryInfo.deliveredAt!).inMilliseconds;
      metrics['read_time_ms'] = readTimeMs;
    }
    
    if (deliveryInfo.preparingAt != null && deliveryInfo.sentAt != null) {
      final totalSendTimeMs = deliveryInfo.sentAt!.difference(deliveryInfo.preparingAt!).inMilliseconds;
      metrics['total_send_time_ms'] = totalSendTimeMs;
    }
    
    // Thêm attributes
    attributes['current_status'] = deliveryInfo.currentStatus.toString();
    
    if (deliveryInfo.connectionType != null) {
      attributes['connection_type'] = deliveryInfo.connectionType!;
    }
    
    // Cập nhật trace
    if (metrics.isNotEmpty) {
      await _performanceMonitor.stopTrace(
        TraceType.custom,
        customTraceName: 'message_delivery_$messageId',
        metrics: metrics,
      );
      
      // Restart trace để tiếp tục theo dõi
      if (deliveryInfo.currentStatus != MessageDeliveryStatus.read && 
          deliveryInfo.currentStatus != MessageDeliveryStatus.failed) {
        await _performanceMonitor.startTrace(
          TraceType.custom,
          customTraceName: 'message_delivery_$messageId',
          attributes: {
            'message_id': messageId,
            'chat_id': deliveryInfo.chatId,
            ...attributes,
          },
        );
      }
    }
    
    _logger.t('Cập nhật metrics cho trace: $messageId');
  }
  
  /// Hoàn thành theo dõi tin nhắn
  Future<void> _completeMessageDeliveryTrace(String messageId, {bool isFailed = false}) async {
    final deliveryInfo = _messageTraces[messageId];
    if (deliveryInfo == null) return;
    
    try {
      // Tính toán các metrics cuối cùng
      final metrics = <String, int>{};
      
      if (deliveryInfo.preparingAt != null) {
        final totalTime = DateTime.now().difference(deliveryInfo.preparingAt!).inMilliseconds;
        metrics['total_delivery_time_ms'] = totalTime;
      }
      
      if (deliveryInfo.messageSizeBytes != null) {
        metrics['message_size_bytes'] = deliveryInfo.messageSizeBytes!;
      }
      
      // Thêm attribute kết quả
      final attributes = <String, String>{
        'result': isFailed ? 'failed' : 'success',
      };
      
      if (isFailed && deliveryInfo.additionalData.containsKey('error')) {
        attributes['error'] = deliveryInfo.additionalData['error'].toString();
      }
      
      if (deliveryInfo.connectionType != null) {
        attributes['connection_type'] = deliveryInfo.connectionType!;
      }
      
      // Thêm metrics và attributes
      for (final entry in attributes.entries) {
        await _performanceMonitor.addTraceAttribute(
          TraceType.custom,
          customTraceName: 'message_delivery_$messageId',
          attributeName: entry.key,
          value: entry.value,
        );
      }
      
      // Dừng trace
      await _performanceMonitor.stopTrace(
        TraceType.custom,
        customTraceName: 'message_delivery_$messageId',
        metrics: metrics,
      );
      
      // Lưu thống kê tổng hợp cho tất cả tin nhắn
      _updateAggregateStats(deliveryInfo, isFailed);
      
      // Dọn dẹp
      _messageTraces.remove(messageId);
      
      _logger.t('Hoàn thành theo dõi tin nhắn $messageId: ${isFailed ? "thất bại" : "thành công"}');
    } catch (e) {
      _logger.e('Lỗi khi hoàn thành trace cho tin nhắn: $e');
    }
  }
  
  /// Cập nhật thống kê tổng hợp cho tất cả tin nhắn
  void _updateAggregateStats(MessageDeliveryInfo info, bool isFailed) {
    try {
      // Thêm metrics cho trace gửi tin nhắn tổng hợp
      final metrics = <String, int>{};
      
      if (info.preparingAt != null && info.sentAt != null) {
        metrics['avg_sending_time_ms'] = info.sentAt!.difference(info.preparingAt!).inMilliseconds;
      }
      
      if (info.sentAt != null && info.deliveredAt != null) {
        metrics['avg_delivery_time_ms'] = info.deliveredAt!.difference(info.sentAt!).inMilliseconds;
      }
      
      _performanceMonitor.startTrace(
        TraceType.sendMessage,
        attributes: {
          'aggregate': 'true',
          'chat_id': info.chatId,
          'result': isFailed ? 'failed' : 'success',
        },
      );
      
      _performanceMonitor.stopTrace(
        TraceType.sendMessage,
        metrics: metrics,
      );
    } catch (e) {
      _logger.e('Lỗi khi cập nhật thống kê tổng hợp: $e');
    }
  }
  
  /// Tạo trace cho tin nhắn đã có sẵn (từ queue)
  Future<void> trackExistingQueuedMessage(QueuedMessage queuedMessage) async {
    final messageId = queuedMessage.localId;
    
    // Tạo thông tin theo dõi mới
    final deliveryInfo = MessageDeliveryInfo(
      messageId: messageId,
      chatId: queuedMessage.chatId,
      createdAt: queuedMessage.createdAt,
      preparingAt: queuedMessage.createdAt,
    );
    
    // Lưu vào map
    _messageTraces[messageId] = deliveryInfo;
    
    // Cập nhật trạng thái hiện tại
    MessageDeliveryStatus status;
    switch (queuedMessage.status) {
      case MessageQueueStatus.pending:
        status = MessageDeliveryStatus.waitingForConnection;
        deliveryInfo.waitingForConnectionAt = DateTime.now();
        break;
      case MessageQueueStatus.sending:
        status = MessageDeliveryStatus.sending;
        deliveryInfo.sendingAt = DateTime.now();
        break;
      case MessageQueueStatus.sent:
      case MessageQueueStatus.delivered:
      case MessageQueueStatus.read:
        status = MessageDeliveryStatus.sent;
        deliveryInfo.sentAt = DateTime.now();
        break;
      case MessageQueueStatus.failed:
      case MessageQueueStatus.cancelled:
      case MessageQueueStatus.conflicted:
        status = MessageDeliveryStatus.failed;
        deliveryInfo.failedAt = DateTime.now();
        break;
      default:
        status = MessageDeliveryStatus.preparing;
    }
    
    deliveryInfo.currentStatus = status;
    
    // Tạo custom trace
    await _performanceMonitor.startTrace(
      TraceType.custom,
      customTraceName: 'message_delivery_$messageId',
      attributes: {
        'message_id': messageId,
        'chat_id': queuedMessage.chatId,
        'from_queue': 'true',
        'status': status.toString(),
      },
    );
    
    _logger.t('Bắt đầu theo dõi tin nhắn queued: $messageId, trạng thái: $status');
  }
}

/// Class lưu thông tin gửi và nhận tin nhắn
class MessageDeliveryInfo {
  /// ID của tin nhắn
  final String messageId;
  
  /// ID của chat chứa tin nhắn
  final String chatId;
  
  /// Thời điểm tạo
  final DateTime createdAt;
  
  /// Thời điểm chuẩn bị gửi
  DateTime? preparingAt;
  
  /// Thời điểm chờ kết nối
  DateTime? waitingForConnectionAt;
  
  /// Thời điểm bắt đầu gửi
  DateTime? sendingAt;
  
  /// Thời điểm gửi thành công
  DateTime? sentAt;
  
  /// Thời điểm nhận bởi người nhận
  DateTime? deliveredAt;
  
  /// Thời điểm đọc bởi người nhận
  DateTime? readAt;
  
  /// Thời điểm thất bại
  DateTime? failedAt;
  
  /// Kích thước tin nhắn (bytes)
  int? messageSizeBytes;
  
  /// Loại kết nối (wifi, cellular, etc)
  String? connectionType;
  
  /// Trạng thái hiện tại
  MessageDeliveryStatus currentStatus = MessageDeliveryStatus.preparing;
  
  /// Thông tin bổ sung
  final Map<String, dynamic> additionalData = {};
  
  /// Constructor
  MessageDeliveryInfo({
    required this.messageId,
    required this.chatId,
    required this.createdAt,
    this.preparingAt,
  });
} 