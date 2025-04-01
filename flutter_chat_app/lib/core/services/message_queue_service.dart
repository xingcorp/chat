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
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
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

/// A priority queue implementation using a heap
class HeapPriorityQueue<E> {
  /// The underlying list that stores the heap
  final List<E> _queue = <E>[];
  
  /// The comparison function to determine priority
  final int Function(E a, E b) _comparison;
  
  /// Creates a new priority queue with the provided comparison function
  HeapPriorityQueue(this._comparison);
  
  /// Adds an element to the queue
  void add(E element) {
    _queue.add(element);
    _siftUp(_queue.length - 1);
  }
  
  /// Removes and returns the highest priority element
  E removeFirst() {
    if (_queue.isEmpty) {
      throw StateError('Cannot remove from an empty queue');
    }
    
    final result = _queue.first;
    final last = _queue.removeLast();
    
    if (_queue.isNotEmpty) {
      _queue[0] = last;
      _siftDown(0);
    }
    
    return result;
  }
  
  /// Sift an element up to maintain heap property
  void _siftUp(int index) {
    var child = index;
    while (child > 0) {
      final parent = (child - 1) ~/ 2;
      if (_comparison(_queue[child], _queue[parent]) >= 0) break;
      
      // Swap with parent
      final temp = _queue[parent];
      _queue[parent] = _queue[child];
      _queue[child] = temp;
      
      child = parent;
    }
  }
  
  /// Sift an element down to maintain heap property
  void _siftDown(int index) {
    final half = _queue.length ~/ 2;
    var parent = index;
    
    while (parent < half) {
      var child = 2 * parent + 1; // Left child
      
      // Find the higher priority child
      final rightChild = child + 1;
      if (rightChild < _queue.length && 
          _comparison(_queue[child], _queue[rightChild]) > 0) {
        child = rightChild;
      }
      
      // Check if we need to swap
      if (_comparison(_queue[parent], _queue[child]) <= 0) break;
      
      // Swap with the child
      final temp = _queue[parent];
      _queue[parent] = _queue[child];
      _queue[child] = temp;
      
      parent = child;
    }
  }
  
  /// Check if the queue is empty
  bool get isEmpty => _queue.isEmpty;
  
  /// Check if the queue is not empty
  bool get isNotEmpty => _queue.isNotEmpty;
  
  /// Get the number of elements in the queue
  int get length => _queue.length;
  
  /// Clear the queue
  void clear() {
    _queue.clear();
  }
}

/// Class to manage message priority queue
class MessagePriorityQueue {
  /// Internal queue using heap-based priority queue
  final _queue = _createPriorityQueue();
  
  /// Map for quick message lookup by ID
  final Map<String, QueuedMessage> _messageMap = {};
  
  /// Create a priority queue for queued messages
  static HeapPriorityQueue<QueuedMessage> _createPriorityQueue() {
    return HeapPriorityQueue<QueuedMessage>(
      (a, b) {
        // Compare by retry count (messages with more retries get higher priority)
        final priorityComparison = b.retryCount.compareTo(a.retryCount);
        if (priorityComparison != 0) return priorityComparison;
        
        // If retry count is equal, compare by creation time (older messages first)
        return a.createdAt.compareTo(b.createdAt);
      },
    );
  }
  
  /// Add a message to the queue
  void add(QueuedMessage message) {
    // Remove old message if it exists
    if (_messageMap.containsKey(message.localId)) {
      _messageMap.remove(message.localId);
    }
    
    // Add new message
    _queue.add(message);
    _messageMap[message.localId] = message;
  }
  
  /// Get and remove the first message from the queue
  QueuedMessage? removeFirst() {
    if (_queue.isEmpty) return null;
    
    final message = _queue.removeFirst();
    _messageMap.remove(message.localId);
    return message;
  }
  
  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;
  
  /// Get number of messages in queue
  int get length => _queue.length;
  
  /// Remove a message from the queue
  bool remove(String localId) {
    final message = _messageMap[localId];
    if (message == null) return false;
    
    // Can't remove directly from HeapPriorityQueue
    // so we recreate the queue
    _messageMap.remove(localId);
    
    final tempList = <QueuedMessage>[];
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (item.localId != localId) {
        tempList.add(item);
      }
    }
    
    // Add back all messages except the removed one
    for (final item in tempList) {
      _queue.add(item);
    }
    
    return true;
  }
  
  /// Clear all messages from the queue
  void clear() {
    _queue.clear();
    _messageMap.clear();
  }
  
  /// Get all messages as a list
  List<QueuedMessage> toList() {
    final result = <QueuedMessage>[];
    final tempList = <QueuedMessage>[];
    
    // Get all messages
    while (_queue.isNotEmpty) {
      final message = _queue.removeFirst();
      result.add(message);
      tempList.add(message);
    }
    
    // Add messages back to the queue
    for (final message in tempList) {
      _queue.add(message);
    }
    
    return result;
  }
  
  /// Find message by ID
  QueuedMessage? operator [](String localId) => _messageMap[localId];
  
  /// Check if message exists
  bool contains(String localId) => _messageMap.containsKey(localId);
  
  /// Filter messages by condition
  List<QueuedMessage> where(bool Function(QueuedMessage) test) {
    return _messageMap.values.where(test).toList();
  }
}

/// Service for managing message queue
@lazySingleton
class MessageQueueService {
  /// Maximum retry attempts before marking as terminal error
  static const int _maxRetryCount = 5;
  
  /// Base delay between retry attempts (ms)
  static const int _baseRetryDelayMs = 1000;
  
  /// Maximum delay between retry attempts (ms)
  static const int _maxRetryDelayMs = 60000; // 1 minute
  
  /// Maximum batch size for processing messages
  static const int _maxBatchSize = 10;
  
  /// Storage key for saving queue
  static const String _storageKey = 'message_queue';
  
  /// Message repository
  final IMessageRepository _messageRepository;
  
  /// Connectivity service
  final ConnectivityService _connectivityService;
  
  /// Local storage service
  final LocalStorageService _localStorageService;
  
  /// Realtime connection service
  final RealtimeConnectionService _realtimeConnectionService;
  
  /// Message priority queue
  final _messageQueue = MessagePriorityQueue();
  
  /// Currently sending messages
  final Map<String, QueuedMessage> _sendingMessages = {};
  
  /// Status update stream controller
  final _messageStatusController = BehaviorSubject<QueuedMessage>();
  
  /// Queue processing timer
  Timer? _processingTimer;
  
  /// Flag indicating processing in progress
  bool _isProcessing = false;
  
  /// Flag indicating queue is paused
  bool _isPaused = false;
  
  /// Connectivity subscription
  StreamSubscription? _connectivitySubscription;
  
  /// Realtime connection subscription
  StreamSubscription? _realtimeConnectionSubscription;
  
  /// Initialization flag
  bool _initialized = false;
  
  /// Constructor
  MessageQueueService(
    this._messageRepository,
    this._localStorageService,
    this._connectivityService,
    this._realtimeConnectionService,
  );
  
  /// Stream of message status updates
  Stream<QueuedMessage> get messageStatusStream => _messageStatusController.stream;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Make sure other services are initialized
    await _restoreQueue();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_handleConnectivityChange);
    
    // Listen for realtime connection changes
    _realtimeConnectionSubscription = _realtimeConnectionService.connectionStateStream
        .listen(_handleRealtimeConnectionChange);
    
    // Start queue processing
    _startProcessingQueue();
    
    _initialized = true;
  }
  
  /// Restore queue from local storage
  Future<void> _restoreQueue() async {
    try {
      final queueJson = await _localStorageService.getString(_storageKey);
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List<dynamic>;
        
        // Restore messages to queue
        for (final messageData in queueData) {
          try {
            final message = QueuedMessage.fromJson(messageData);
            
            // Reset sending status to pending if needed
            if (message.status == MessageQueueStatus.sending) {
              _messageQueue.add(message.copyWithStatus(
                status: MessageQueueStatus.pending,
              ));
            } else if (message.status != MessageQueueStatus.sent && 
                       message.status != MessageQueueStatus.failed && 
                       message.status != MessageQueueStatus.conflicted) {
              _messageQueue.add(message);
            }
          } catch (e) {
            debugPrint('Failed to parse message: $e');
          }
        }
        
        debugPrint('Restored ${_messageQueue.length} messages to queue');
      }
    } catch (e) {
      debugPrint('Failed to restore message queue: $e');
    }
  }
  
  /// Save queue to local storage
  Future<void> _saveQueue() async {
    try {
      // Combine pending and sending messages
      final allMessages = [..._messageQueue.toList(), ..._sendingMessages.values];
      
      // Only save non-terminal messages
      final uncompletedMessages = allMessages.where((msg) => 
          msg.status != MessageQueueStatus.sent && 
          msg.status != MessageQueueStatus.failed && 
          msg.status != MessageQueueStatus.conflicted).toList();
      
      final queueJson = jsonEncode(uncompletedMessages.map((m) => m.toJson()).toList());
      await _localStorageService.setString(_storageKey, queueJson);
    } catch (e) {
      debugPrint('Failed to save message queue: $e');
    }
  }
  
  /// Add a message to the queue
  Future<String> enqueueMessage({
    required String chatId,
    required String message,
    required ContentType contentType,
    List<String> attachmentIds = const [],
  }) async {
    // Create a new queued message
    final queuedMessage = QueuedMessage(
      chatId: chatId,
      content: message,
      contentType: contentType,
      attachmentIds: attachmentIds,
      status: MessageQueueStatus.pending,
    );
    
    // Add to queue
    _messageQueue.add(queuedMessage);
    
    // Notify listeners
    _notifyMessageStatusChanged(queuedMessage);
    
    // Save queue
    await _saveQueue();
    
    // Start processing if not already
    _ensureProcessing();
    
    return queuedMessage.localId;
  }
  
  /// Start queue processing
  void _startProcessingQueue() {
    if (_processingTimer != null) {
      _processingTimer!.cancel();
    }
    
    // Process queue every 2 seconds
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processQueue();
    });
    
    // Process immediately
    _processQueue();
  }
  
  /// Stop queue processing
  void _stopProcessingQueue() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }
  
  /// Ensure processing is started
  void _ensureProcessing() {
    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }
  }
  
  /// Process the queue
  Future<void> _processQueue() async {
    // Skip if already processing or paused
    if (_isProcessing || _isPaused) return;
    
    _isProcessing = true;
    
    try {
      // Check network connectivity
      final isConnected = await _connectivityService.checkNetworkStatus();
      if (!isConnected) {
        debugPrint('No network connection, skipping queue processing');
        return;
      }
      
      // Process ready messages
      await _processReadyMessages();
      
      // Check for scheduled retries
      _checkScheduledRetries();
      
    } catch (e) {
      debugPrint('Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Process messages that are ready to send
  Future<void> _processReadyMessages() async {
    // Get current time
    final now = DateTime.now();
    
    // Collect messages to process in this batch
    final messagesToProcess = <QueuedMessage>[];
    
    // Get messages with pending status or scheduled for retry
    while (messagesToProcess.length < _maxBatchSize && !_messageQueue.isEmpty) {
      final message = _messageQueue.removeFirst()!;
      
      // Check if message is ready for processing
      final isReadyForProcessing = message.status == MessageQueueStatus.pending ||
          (message.status == MessageQueueStatus.failed && 
           message.scheduledRetryTime != null && 
           message.scheduledRetryTime!.isBefore(now));
           
      if (isReadyForProcessing) {
        messagesToProcess.add(message);
      } else {
        // Put it back in the queue if not ready
        _messageQueue.add(message);
        break;
      }
    }
    
    // Process collected messages
    for (final message in messagesToProcess) {
      await _sendMessage(message);
    }
  }
  
  /// Check for scheduled retries
  void _checkScheduledRetries() {
    final now = DateTime.now();
    
    // Find messages scheduled for retry
    final retryMessages = _messageQueue.where((msg) => 
        msg.status == MessageQueueStatus.failed && 
        msg.scheduledRetryTime != null && 
        msg.scheduledRetryTime!.isBefore(now));
        
    if (retryMessages.isNotEmpty) {
      debugPrint('Found ${retryMessages.length} messages ready for retry');
      _ensureProcessing();
    }
  }
  
  /// Send a message
  Future<void> _sendMessage(QueuedMessage message) async {
    // Update status to sending
    final updatedMessage = message.copyWithStatus(
      status: MessageQueueStatus.sending,
    );
    
    // Add to sending messages map
    _sendingMessages[updatedMessage.localId] = updatedMessage;
    
    // Notify listeners
    _notifyMessageStatusChanged(updatedMessage);
    
    try {
      // Send message to server
      final result = await _messageRepository.sendMessage(
        chatId: updatedMessage.chatId,
        content: updatedMessage.content,
        senderId: 'current_user_id', // This should come from a user service
        contentType: updatedMessage.contentType.toString(),
        attachmentIds: updatedMessage.attachmentIds,
      );
      
      // Mark as sent
      final sentMessage = updatedMessage.copyWithStatus(
        status: MessageQueueStatus.sent,
        serverId: result.id,
      );
      
      // Remove from sending messages
      _sendingMessages.remove(updatedMessage.localId);
      
      // Notify listeners
      _notifyMessageStatusChanged(sentMessage);
      
      debugPrint('Message sent successfully: ${sentMessage.localId}');
    } catch (e) {
      debugPrint('Failed to send message: $e');
      
      // Increment retry count
      final retryCount = updatedMessage.retryCount + 1;
      
      // Check if max retries reached
      if (retryCount >= _maxRetryCount) {
        // Mark as failed terminal state
        final failedMessage = updatedMessage.copyWithStatus(
          status: MessageQueueStatus.failed,
          retryCount: retryCount,
          errorMessage: 'Failed after $retryCount attempts: $e',
        );
        
        // Remove from sending messages
        _sendingMessages.remove(updatedMessage.localId);
        
        // Notify listeners
        _notifyMessageStatusChanged(failedMessage);
        
        debugPrint('Message failed permanently: ${failedMessage.localId}');
      } else {
        // Schedule for retry with exponential backoff
        final delayMs = _calculateRetryDelay(retryCount);
        final nextRetryTime = DateTime.now().add(Duration(milliseconds: delayMs));
        
        // Update message with retry info
        final retryMessage = updatedMessage.copyWithStatus(
          status: MessageQueueStatus.failed,
          retryCount: retryCount,
          errorMessage: 'Retry $retryCount: $e',
          scheduledRetryTime: nextRetryTime,
        );
        
        // Remove from sending messages
        _sendingMessages.remove(updatedMessage.localId);
        
        // Add back to queue
        _messageQueue.add(retryMessage);
        
        // Notify listeners
        _notifyMessageStatusChanged(retryMessage);
        
        debugPrint('Message scheduled for retry: ${retryMessage.localId} at $nextRetryTime');
      }
    }
    
    // Save queue state
    await _saveQueue();
  }
  
  /// Calculate retry delay with exponential backoff
  int _calculateRetryDelay(int retryCount) {
    // Exponential backoff with jitter
    final baseDelay = _baseRetryDelayMs * pow(2, retryCount);
    final maxDelay = min(baseDelay.toInt(), _maxRetryDelayMs);
    
    // Add jitter to avoid thundering herd
    final jitter = Random().nextInt((maxDelay * 0.3).toInt());
    
    return maxDelay + jitter;
  }
  
  /// Handle connectivity changes
  void _handleConnectivityChange(List<dynamic> _) {
    final isConnected = _connectivityService.isConnected;
    
    if (isConnected) {
      // Resume processing if we have connection
      _isPaused = false;
      _ensureProcessing();
    } else {
      // Pause processing if no connection
      _isPaused = true;
    }
  }
  
  /// Handle realtime connection changes
  void _handleRealtimeConnectionChange(dynamic connectionState) {
    // When realtime connection is established, process queue
    if (connectionState == ConnectionState.connected) {
      _ensureProcessing();
    }
  }
  
  /// Notify about message status changes
  void _notifyMessageStatusChanged(QueuedMessage message) {
    if (!_messageStatusController.isClosed) {
      _messageStatusController.add(message);
    }
  }
  
  /// Get all messages in the queue
  List<QueuedMessage> getAllMessages() {
    return [..._messageQueue.toList(), ..._sendingMessages.values];
  }
  
  /// Get a message by ID
  QueuedMessage? getMessageById(String localId) {
    return _messageQueue[localId] ?? _sendingMessages[localId];
  }
  
  /// Cancel a pending message
  Future<bool> cancelMessage(String localId) async {
    // Find message
    final message = getMessageById(localId);
    if (message == null) return false;
    
    // Can only cancel pending or failed messages
    if (message.status != MessageQueueStatus.pending && 
        message.status != MessageQueueStatus.failed) {
      return false;
    }
    
    // Mark as cancelled - using failed status since cancelled is not available
    final cancelledMessage = message.copyWithStatus(
      status: MessageQueueStatus.failed,
      errorMessage: 'Cancelled by user',
    );
    
    // Remove from queues
    if (_sendingMessages.containsKey(localId)) {
      _sendingMessages.remove(localId);
    } else {
      _messageQueue.remove(localId);
    }
    
    // Notify listeners
    _notifyMessageStatusChanged(cancelledMessage);
    
    // Save queue
    await _saveQueue();
    
    return true;
  }
  
  /// Retry a failed message
  Future<bool> retryMessage(String localId) async {
    // Find message
    final message = getMessageById(localId);
    if (message == null) return false;
    
    // Can only retry failed messages
    if (message.status != MessageQueueStatus.failed) {
      return false;
    }
    
    // Reset for retry
    final retryMessage = message.copyWithStatus(
      status: MessageQueueStatus.pending,
    );
    
    // Add to queue
    _messageQueue.add(retryMessage);
    
    // Remove from sending if there
    _sendingMessages.remove(localId);
    
    // Notify listeners
    _notifyMessageStatusChanged(retryMessage);
    
    // Save queue
    await _saveQueue();
    
    // Ensure processing
    _ensureProcessing();
    
    return true;
  }
  
  /// Pause queue processing
  void pauseQueue() {
    _isPaused = true;
  }
  
  /// Resume queue processing
  void resumeQueue() {
    _isPaused = false;
    _ensureProcessing();
  }
  
  /// Dispose resources
  void dispose() {
    _stopProcessingQueue();
    _connectivitySubscription?.cancel();
    _realtimeConnectionSubscription?.cancel();
    _messageStatusController.close();
  }
} 