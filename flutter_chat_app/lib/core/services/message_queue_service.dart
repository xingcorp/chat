import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/repositories/message_repository.dart';
import 'package:rxdart/rxdart.dart';

/// Trạng thái của một tin nhắn trong hàng đợi
enum MessageQueueStatus {
  /// Đang chờ, chưa thử gửi
  pending,
  
  /// Đang trong quá trình gửi
  sending,
  
  /// Đã gửi thành công
  sent,
  
  /// Gửi thất bại, sẽ thử lại
  failed,
  
  /// Không thể gửi sau nhiều lần thử
  error,
  
  /// Đã được người nhận xác nhận
  delivered,
  
  /// Đã được đọc
  read,
}

/// Model quản lý tin nhắn trong hàng đợi
class QueuedMessage {
  /// ID duy nhất để theo dõi tin nhắn trong hàng đợi
  final String localId;
  
  /// ChatID mà tin nhắn sẽ được gửi đến
  final String chatId;
  
  /// Nội dung tin nhắn
  final String content;
  
  /// Loại nội dung của tin nhắn
  final ContentType contentType;
  
  /// IDs của các tệp đính kèm (nếu có)
  final List<String> attachmentIds;
  
  /// Số lần đã thử gửi
  int retryCount;
  
  /// Thời gian tạo tin nhắn
  final DateTime createdAt;
  
  /// Thời gian cập nhật gần nhất
  DateTime updatedAt;
  
  /// Thời gian dự kiến thử lại
  DateTime? scheduledRetryTime;
  
  /// Trạng thái hiện tại của tin nhắn
  MessageQueueStatus status;
  
  /// ID của tin nhắn trên server (sau khi gửi thành công)
  String? serverId;
  
  /// Thông tin lỗi (nếu có)
  String? errorMessage;
  
  /// Constructor
  QueuedMessage({
    String? localId,
    required this.chatId,
    required this.content,
    required this.contentType,
    this.attachmentIds = const [],
    this.retryCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.scheduledRetryTime,
    this.status = MessageQueueStatus.pending,
    this.serverId,
    this.errorMessage,
  })  : localId = localId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// Tạo tin nhắn từ JSON
  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      localId: json['localId'],
      chatId: json['chatId'],
      content: json['content'],
      contentType: ContentType.values.firstWhere(
        (e) => e.toString() == json['contentType'],
      ),
      attachmentIds: List<String>.from(json['attachmentIds'] ?? []),
      retryCount: json['retryCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      scheduledRetryTime: json['scheduledRetryTime'] != null
          ? DateTime.parse(json['scheduledRetryTime'])
          : null,
      status: MessageQueueStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => MessageQueueStatus.pending,
      ),
      serverId: json['serverId'],
      errorMessage: json['errorMessage'],
    );
  }
  
  /// Chuyển tin nhắn sang JSON
  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'chatId': chatId,
      'content': content,
      'contentType': contentType.toString(),
      'attachmentIds': attachmentIds,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'scheduledRetryTime':
          scheduledRetryTime?.toIso8601String(),
      'status': status.toString(),
      'serverId': serverId,
      'errorMessage': errorMessage,
    };
  }
  
  /// Cập nhật trạng thái của tin nhắn
  QueuedMessage copyWithStatus({
    required MessageQueueStatus status,
    String? serverId,
    String? errorMessage,
    DateTime? scheduledRetryTime,
    int? retryCount,
  }) {
    return QueuedMessage(
      localId: localId,
      chatId: chatId,
      content: content,
      contentType: contentType,
      attachmentIds: attachmentIds,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      scheduledRetryTime: scheduledRetryTime ?? this.scheduledRetryTime,
      status: status,
      serverId: serverId ?? this.serverId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Service quản lý hàng đợi tin nhắn
@lazySingleton
class MessageQueueService {
  /// Số lần thử lại tối đa trước khi đánh dấu là lỗi
  static const int _maxRetryCount = 5;
  
  /// Khoảng thời gian cơ bản giữa các lần thử lại (ms)
  static const int _baseRetryDelayMs = 1000;
  
  /// Khoảng thời gian tối đa giữa các lần thử lại (ms)
  static const int _maxRetryDelayMs = 60000; // 1 phút
  
  /// Kích thước lô tối đa để gửi trong 1 lần
  static const int _maxBatchSize = 10;
  
  /// Key lưu trữ hàng đợi tin nhắn
  static const String _storageKey = 'message_queue';
  
  /// Repository for sending messages
  final IMessageRepository _messageRepository;
  
  /// Service to check network connectivity
  final ConnectivityService _connectivityService;
  
  /// Service to store messages locally
  final LocalStorageService _localStorageService;
  
  /// Hàng đợi tin nhắn (sắp xếp theo thứ tự tạo)
  final Queue<QueuedMessage> _messageQueue = Queue<QueuedMessage>();
  
  /// Tin nhắn đang được gửi
  final Map<String, QueuedMessage> _sendingMessages = {};
  
  /// Stream controller để phát các cập nhật trạng thái tin nhắn
  final _messageStatusController = StreamController<QueuedMessage>.broadcast();
  
  /// Timer để xử lý hàng đợi định kỳ
  Timer? _processingTimer;
  
  /// Cờ đánh dấu đang xử lý
  bool _isProcessing = false;
  
  /// Queue paused flag
  bool _isPaused = false;
  
  /// Subscription theo dõi kết nối
  StreamSubscription? _connectivitySubscription;
  
  /// Constructor
  MessageQueueService(
    this._messageRepository,
    this._localStorageService,
    this._connectivityService,
  );
  
  /// Stream các cập nhật trạng thái tin nhắn
  Stream<QueuedMessage> get messageStatusStream => 
      _messageStatusController.stream;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    // Khôi phục hàng đợi từ storage
    await _restoreQueue();
    
    // Lắng nghe sự thay đổi kết nối
    _connectivitySubscription = 
        _connectivityService.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Bắt đầu xử lý hàng đợi
    _startProcessingQueue();
  }
  
  /// Khôi phục hàng đợi từ bộ nhớ cục bộ
  Future<void> _restoreQueue() async {
    try {
      final queueJson = _localStorageService.getString(_storageKey);
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List<dynamic>;
        
        // Khôi phục tin nhắn vào hàng đợi
        for (final messageData in queueData) {
          final message = QueuedMessage.fromJson(messageData);
          
          // Đặt lại trạng thái sending sang pending nếu cần
          if (message.status == MessageQueueStatus.sending) {
            _messageQueue.add(message.copyWithStatus(
              status: MessageQueueStatus.pending,
              errorMessage: 'Sending was interrupted',
            ));
          } else if (message.status == MessageQueueStatus.pending || 
                     message.status == MessageQueueStatus.failed) {
            _messageQueue.add(message);
          }
        }
        
        debugPrint('Restored ${_messageQueue.length} messages to queue');
      }
    } catch (e) {
      debugPrint('Failed to restore message queue: $e');
    }
  }
  
  /// Lưu hàng đợi vào bộ nhớ cục bộ
  Future<void> _saveQueue() async {
    try {
      // Kết hợp tin nhắn đang chờ và đang gửi
      final allMessages = [..._messageQueue, ..._sendingMessages.values];
      
      // Chỉ lưu tin nhắn chưa hoàn thành
      final pendingMessages = allMessages.where((msg) => 
          msg.status == MessageQueueStatus.pending || 
          msg.status == MessageQueueStatus.sending ||
          msg.status == MessageQueueStatus.failed).toList();
      
      final queueJson = jsonEncode(pendingMessages.map((m) => m.toJson()).toList());
      await _localStorageService.setString(_storageKey, queueJson);
    } catch (e) {
      debugPrint('Failed to save message queue: $e');
    }
  }
  
  /// Thêm tin nhắn vào hàng đợi
  Future<String> enqueueMessage({
    required String chatId,
    required String content,
    required ContentType contentType,
    List<String> attachmentIds = const [],
  }) async {
    final queuedMessage = QueuedMessage(
      chatId: chatId,
      content: content,
      contentType: contentType,
      attachmentIds: attachmentIds,
    );
    
    // Thêm vào hàng đợi
    _messageQueue.add(queuedMessage);
    
    // Phát sự kiện cập nhật trạng thái
    _emitStatusUpdate(queuedMessage);
    
    // Lưu hàng đợi
    await _saveQueue();
    
    // Đảm bảo hàng đợi đang chạy
    _ensureQueueProcessing();
    
    return queuedMessage.localId;
  }
  
  /// Đảm bảo hàng đợi đang được xử lý
  void _ensureQueueProcessing() {
    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }
  }
  
  /// Bắt đầu xử lý hàng đợi định kỳ
  void _startProcessingQueue() {
    // Hủy timer hiện tại nếu có
    _processingTimer?.cancel();
    
    // Tạo timer mới
    _processingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!_isProcessing && !_isPaused) {
          _processQueue();
        }
      },
    );
    
    // Xử lý ngay lập tức
    _ensureQueueProcessing();
  }
  
  /// Dừng xử lý hàng đợi
  void pauseQueue() {
    _isPaused = true;
    debugPrint('Message queue paused');
  }
  
  /// Khôi phục xử lý hàng đợi
  void resumeQueue() {
    _isPaused = false;
    debugPrint('Message queue resumed');
    _ensureQueueProcessing();
  }
  
  /// Xử lý kết nối thay đổi
  void _handleConnectivityChange(bool isConnected) {
    if (isConnected) {
      // Khôi phục xử lý khi có kết nối
      resumeQueue();
    } else {
      // Tạm dừng xử lý khi mất kết nối
      pauseQueue();
    }
  }
  
  /// Xử lý hàng đợi tin nhắn
  Future<void> _processQueue() async {
    // Kiểm tra trạng thái kết nối
    if (!await _connectivityService.isConnected()) {
      debugPrint('No connection, skipping queue processing');
      return;
    }
    
    // Tránh xử lý đồng thời
    if (_isProcessing || _isPaused) {
      return;
    }
    
    _isProcessing = true;
    
    try {
      // Xử lý tin nhắn đến lịch thử lại
      await _processScheduledRetries();
      
      // Nếu không có tin nhắn trong hàng đợi, kết thúc
      if (_messageQueue.isEmpty) {
        return;
      }
      
      debugPrint('Processing message queue, ${_messageQueue.length} pending messages');
      
      // Xử lý tin nhắn theo lô
      final batch = _prepareBatch();
      if (batch.isNotEmpty) {
        await _sendMessageBatch(batch);
      }
    } catch (e) {
      debugPrint('Error processing message queue: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Xử lý các tin nhắn đến lịch thử lại
  Future<void> _processScheduledRetries() async {
    final now = DateTime.now();
    
    // Kiểm tra tin nhắn lỗi có đến thời gian thử lại chưa
    for (final message in _sendingMessages.values.toList()) {
      if (message.status == MessageQueueStatus.failed &&
          message.scheduledRetryTime != null &&
          message.scheduledRetryTime!.isBefore(now)) {
        
        // Đặt lại trạng thái để thử lại
        final updatedMessage = message.copyWithStatus(
          status: MessageQueueStatus.pending,
          scheduledRetryTime: null,
        );
        
        // Thêm lại vào hàng đợi
        _messageQueue.add(updatedMessage);
        _sendingMessages.remove(updatedMessage.localId);
        
        // Phát sự kiện cập nhật trạng thái
        _emitStatusUpdate(updatedMessage);
      }
    }
  }
  
  /// Chuẩn bị lô tin nhắn để gửi
  List<QueuedMessage> _prepareBatch() {
    final batch = <QueuedMessage>[];
    
    // Lấy tin nhắn từ hàng đợi theo kích thước lô
    while (batch.length < _maxBatchSize && _messageQueue.isNotEmpty) {
      final message = _messageQueue.removeFirst();
      
      // Kiểm tra xem có phải trạng thái pending không
      if (message.status == MessageQueueStatus.pending) {
        // Cập nhật trạng thái và thêm vào lô
        final updatedMessage = message.copyWithStatus(
          status: MessageQueueStatus.sending,
        );
        
        batch.add(updatedMessage);
        
        // Lưu vào danh sách đang gửi
        _sendingMessages[updatedMessage.localId] = updatedMessage;
        
        // Phát sự kiện cập nhật trạng thái
        _emitStatusUpdate(updatedMessage);
      }
    }
    
    return batch;
  }
  
  /// Gửi lô tin nhắn
  Future<void> _sendMessageBatch(List<QueuedMessage> batch) async {
    // Gửi từng tin nhắn trong lô
    await Future.wait(
      batch.map((message) => _sendSingleMessage(message)),
    );
    
    // Lưu trạng thái hàng đợi
    await _saveQueue();
  }
  
  /// Gửi một tin nhắn
  Future<void> _sendSingleMessage(QueuedMessage message) async {
    try {
      // Gửi tin nhắn thông qua repository
      final sentMessage = await _messageRepository.sendMessage(
        message.chatId,
        message.content,
        message.contentType,
        attachmentIds: message.attachmentIds,
      );
      
      // Cập nhật trạng thái thành công
      final updatedMessage = message.copyWithStatus(
        status: MessageQueueStatus.sent,
        serverId: sentMessage.id,
      );
      
      // Cập nhật trong danh sách đang gửi
      _sendingMessages[message.localId] = updatedMessage;
      
      // Phát sự kiện cập nhật trạng thái
      _emitStatusUpdate(updatedMessage);
      
      debugPrint('Message sent successfully: ${message.localId} -> ${sentMessage.id}');
    } catch (e) {
      // Tăng số lần thử
      final newRetryCount = message.retryCount + 1;
      
      // Kiểm tra có vượt quá số lần thử tối đa không
      if (newRetryCount >= _maxRetryCount) {
        // Đánh dấu lỗi cuối cùng
        final updatedMessage = message.copyWithStatus(
          status: MessageQueueStatus.error,
          errorMessage: e.toString(),
          retryCount: newRetryCount,
        );
        
        // Cập nhật trong danh sách đang gửi
        _sendingMessages[message.localId] = updatedMessage;
        
        // Phát sự kiện cập nhật trạng thái
        _emitStatusUpdate(updatedMessage);
        
        debugPrint('Message failed permanently after $_maxRetryCount attempts: ${message.localId}');
      } else {
        // Tính toán thời gian thử lại với exponential backoff
        final retryDelayMs = _calculateRetryDelay(newRetryCount);
        final scheduledRetryTime = DateTime.now().add(Duration(milliseconds: retryDelayMs));
        
        // Đánh dấu thất bại và lên lịch thử lại
        final updatedMessage = message.copyWithStatus(
          status: MessageQueueStatus.failed,
          errorMessage: e.toString(),
          retryCount: newRetryCount,
          scheduledRetryTime: scheduledRetryTime,
        );
        
        // Cập nhật trong danh sách đang gửi
        _sendingMessages[message.localId] = updatedMessage;
        
        // Phát sự kiện cập nhật trạng thái
        _emitStatusUpdate(updatedMessage);
        
        debugPrint('Message send failed, scheduled retry in ${retryDelayMs}ms: ${message.localId}');
      }
    }
  }
  
  /// Tính toán thời gian thử lại với exponential backoff + jitter
  int _calculateRetryDelay(int retryCount) {
    // Calculate exponential backoff
    final baseDelay = _baseRetryDelayMs * pow(2, retryCount - 1);
    
    // Add jitter (randomness) to avoid thundering herd
    final jitter = Random().nextInt(_baseRetryDelayMs);
    
    // Cap at max delay
    return min(baseDelay.toInt() + jitter, _maxRetryDelayMs);
  }
  
  /// Cập nhật trạng thái của tin nhắn (sau khi nhận được delivered/read receipts)
  Future<void> updateMessageStatus({
    required String localId,
    required MessageQueueStatus newStatus,
  }) async {
    // Tìm tin nhắn trong danh sách đang gửi
    final message = _sendingMessages[localId];
    if (message != null) {
      // Chỉ cho phép cập nhật lên delivered hoặc read
      if (newStatus == MessageQueueStatus.delivered || 
          newStatus == MessageQueueStatus.read) {
        
        // Cập nhật trạng thái
        final updatedMessage = message.copyWithStatus(
          status: newStatus,
        );
        
        // Cập nhật trong danh sách đang gửi
        _sendingMessages[localId] = updatedMessage;
        
        // Phát sự kiện cập nhật trạng thái
        _emitStatusUpdate(updatedMessage);
        
        // Lưu hàng đợi
        await _saveQueue();
      }
    }
  }
  
  /// Phát sự kiện cập nhật trạng thái
  void _emitStatusUpdate(QueuedMessage message) {
    _messageStatusController.add(message);
  }
  
  /// Xóa các tin nhắn đã hoàn thành khỏi hàng đợi
  Future<void> clearCompletedMessages() async {
    // Tìm các tin nhắn đã hoàn thành
    final completedIds = _sendingMessages.entries
        .where((entry) => 
            entry.value.status == MessageQueueStatus.sent ||
            entry.value.status == MessageQueueStatus.delivered ||
            entry.value.status == MessageQueueStatus.read)
        .map((entry) => entry.key)
        .toList();
    
    // Xóa khỏi danh sách đang gửi
    for (final id in completedIds) {
      _sendingMessages.remove(id);
    }
    
    // Lưu hàng đợi
    await _saveQueue();
    
    debugPrint('Cleared ${completedIds.length} completed messages from queue');
  }
  
  /// Lấy trạng thái hiện tại của tin nhắn
  QueuedMessage? getMessageStatus(String localId) {
    return _sendingMessages[localId];
  }
  
  /// Lấy tất cả tin nhắn đang chờ xử lý
  List<QueuedMessage> getPendingMessages() {
    return [..._messageQueue, ..._sendingMessages.values.where(
      (msg) => msg.status == MessageQueueStatus.pending || 
               msg.status == MessageQueueStatus.sending ||
               msg.status == MessageQueueStatus.failed
    )];
  }
  
  /// Thử lại gửi tin nhắn lỗi
  Future<void> retryMessage(String localId) async {
    // Tìm tin nhắn trong danh sách đang gửi
    final message = _sendingMessages[localId];
    if (message != null && 
        (message.status == MessageQueueStatus.failed || 
         message.status == MessageQueueStatus.error)) {
      
      // Cập nhật trạng thái thành pending
      final updatedMessage = message.copyWithStatus(
        status: MessageQueueStatus.pending,
        scheduledRetryTime: null,
      );
      
      // Xóa khỏi danh sách đang gửi
      _sendingMessages.remove(localId);
      
      // Thêm lại vào hàng đợi
      _messageQueue.add(updatedMessage);
      
      // Phát sự kiện cập nhật trạng thái
      _emitStatusUpdate(updatedMessage);
      
      // Lưu hàng đợi
      await _saveQueue();
      
      // Đảm bảo hàng đợi đang chạy
      _ensureQueueProcessing();
    }
  }
  
  /// Hủy một tin nhắn trong hàng đợi
  Future<bool> cancelMessage(String localId) async {
    // Tìm trong hàng đợi
    final pendingMessage = _messageQueue.where((m) => m.localId == localId).toList();
    if (pendingMessage.isNotEmpty) {
      _messageQueue.removeWhere((m) => m.localId == localId);
      await _saveQueue();
      return true;
    }
    
    // Tìm trong danh sách đang gửi
    if (_sendingMessages.containsKey(localId)) {
      final message = _sendingMessages[localId]!;
      
      // Chỉ cho phép hủy nếu chưa gửi thành công
      if (message.status == MessageQueueStatus.pending || 
          message.status == MessageQueueStatus.failed ||
          message.status == MessageQueueStatus.error) {
        
        _sendingMessages.remove(localId);
        await _saveQueue();
        return true;
      }
    }
    
    return false;
  }
  
  /// Đồng bộ trạng thái tin nhắn từ server
  Future<void> syncMessageStatuses(List<ChatMessage> serverMessages) async {
    for (final serverMessage in serverMessages) {
      // Tìm tin nhắn trong danh sách đang gửi
      final localMessages = _sendingMessages.values.where(
        (m) => m.serverId == serverMessage.id
      ).toList();
      
      for (final localMessage in localMessages) {
        // Cập nhật trạng thái theo server
        MessageQueueStatus newStatus;
        
        // Kiểm tra trạng thái đọc
        if (serverMessage.readBy.isNotEmpty) {
          newStatus = MessageQueueStatus.read;
        } else {
          newStatus = MessageQueueStatus.delivered;
        }
        
        // Cập nhật trạng thái
        await updateMessageStatus(
          localId: localMessage.localId,
          newStatus: newStatus,
        );
      }
    }
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _processingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _messageStatusController.close();
  }
  
  /// Mã hóa dữ liệu thành JSON
  dynamic jsonEncode(dynamic data) {
    return data;
  }
  
  /// Giải mã dữ liệu từ JSON
  dynamic jsonDecode(String data) {
    return data;
  }
} 