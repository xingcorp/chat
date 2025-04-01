import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
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
  
  /// Đã được xung đột với tin nhắn từ server
  conflicted,
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
  
  /// Mức độ ưu tiên (tin nhắn có độ ưu tiên cao hơn sẽ được gửi trước)
  final int priority;
  
  /// Hash nội dung để phát hiện trùng lặp
  final String contentHash;
  
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
    this.priority = 0,
  })  : localId = localId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        contentHash = _generateContentHash(chatId, content, contentType, attachmentIds);
  
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
      priority: json['priority'] ?? 0,
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
      'priority': priority,
      'contentHash': contentHash,
    };
  }
  
  /// Tạo hash cho nội dung để phát hiện trùng lặp
  static String _generateContentHash(
    String chatId,
    String content,
    ContentType contentType,
    List<String> attachmentIds,
  ) {
    final combinedString = '$chatId|$content|${contentType.toString()}|${attachmentIds.join(',')}';
    // Sử dụng một hàm hash đơn giản vì mục đích chính là phát hiện trùng lặp
    var hash = 0;
    for (var i = 0; i < combinedString.length; i++) {
      hash = ((hash << 5) - hash) + combinedString.codeUnitAt(i);
      hash &= hash; // Convert to 32bit integer
    }
    return hash.toString();
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
      priority: priority,
    );
  }
  
  /// Kiểm tra xem tin nhắn có giống nhau không dựa vào nội dung
  bool hasSameContent(QueuedMessage other) {
    return contentHash == other.contentHash;
  }
}

/// Lớp giúp ưu tiên tin nhắn trong hàng đợi
class MessagePriorityQueue {
  /// Hàng đợi tin nhắn
  final _queue = HeapPriorityQueue<QueuedMessage>(
    (a, b) {
      // So sánh độ ưu tiên trước
      final priorityComparison = b.priority.compareTo(a.priority);
      if (priorityComparison != 0) return priorityComparison;
      
      // Nếu độ ưu tiên bằng nhau, so sánh thời gian tạo (cũ hơn được gửi trước)
      return a.createdAt.compareTo(b.createdAt);
    },
  );
  
  /// Map để truy cập nhanh tin nhắn theo ID
  final Map<String, QueuedMessage> _messageMap = {};
  
  /// Thêm tin nhắn vào hàng đợi
  void add(QueuedMessage message) {
    // Xóa tin nhắn cũ nếu đã tồn tại
    if (_messageMap.containsKey(message.localId)) {
      // Không thể xóa trực tiếp từ PriorityQueue, 
      // nên chúng ta chỉ đánh dấu trong map
      _messageMap.remove(message.localId);
    }
    
    // Thêm tin nhắn mới
    _queue.add(message);
    _messageMap[message.localId] = message;
  }
  
  /// Lấy tin nhắn đầu tiên và xóa khỏi hàng đợi
  QueuedMessage? removeFirst() {
    if (_queue.isEmpty) return null;
    
    final message = _queue.removeFirst();
    _messageMap.remove(message.localId);
    return message;
  }
  
  /// Kiểm tra hàng đợi có trống không
  bool get isEmpty => _queue.isEmpty;
  
  /// Lấy số lượng tin nhắn trong hàng đợi
  int get length => _queue.length;
  
  /// Xóa tin nhắn khỏi hàng đợi
  bool remove(String localId) {
    final message = _messageMap[localId];
    if (message == null) return false;
    
    // Không thể xóa trực tiếp từ PriorityQueue
    // nên chúng ta sẽ tái tạo hàng đợi
    _messageMap.remove(localId);
    
    final tempList = <QueuedMessage>[];
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (item.localId != localId) {
        tempList.add(item);
      }
    }
    
    // Thêm lại các tin nhắn
    for (final item in tempList) {
      _queue.add(item);
    }
    
    return true;
  }
  
  /// Xóa tất cả tin nhắn khỏi hàng đợi
  void clear() {
    _queue.clear();
    _messageMap.clear();
  }
  
  /// Lấy danh sách tin nhắn
  List<QueuedMessage> toList() {
    final result = <QueuedMessage>[];
    final tempList = <QueuedMessage>[];
    
    // Lấy tất cả tin nhắn
    while (_queue.isNotEmpty) {
      final message = _queue.removeFirst();
      result.add(message);
      tempList.add(message);
    }
    
    // Thêm lại tin nhắn vào hàng đợi
    for (final message in tempList) {
      _queue.add(message);
    }
    
    return result;
  }
  
  /// Tìm tin nhắn theo ID
  QueuedMessage? operator [](String localId) => _messageMap[localId];
  
  /// Kiểm tra tin nhắn có tồn tại không
  bool contains(String localId) => _messageMap.containsKey(localId);
  
  /// Lọc tin nhắn theo điều kiện
  List<QueuedMessage> where(bool Function(QueuedMessage) test) {
    return _messageMap.values.where(test).toList();
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
  
  /// Service để quản lý kết nối realtime
  final RealtimeConnectionService _realtimeConnectionService;
  
  /// Hàng đợi tin nhắn (sắp xếp theo thứ tự ưu tiên)
  final MessagePriorityQueue _messageQueue = MessagePriorityQueue();
  
  /// Tin nhắn đang được gửi
  final Map<String, QueuedMessage> _sendingMessages = {};
  
  /// Stream controller để phát các cập nhật trạng thái tin nhắn
  final _messageStatusController = BehaviorSubject<QueuedMessage>();
  
  /// Timer để xử lý hàng đợi định kỳ
  Timer? _processingTimer;
  
  /// Cờ đánh dấu đang xử lý
  bool _isProcessing = false;
  
  /// Queue paused flag
  bool _isPaused = false;
  
  /// Subscription theo dõi kết nối
  StreamSubscription? _connectivitySubscription;
  
  /// Subscription theo dõi kết nối realtime
  StreamSubscription? _realtimeConnectionSubscription;
  
  /// Đã khởi tạo
  bool _initialized = false;
  
  /// Constructor
  MessageQueueService(
    this._messageRepository,
    this._localStorageService,
    this._connectivityService,
    this._realtimeConnectionService,
  );
  
  /// Stream các cập nhật trạng thái tin nhắn
  Stream<QueuedMessage> get messageStatusStream => 
      _messageStatusController.stream;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Đảm bảo các services khác đã được khởi tạo
    await _realtimeConnectionService.initialize();
    
    // Khôi phục hàng đợi từ storage
    await _restoreQueue();
    
    // Lắng nghe sự thay đổi kết nối
    _connectivitySubscription = 
        _connectivityService.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Lắng nghe trạng thái kết nối realtime
    _realtimeConnectionSubscription = 
        _realtimeConnectionService.connectionStateStream.listen(_handleRealtimeConnectionChange);
    
    // Bắt đầu xử lý hàng đợi
    _startProcessingQueue();
    
    _initialized = true;
  }
  
  /// Khôi phục hàng đợi từ bộ nhớ cục bộ
  Future<void> _restoreQueue() async {
    try {
      final queueJson = await _localStorageService.getString(_storageKey);
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
      final pendingMessages = _messageQueue.toList();
      final sendingMessages = _sendingMessages.values.toList();
      final allMessages = [...pendingMessages, ...sendingMessages];
      
      // Chỉ lưu tin nhắn chưa hoàn thành
      final uncompletedMessages = allMessages.where((msg) => 
          msg.status == MessageQueueStatus.pending || 
          msg.status == MessageQueueStatus.sending ||
          msg.status == MessageQueueStatus.failed).toList();
      
      final queueJson = jsonEncode(uncompletedMessages.map((m) => m.toJson()).toList());
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
    int priority = 0,
  }) async {
    final queuedMessage = QueuedMessage(
      chatId: chatId,
      content: content,
      contentType: contentType,
      attachmentIds: attachmentIds,
      priority: priority,
    );
    
    // Kiểm tra trùng lặp
    final duplicateMessage = _checkForDuplicate(queuedMessage);
    if (duplicateMessage != null) {
      // Nếu tin nhắn đã tồn tại, kiểm tra trạng thái
      if (duplicateMessage.status == MessageQueueStatus.sent ||
          duplicateMessage.status == MessageQueueStatus.delivered ||
          duplicateMessage.status == MessageQueueStatus.read) {
        // Nếu đã gửi thành công, trả về ID cũ
        return duplicateMessage.localId;
      } else if (duplicateMessage.status == MessageQueueStatus.error) {
        // Nếu lỗi, thử lại với tin nhắn mới
        _messageQueue.remove(duplicateMessage.localId);
        _sendingMessages.remove(duplicateMessage.localId);
      } else {
        // Nếu đang chờ hoặc đang gửi, cập nhật ưu tiên nếu cần
        if (priority > duplicateMessage.priority) {
          if (_sendingMessages.containsKey(duplicateMessage.localId)) {
            _sendingMessages.remove(duplicateMessage.localId);
            _messageQueue.add(queuedMessage);
          } else {
            _messageQueue.remove(duplicateMessage.localId);
            _messageQueue.add(queuedMessage);
          }
        }
        return duplicateMessage.localId;
      }
    }
    
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
  
  /// Kiểm tra tin nhắn trùng lặp
  QueuedMessage? _checkForDuplicate(QueuedMessage message) {
    // Kiểm tra trong danh sách đang gửi
    for (final sendingMessage in _sendingMessages.values) {
      if (sendingMessage.hasSameContent(message)) {
        return sendingMessage;
      }
    }
    
    // Kiểm tra trong hàng đợi
    for (final queuedMessage in _messageQueue.toList()) {
      if (queuedMessage.hasSameContent(message)) {
        return queuedMessage;
      }
    }
    
    return null;
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
  
  /// Xử lý kết nối realtime thay đổi
  void _handleRealtimeConnectionChange(ConnectionState state) {
    // Khi kết nối realtime được thiết lập hoặc ngắt kết nối
    if (state == ConnectionState.connected) {
      // Khôi phục xử lý khi có kết nối
      resumeQueue();
    } else if (state == ConnectionState.disconnected || 
              state == ConnectionState.closed ||
              state == ConnectionState.error) {
      // Tạm dừng xử lý khi mất kết nối hoặc lỗi
      pauseQueue();
    }
  }
  
  /// Xử lý hàng đợi tin nhắn
  Future<void> _processQueue() async {
    // Kiểm tra trạng thái kết nối
    final isNetworkConnected = await _connectivityService.isConnected();
    final isRealtimeConnected = _realtimeConnectionService.isConnected;
    
    if (!isNetworkConnected || !isRealtimeConnected) {
      debugPrint('No connection (network: $isNetworkConnected, realtime: $isRealtimeConnected), skipping queue processing');
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
    while (batch.length < _maxBatchSize && !_messageQueue.isEmpty) {
      final message = _messageQueue.removeFirst()!;
      
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
        localId: message.localId,
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
      // Kiểm tra xem có phải lỗi xung đột không
      if (_isConflictError(e)) {
        // Xử lý lỗi xung đột
        await _handleMessageConflict(message, e);
      } else {
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
  }
  
  /// Kiểm tra lỗi xung đột
  bool _isConflictError(dynamic error) {
    if (error is Exception) {
      final errorMsg = error.toString().toLowerCase();
      return errorMsg.contains('conflict') || 
             errorMsg.contains('duplicate') || 
             errorMsg.contains('already exists');
    }
    return false;
  }
  
  /// Xử lý xung đột tin nhắn
  Future<void> _handleMessageConflict(QueuedMessage message, dynamic error) async {
    // Đánh dấu tin nhắn là xung đột
    final updatedMessage = message.copyWithStatus(
      status: MessageQueueStatus.conflicted,
      errorMessage: 'Message conflict: ${error.toString()}',
    );
    
    // Cập nhật trong danh sách đang gửi
    _sendingMessages[message.localId] = updatedMessage;
    
    // Phát sự kiện cập nhật trạng thái
    _emitStatusUpdate(updatedMessage);
    
    debugPrint('Message conflict detected: ${message.localId}');
    
    // Cố gắng tìm tin nhắn tương ứng từ server
    try {
      // Tìm tin nhắn dựa vào nội dung và chat ID
      final serverMessages = await _messageRepository.findMessagesByContent(
        message.chatId,
        message.content,
        limit: 1,
      );
      
      if (serverMessages.isNotEmpty) {
        final serverMessage = serverMessages.first;
        
        // Cập nhật với ID từ server
        final resolvedMessage = updatedMessage.copyWithStatus(
          status: MessageQueueStatus.sent,
          serverId: serverMessage.id,
        );
        
        // Cập nhật trong danh sách đang gửi
        _sendingMessages[message.localId] = resolvedMessage;
        
        // Phát sự kiện cập nhật
        _emitStatusUpdate(_sendingMessages[message.localId]!);
        
        debugPrint('Conflict resolved: ${message.localId} -> ${serverMessage.id}');
      }
    } catch (e) {
      debugPrint('Failed to resolve message conflict: $e');
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
  
  /// Cập nhật trạng thái của tin nhắn dựa trên ID từ server
  Future<void> updateMessageStatusByServerId({
    required String serverId,
    required MessageQueueStatus newStatus,
  }) async {
    // Tìm tin nhắn bằng server ID
    final messages = _sendingMessages.values
        .where((msg) => msg.serverId == serverId)
        .toList();
    
    for (final message in messages) {
      await updateMessageStatus(
        localId: message.localId,
        newStatus: newStatus,
      );
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
    final pendingFromQueue = _messageQueue.where(
      (msg) => msg.status == MessageQueueStatus.pending
    );
    
    final pendingFromSending = _sendingMessages.values.where(
      (msg) => msg.status == MessageQueueStatus.pending || 
               msg.status == MessageQueueStatus.sending ||
               msg.status == MessageQueueStatus.failed
    );
    
    return [...pendingFromQueue, ...pendingFromSending];
  }
  
  /// Thử lại gửi tin nhắn lỗi
  Future<void> retryMessage(String localId) async {
    // Tìm tin nhắn trong danh sách đang gửi
    final message = _sendingMessages[localId];
    if (message != null && 
        (message.status == MessageQueueStatus.failed || 
         message.status == MessageQueueStatus.error ||
         message.status == MessageQueueStatus.conflicted)) {
      
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
    if (_messageQueue.contains(localId)) {
      _messageQueue.remove(localId);
      await _saveQueue();
      return true;
    }
    
    // Tìm trong danh sách đang gửi
    if (_sendingMessages.containsKey(localId)) {
      final message = _sendingMessages[localId]!;
      
      // Chỉ cho phép hủy nếu chưa gửi thành công
      if (message.status == MessageQueueStatus.pending || 
          message.status == MessageQueueStatus.failed ||
          message.status == MessageQueueStatus.error ||
          message.status == MessageQueueStatus.conflicted) {
        
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
        } else if (serverMessage.deliveredTo.isNotEmpty) {
          newStatus = MessageQueueStatus.delivered;
        } else {
          newStatus = MessageQueueStatus.sent;
        }
        
        // Cập nhật trạng thái
        await updateMessageStatus(
          localId: localMessage.localId,
          newStatus: newStatus,
        );
      }
    }
  }
  
  /// Đồng bộ tin nhắn với server
  Future<void> syncWithServer(List<ChatMessage> serverMessages) async {
    // Đồng bộ trạng thái
    await syncMessageStatuses(serverMessages);
    
    // Kiểm tra xung đột và giải quyết
    await _resolveMessageConflicts(serverMessages);
    
    // Xóa tin nhắn đã hoàn thành
    await clearCompletedMessages();
  }
  
  /// Giải quyết xung đột giữa tin nhắn cục bộ và server
  Future<void> _resolveMessageConflicts(List<ChatMessage> serverMessages) async {
    // Tạo map từ nội dung tin nhắn đến ID server
    final serverContentMap = <String, String>{};
    for (final message in serverMessages) {
      final contentKey = '${message.chatId}|${message.content}|${message.contentType}';
      serverContentMap[contentKey] = message.id;
    }
    
    // Kiểm tra các tin nhắn đang chờ và đang gửi
    for (final localMessage in [..._messageQueue.toList(), ..._sendingMessages.values]) {
      // Chỉ kiểm tra tin nhắn chưa có server ID
      if (localMessage.serverId == null) {
        final contentKey = '${localMessage.chatId}|${localMessage.content}|${localMessage.contentType}';
        
        if (serverContentMap.containsKey(contentKey)) {
          // Tìm thấy nội dung trùng lặp trên server
          final serverId = serverContentMap[contentKey]!;
          
          // Cập nhật trạng thái
          if (_sendingMessages.containsKey(localMessage.localId)) {
            _sendingMessages[localMessage.localId] = localMessage.copyWithStatus(
              status: MessageQueueStatus.sent,
              serverId: serverId,
            );
          } else {
            // Xóa khỏi hàng đợi và thêm vào đang gửi
            _messageQueue.remove(localMessage.localId);
            _sendingMessages[localMessage.localId] = localMessage.copyWithStatus(
              status: MessageQueueStatus.sent,
              serverId: serverId,
            );
          }
          
          // Phát sự kiện cập nhật
          _emitStatusUpdate(_sendingMessages[localMessage.localId]!);
        }
      }
    }
  }
  
  /// Thiết lập ưu tiên cho tin nhắn
  Future<void> setMessagePriority(String localId, int priority) async {
    // Kiểm tra trong hàng đợi
    if (_messageQueue.contains(localId)) {
      final message = _messageQueue[localId]!;
      
      // Tạo bản sao với độ ưu tiên mới
      final updatedMessage = QueuedMessage(
        localId: message.localId,
        chatId: message.chatId,
        content: message.content,
        contentType: message.contentType,
        attachmentIds: message.attachmentIds,
        retryCount: message.retryCount,
        createdAt: message.createdAt,
        status: message.status,
        serverId: message.serverId,
        errorMessage: message.errorMessage,
        priority: priority,
      );
      
      // Cập nhật trong hàng đợi
      _messageQueue.remove(localId);
      _messageQueue.add(updatedMessage);
      
      // Phát sự kiện cập nhật
      _emitStatusUpdate(updatedMessage);
      
      // Lưu hàng đợi
      await _saveQueue();
    }
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _processingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _realtimeConnectionSubscription?.cancel();
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