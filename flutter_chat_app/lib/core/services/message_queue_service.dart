import 'dart:async';
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
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:rxdart/rxdart.dart';

/// Public queued message class for external API
class QueuedMessage {
  /// Unique ID of the message
  final String localId;

  /// Chat ID this message belongs to
  final String chatId;
  
  /// Message content
  final String content;
  
  /// Content type
  final ContentType contentType;
  
  /// Current status
  final MessageQueueStatus status;
  
  /// Server ID after sending
  final String? serverId;
  
  /// Error message if failed
  final String? errorMessage;
  
  /// Attachment IDs
  final List<String> attachmentIds;
  
  /// Created at timestamp
  final DateTime createdAt;
  
  /// Last updated at timestamp
  final DateTime updatedAt;
  
  /// Number of retry attempts
  final int retryCount;
  
  /// Scheduled retry time
  final DateTime? scheduledRetryTime;
  
  /// Constructor
  QueuedMessage({
    required this.localId,
    required this.chatId,
    required this.content,
    required this.contentType,
    required this.status,
    this.serverId,
    this.errorMessage,
    this.attachmentIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.scheduledRetryTime,
  });
  
  /// Create from internal message
  factory QueuedMessage._fromInternal(_InternalQueuedMessage internal) {
    return QueuedMessage(
      localId: internal.localId,
      chatId: internal.chatId,
      content: internal.content,
      contentType: internal.contentType,
      status: internal.status,
      serverId: internal.serverId,
      errorMessage: internal.errorMessage,
      attachmentIds: internal.attachmentIds,
      createdAt: internal.createdAt,
      updatedAt: internal.updatedAt,
      retryCount: internal.retryCount,
      scheduledRetryTime: internal.scheduledRetryTime,
    );
  }
}

/// Internal model for queue management, separate from domain model
class _InternalQueuedMessage {
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
  _InternalQueuedMessage({
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
  factory _InternalQueuedMessage.fromJson(Map<String, dynamic> json) {
    return _InternalQueuedMessage(
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
  _InternalQueuedMessage copyWithStatus({
    required MessageQueueStatus status,
    String? serverId,
    String? errorMessage,
    DateTime? scheduledRetryTime,
    int? retryCount,
  }) {
    return _InternalQueuedMessage(
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
  bool hasSameContent(_InternalQueuedMessage other) {
    return contentHash == other.contentHash;
  }
}

/// Service quản lý hàng đợi tin nhắn
@lazySingleton
class MessageQueueService {
  final IMessageRepository _messageRepository;
  final LocalStorageService _localStorageService;
  final ConnectivityService _connectivityService;
  final RealtimeConnectionService _realtimeConnectionService;
  
  /// Các tin nhắn trong hàng đợi
  final List<_InternalQueuedMessage> _messageQueue = [];
  
  /// Các tin nhắn đang được gửi
  final Map<String, _InternalQueuedMessage> _sendingMessages = {};
  
  /// Controller cho stream trạng thái tin nhắn
  final _messageStatusController = StreamController<QueuedMessage>.broadcast();
  
  /// Controller cho stream trạng thái nội bộ
  final _internalStatusController = StreamController<_InternalQueuedMessage>.broadcast();
  
  /// Khóa lưu trữ
  final String _storageKey = 'message_queue';
  
  /// Có đang xử lý hàng đợi không
  bool _isProcessingQueue = false;
  
  /// Có đã khởi tạo không
  bool _initialized = false;
  
  /// Timer xử lý hàng đợi
  Timer? _queueProcessorTimer;
  
  /// Subscription theo dõi kết nối
  StreamSubscription? _connectivitySubscription;
  
  /// Subscription theo dõi kết nối realtime
  StreamSubscription? _realtimeConnectionSubscription;
  
  /// Subscription theo dõi trạng thái nội bộ
  StreamSubscription? _internalStatusSubscription;
  
  /// Constructor
  MessageQueueService(
    this._messageRepository,
    this._localStorageService,
    this._connectivityService,
    this._realtimeConnectionService,
  ) {
    // Set up internal status subscription to map to public API
    _internalStatusSubscription = _internalStatusController.stream
        .listen((message) {
          _messageStatusController.add(QueuedMessage._fromInternal(message));
        });
  }
  
  /// Stream of message status updates
  Stream<QueuedMessage> get messageStatusStream => _messageStatusController.stream;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Khôi phục hàng đợi từ storage
      await _restoreQueue();
      
      // Lắng nghe kết nối
      _connectivitySubscription = _connectivityService.onConnectivityChanged
          .listen(_handleConnectivityChange);
      
      // Lắng nghe kết nối realtime
      _realtimeConnectionSubscription = _realtimeConnectionService.connectionStateStream
          .listen(_handleRealtimeConnectionChange);
      
      // Bắt đầu xử lý hàng đợi
      _startProcessingQueue();
      
      _initialized = true;
      debugPrint('MessageQueueService initialized');
    } catch (e) {
      debugPrint('Error initializing MessageQueueService: $e');
    }
  }
  
  /// Thêm tin nhắn vào hàng đợi
  Future<String> enqueueMessage({
    required String chatId, 
    required String message, 
    required ContentType contentType,
    List<String> attachmentIds = const [],
  }) async {
    // Tạo tin nhắn mới
    final queuedMessage = _InternalQueuedMessage(
      chatId: chatId,
      content: message,
      contentType: contentType,
      attachmentIds: attachmentIds,
      status: MessageQueueStatus.pending,
    );
    
    // Thêm vào hàng đợi
    _messageQueue.add(queuedMessage);
    
    // Lưu hàng đợi
    await _saveQueue();
    
    // Thông báo trạng thái
    _internalStatusController.add(queuedMessage);
    
    // Bắt đầu xử lý hàng đợi nếu chưa chạy
    if (!_isProcessingQueue) {
      _processQueue();
    }
    
    return queuedMessage.localId;
  }
  
  /// Bắt đầu xử lý hàng đợi
  void _startProcessingQueue() {
    // Xử lý hàng đợi mỗi 5 giây
    _queueProcessorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _processQueue(),
    );
    
    // Xử lý hàng đợi ngay lập tức
    _processQueue();
  }
  
  /// Xử lý hàng đợi tin nhắn
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    
    try {
      // Kiểm tra kết nối
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        _isProcessingQueue = false;
        return;
      }
      
      // Lấy tin nhắn từ đầu hàng đợi
      if (_messageQueue.isNotEmpty) {
        final message = _messageQueue.removeAt(0);
        
        // Đánh dấu là đang gửi
        final sendingMessage = message.copyWithStatus(status: MessageQueueStatus.sending);
        _sendingMessages[sendingMessage.localId] = sendingMessage;
        _internalStatusController.add(sendingMessage);
        
        // Cập nhật storage
        await _saveQueue();
        
        // Gửi tin nhắn
        try {
          final result = await _messageRepository.sendMessage(
            chatId: sendingMessage.chatId,
            content: sendingMessage.content,
            senderId: 'current_user_id', // In real app, get from auth service
            contentType: sendingMessage.contentType,
            attachmentIds: sendingMessage.attachmentIds,
          );
          
          // Cập nhật trạng thái thành công
          final updatedMessage = sendingMessage.copyWithStatus(
            status: MessageQueueStatus.sent,
            serverId: result.id,
          );
          
          _sendingMessages.remove(sendingMessage.localId);
          _internalStatusController.add(updatedMessage);
          
          // Cập nhật storage
          await _saveQueue();
          
        } catch (e) {
          // Cập nhật trạng thái lỗi
          final errorMessage = sendingMessage.copyWithStatus(
            status: MessageQueueStatus.failed,
            errorMessage: e.toString(),
            retryCount: sendingMessage.retryCount + 1,
          );
          
          _sendingMessages.remove(sendingMessage.localId);
          
          // Nếu còn cơ hội thử lại, thêm lại vào hàng đợi
          if (errorMessage.retryCount < 3) {
            // Delay dần khi thử lại nhiều lần
            final delay = pow(2, errorMessage.retryCount).toInt() * 1000;
            final retryTime = DateTime.now().add(Duration(milliseconds: delay));
            
            final retryMessage = errorMessage.copyWithStatus(
              status: MessageQueueStatus.pending,
              scheduledRetryTime: retryTime,
            );
            
            _messageQueue.add(retryMessage);
            _internalStatusController.add(retryMessage);
          } else {
            // Đã hết số lần thử lại
            _internalStatusController.add(errorMessage);
          }
          
          // Cập nhật storage
          await _saveQueue();
        }
      }
    } catch (e) {
      debugPrint('Error processing queue: $e');
    } finally {
      _isProcessingQueue = false;
      
      // Nếu còn tin nhắn trong hàng đợi, tiếp tục xử lý
      if (_messageQueue.isNotEmpty) {
        _processQueue();
      }
    }
  }
  
  /// Xử lý sự kiện thay đổi kết nối
  void _handleConnectivityChange(List<dynamic> _) {
    // Chỉ cần có bất kỳ sự thay đổi nào, thử xử lý hàng đợi
    _processQueue();
  }
  
  /// Xử lý sự kiện thay đổi kết nối realtime
  void _handleRealtimeConnectionChange(dynamic _) {
    // Chỉ cần có bất kỳ sự thay đổi kết nối, thử xử lý hàng đợi
    _processQueue();
  }
  
  /// Hủy tin nhắn đang chờ
  Future<bool> cancelMessage(String localId) async {
    // Tìm trong hàng đợi
    final index = _messageQueue.indexWhere((m) => m.localId == localId);
    if (index >= 0) {
      final message = _messageQueue.removeAt(index);
      final cancelledMessage = message.copyWithStatus(status: MessageQueueStatus.cancelled);
      _internalStatusController.add(cancelledMessage);
      await _saveQueue();
      return true;
    }
    
    // Tìm trong đang gửi
    if (_sendingMessages.containsKey(localId)) {
      final message = _sendingMessages.remove(localId);
      if (message != null) {
        final cancelledMessage = message.copyWithStatus(status: MessageQueueStatus.cancelled);
        _internalStatusController.add(cancelledMessage);
        await _saveQueue();
        return true;
      }
    }
    
    return false;
  }
  
  /// Thử lại gửi tin nhắn lỗi
  Future<bool> retryMessage(String localId) async {
    // Tìm tin nhắn
    final messageFinder = (m) => m.localId == localId && m.status == MessageQueueStatus.failed;
    final existingIndex = _messageQueue.indexWhere(messageFinder);
    
    if (existingIndex >= 0) {
      // Đã có trong hàng đợi, chỉ cần cập nhật trạng thái
      final message = _messageQueue[existingIndex];
      final updatedMessage = message.copyWithStatus(
        status: MessageQueueStatus.pending,
        errorMessage: null,
      );
      
      _messageQueue[existingIndex] = updatedMessage;
      _internalStatusController.add(updatedMessage);
      await _saveQueue();
      
      // Xử lý hàng đợi
      _processQueue();
      
      return true;
    } else {
      // Tìm trong storage lịch sử (nếu cần)
      // ...
      
      return false;
    }
  }
  
  /// Lưu hàng đợi vào storage
  Future<void> _saveQueue() async {
    try {
      // Kết hợp tin nhắn đang đợi và đang gửi
      final allMessages = [..._messageQueue, ..._sendingMessages.values];
      
      // Chỉ lưu tin nhắn chưa hoàn thành
      final uncompletedMessages = allMessages.where((msg) => !msg.status.isTerminal).toList();
      
      final messageJsonList = uncompletedMessages.map((m) => m.toJson()).toList();
      final queueJson = jsonEncode(messageJsonList);
      
      // Lưu vào storage
      await _localStorageService.setString(_storageKey, queueJson);
    } catch (e) {
      debugPrint('Failed to save message queue: $e');
    }
  }
  
  /// Khôi phục hàng đợi từ storage
  Future<void> _restoreQueue() async {
    try {
      // getString returns String? directly, not a Future
      final queueJsonString = _localStorageService.getString(_storageKey);
      
      if (queueJsonString != null) {
        final queueData = jsonDecode(queueJsonString) as List<dynamic>;
        
        // Khôi phục tin nhắn vào hàng đợi
        for (final messageData in queueData) {
          try {
            final message = _InternalQueuedMessage.fromJson(messageData);
            
            // Reset trạng thái sending thành pending nếu cần
            if (message.status == MessageQueueStatus.sending) {
              _messageQueue.add(message.copyWithStatus(
                status: MessageQueueStatus.pending,
              ));
            } else if (!message.status.isTerminal) {
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
  
  /// Đóng và giải phóng tài nguyên
  void dispose() {
    _queueProcessorTimer?.cancel();
    _connectivitySubscription?.cancel();
    _realtimeConnectionSubscription?.cancel();
    _internalStatusSubscription?.cancel();
    _messageStatusController.close();
    _internalStatusController.close();
    _initialized = false;
  }
} 