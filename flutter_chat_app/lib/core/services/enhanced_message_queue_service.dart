import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:crypto/crypto.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_chat_app/core/services/attachment_queue_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/message_error_type.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/events/message_queue_event.dart';
import 'package:flutter_chat_app/domain/models/message_queue_metrics.dart';
import 'package:flutter_chat_app/domain/models/queued_attachment.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';

/// Enum định nghĩa các loại nội dung tin nhắn
enum ContentType {
  /// Văn bản thông thường
  text,
  
  /// Hình ảnh
  image,
  
  /// Video
  video,
  
  /// Âm thanh
  audio,
  
  /// Vị trí
  location,
  
  /// Liên hệ
  contact,
  
  /// Tập tin
  file,
}

/// Enum định nghĩa các mức độ ưu tiên của tin nhắn trong hàng đợi
enum MessagePriority {
  /// Ưu tiên thấp: Tin nhắn không quan trọng, xử lý sau cùng
  low,
  
  /// Ưu tiên thông thường: Tin nhắn thông thường
  normal,
  
  /// Ưu tiên cao: Xử lý trước các tin nhắn thông thường
  high,
  
  /// Ưu tiên khẩn cấp: Xử lý ngay lập tức, thường cho tin quan trọng
  urgent,
}

/// Lớp mô tả thông tin tệp đính kèm cần tải lên
class AttachmentInfo {
  /// Đường dẫn tới tệp đính kèm
  final String filePath;
  
  /// Loại tệp đính kèm
  final AttachmentType type;
  
  /// Constructor
  AttachmentInfo({
    required this.filePath,
    required this.type,
  });
}

/// Lớp nội bộ để quản lý tin nhắn trong hàng đợi
class _EnhancedQueuedMessage {
  /// ID tin nhắn local
  final String localId;
  
  /// ID của chat
  final String chatId;
  
  /// ID của người gửi
  final String senderId;
  
  /// ID của người nhận
  final String recipientId;
  
  /// Nội dung tin nhắn
  final String content;
  
  /// Loại nội dung
  final ContentType contentType;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Thời gian cập nhật gần nhất
  final DateTime updatedAt;
  
  /// Trạng thái tin nhắn
  final MessageQueueStatus status;
  
  /// Số lần thử lại
  final int retryCount;
  
  /// Thời gian dự kiến thử lại tiếp theo
  final DateTime? nextRetryTime;
  
  /// Thông báo lỗi (nếu có)
  final String? errorMessage;
  
  /// Loại lỗi (nếu có)
  final MessageErrorType? errorType;
  
  /// Độ ưu tiên
  final MessagePriority priority;
  
  /// Content hash để kiểm tra trùng lặp
  final String contentHash;
  
  /// ID trên server (sau khi gửi thành công)
  final String? serverId;
  
  /// Danh sách ID tệp đính kèm
  final List<String> attachmentIds;
  
  /// Constructor
  _EnhancedQueuedMessage({
    required this.localId,
    required this.chatId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.contentType,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.retryCount,
    this.nextRetryTime,
    this.errorMessage,
    this.errorType,
    required this.priority,
    required this.contentHash,
    this.serverId,
    this.attachmentIds = const [],
  });
  
  /// Factory constructor để tạo từ Map
  factory _EnhancedQueuedMessage.fromMap(Map<String, dynamic> map) {
    return _EnhancedQueuedMessage(
      localId: map['localId'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      recipientId: map['recipientId'] as String,
      content: map['content'] as String,
      contentType: ContentType.values[map['contentType'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      status: MessageQueueStatus.values[map['status'] as int],
      retryCount: map['retryCount'] as int,
      nextRetryTime: map['nextRetryTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextRetryTime'] as int)
          : null,
      errorMessage: map['errorMessage'] as String?,
      errorType: map['errorType'] != null
          ? MessageErrorType.values[map['errorType'] as int]
          : null,
      priority: MessagePriority.values[map['priority'] as int],
      contentHash: map['contentHash'] as String,
      serverId: map['serverId'] as String?,
      attachmentIds: map['attachmentIds'] != null 
          ? List<String>.from(map['attachmentIds'] as List)
          : const [],
    );
  }
  
  /// Chuyển đổi thành Map
  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'chatId': chatId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'contentType': contentType.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'status': status.index,
      'retryCount': retryCount,
      'nextRetryTime': nextRetryTime?.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
      'errorType': errorType?.index,
      'priority': priority.index,
      'contentHash': contentHash,
      'serverId': serverId,
      'attachmentIds': attachmentIds,
    };
  }
  
  /// Tạo content hash từ nội dung tin nhắn
  static String generateContentHash({
    required String chatId,
    required String content,
    required ContentType contentType,
  }) {
    final input = '$chatId:$content:${contentType.index}';
    return sha256.convert(utf8.encode(input)).toString();
  }
  
  /// Tạo bản sao với trạng thái mới
  _EnhancedQueuedMessage copyWithStatus({
    required MessageQueueStatus status,
    String? serverId,
    String? errorMessage,
    MessageErrorType? errorType,
    DateTime? nextRetryTime,
    int? retryCount,
  }) {
    return _EnhancedQueuedMessage(
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      contentType: contentType,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: status,
      retryCount: retryCount ?? this.retryCount,
      nextRetryTime: nextRetryTime,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      priority: priority,
      contentHash: contentHash,
      serverId: serverId ?? this.serverId,
      attachmentIds: attachmentIds,
    );
  }
}

/// Lớp đại diện cho tin nhắn có thể truy cập công khai
class EnhancedQueuedMessage {
  /// ID tin nhắn local
  final String localId;
  
  /// ID của chat
  final String chatId;
  
  /// ID của người gửi
  final String senderId;
  
  /// ID của người nhận
  final String recipientId;
  
  /// Nội dung tin nhắn
  final String content;
  
  /// Loại nội dung
  final ContentType contentType;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Thời gian cập nhật gần nhất
  final DateTime updatedAt;
  
  /// Trạng thái tin nhắn
  final MessageQueueStatus status;
  
  /// Số lần thử lại
  final int retryCount;
  
  /// Thời gian dự kiến thử lại tiếp theo
  final DateTime? nextRetryTime;
  
  /// Thông báo lỗi (nếu có)
  final String? errorMessage;
  
  /// Loại lỗi (nếu có)
  final MessageErrorType? errorType;
  
  /// Độ ưu tiên
  final MessagePriority priority;
  
  /// ID trên server (sau khi gửi thành công)
  final String? serverId;
  
  /// Danh sách ID tệp đính kèm
  final List<String> attachmentIds;
  
  EnhancedQueuedMessage({
    required this.localId,
    required this.chatId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.contentType,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.retryCount,
    this.nextRetryTime,
    this.errorMessage,
    this.errorType,
    required this.priority,
    this.serverId,
    this.attachmentIds = const [],
  });
  
  /// Chuyển đổi từ đối tượng nội bộ
  static EnhancedQueuedMessage fromInternal(_EnhancedQueuedMessage internal) {
    return EnhancedQueuedMessage(
      localId: internal.localId,
      chatId: internal.chatId,
      senderId: internal.senderId,
      recipientId: internal.recipientId,
      content: internal.content,
      contentType: internal.contentType,
      createdAt: internal.createdAt,
      updatedAt: internal.updatedAt,
      status: internal.status,
      retryCount: internal.retryCount,
      nextRetryTime: internal.nextRetryTime,
      errorMessage: internal.errorMessage,
      errorType: internal.errorType,
      priority: internal.priority,
      serverId: internal.serverId,
      attachmentIds: internal.attachmentIds,
    );
  }
}

/// Lớp triển khai ngoại lệ tin nhắn trùng lặp
class DuplicateMessageException implements Exception {
  final String message;
  DuplicateMessageException(this.message);
  
  @override
  String toString() => message;
}

/// Lớp kết nối realtime 
enum RealtimeConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
}

/// Lớp giả định cho realtime service
class RealtimeConnectionService {
  Stream<RealtimeConnectionState> get connectionStateStream => 
      Stream<RealtimeConnectionState>.empty();
}

/// Extension cho MessageQueueEventType
extension MessageQueueEventTypeExtension on MessageQueueEventType {
  static const messagePriorityChanged = MessageQueueEventType.messageEnqueued;
  static const messageRetried = MessageQueueEventType.messageSending;
  static const metricsReset = MessageQueueEventType.queueCleared;
}

/// Priority queue implementation
class _MessagePriorityQueue {
  final List<_EnhancedQueuedMessage> _queue = [];
  final Map<String, _EnhancedQueuedMessage> _messageMap = {};
  
  // Getter để cung cấp truy cập vào messages cho sử dụng nội bộ
  List<_EnhancedQueuedMessage> get _messages => _queue;
  
  void add(_EnhancedQueuedMessage message) {
    // Xóa tin nhắn cũ nếu có
    if (_messageMap.containsKey(message.localId)) {
      remove(message.localId);
    }
    
    // Thêm tin nhắn mới
    _queue.add(message);
    _sortQueue();
    _messageMap[message.localId] = message;
  }
  
  _EnhancedQueuedMessage? removeFirst() {
    if (_queue.isEmpty) return null;
    
    final message = _queue.removeAt(0);
    _messageMap.remove(message.localId);
    return message;
  }
  
  bool get isEmpty => _queue.isEmpty;
  
  int get length => _queue.length;
  
  bool remove(String localId) {
    final message = _messageMap[localId];
    if (message == null) return false;
    
    _messageMap.remove(localId);
    _queue.removeWhere((m) => m.localId == localId);
    return true;
  }
  
  void clear() {
    _queue.clear();
    _messageMap.clear();
  }
  
  List<_EnhancedQueuedMessage> toList() {
    return List.from(_queue);
  }
  
  _EnhancedQueuedMessage? operator [](String localId) => _messageMap[localId];
  
  bool contains(String localId) => _messageMap.containsKey(localId);
  
  List<_EnhancedQueuedMessage> where(bool Function(_EnhancedQueuedMessage) test) {
    return _messageMap.values.where(test).toList();
  }
  
  bool any(bool Function(_EnhancedQueuedMessage) test) {
    return _messageMap.values.any(test);
  }
  
  void _sortQueue() {
    _queue.sort((a, b) {
      // Ưu tiên các tin nhắn thử lại
      final retryComp = b.retryCount.compareTo(a.retryCount);
      if (retryComp != 0) return retryComp;
      
      // Sau đó theo priority
      final priorityComp = b.priority.index.compareTo(a.priority.index);
      if (priorityComp != 0) return priorityComp;
      
      // Cuối cùng theo thời gian tạo
      return a.createdAt.compareTo(b.createdAt);
    });
  }
}

/// Định nghĩa trạng thái attachment queue
enum AttachmentQueueStatus {
  pending,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Service quản lý hàng đợi tin nhắn cải tiến
@lazySingleton
class EnhancedMessageQueueService {
  /// Số lần thử lại tối đa
  static const int _maxRetryCount = 5;
  
  /// Thời gian trễ cơ bản giữa các lần thử lại (ms)
  static const int _baseRetryDelayMs = 1000;
  
  /// Thời gian trễ tối đa giữa các lần thử lại (ms)
  static const int _maxRetryDelayMs = 60000; // 1 phút
  
  /// Kích thước lô tối đa
  static const int _maxBatchSize = 10;
  
  /// Khóa lưu trữ
  static const String _storageKey = 'enhanced_message_queue';
  
  /// Repository tin nhắn
  final IMessageRepository _messageRepository;
  
  /// Service kết nối
  final ConnectivityService _connectivityService;
  
  /// Service lưu trữ
  final LocalStorageService _localStorageService;
  
  /// Service kết nối realtime
  final RealtimeConnectionService _realtimeConnectionService;
  
  /// Service quản lý tệp đính kèm
  final AttachmentQueueService _attachmentQueueService;
  
  /// Hàng đợi tin nhắn
  final _MessagePriorityQueue _messageQueue = _MessagePriorityQueue();
  
  /// Tin nhắn đang gửi
  final Map<String, _EnhancedQueuedMessage> _sendingMessages = {};
  
  /// Stream controller trạng thái nội bộ
  final _internalStatusController = BehaviorSubject<_EnhancedQueuedMessage>();
  
  /// Stream controller API public
  final _messageStatusController = BehaviorSubject<EnhancedQueuedMessage>();
  
  /// Stream controller sự kiện
  final _eventController = BehaviorSubject<MessageQueueEvent>();
  
  /// Timer xử lý
  Timer? _processingTimer;
  
  /// Cờ đang xử lý
  bool _isProcessing = false;
  
  /// Cờ tạm dừng
  bool _isPaused = false;
  
  /// Metrics
  final MessageQueueMetrics _metrics = MessageQueueMetrics();
  
  /// Đăng ký các subscription
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _realtimeConnectionSubscription;
  StreamSubscription? _internalStatusSubscription;
  StreamSubscription? _attachmentStatusSubscription;
  StreamSubscription? _attachmentEventSubscription;
  
  /// Cờ khởi tạo
  bool _initialized = false;
  
  /// Constructor
  EnhancedMessageQueueService(
    this._messageRepository,
    this._localStorageService,
    this._connectivityService,
    this._realtimeConnectionService,
    this._attachmentQueueService,
  ) {
    // Thiết lập theo dõi trạng thái nội bộ
    _internalStatusSubscription = _internalStatusController.stream
        .listen(_handleInternalStatusUpdate);
    
    // Theo dõi sự kiện từ attachment queue
    _attachmentEventSubscription = _attachmentQueueService.events
        .listen(_handleAttachmentEvent);
    
    // Theo dõi trạng thái attachment
    _attachmentStatusSubscription = _attachmentQueueService.attachmentStatusStream
        .listen(_handleAttachmentStatusUpdate);
  }
  
  /// Stream trạng thái tin nhắn
  Stream<EnhancedQueuedMessage> get messageStatusStream => 
      _messageStatusController.stream;
  
  /// Stream sự kiện
  Stream<MessageQueueEvent> get events => _eventController.stream;
  
  /// Metrics
  MessageQueueMetrics get metrics => _metrics;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _restoreQueue();
    
    // Theo dõi thay đổi kết nối
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((status) => _handleConnectivityChange(status.isNotEmpty));
    
    // Theo dõi thay đổi kết nối realtime
    _realtimeConnectionSubscription = _realtimeConnectionService.connectionStateStream
        .listen(_handleRealtimeConnectionChange);
    
    // Bắt đầu xử lý hàng đợi
    _startProcessingQueue();
    
    _initialized = true;
    
    debugPrint('Enhanced MessageQueueService đã khởi tạo');
  }
  
  /// Khôi phục hàng đợi từ lưu trữ
  Future<void> _restoreQueue() async {
    try {
      final jsonString = await _localStorageService.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('Không có hàng đợi để khôi phục');
        return;
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // Xử lý các tin nhắn
      for (final item in jsonList) {
        try {
          final message = _EnhancedQueuedMessage.fromMap(item);
          
          // Nếu đang ở trạng thái gửi, đặt lại thành đang chờ
          if (message.status == MessageQueueStatus.sending) {
            final updatedMessage = message.copyWithStatus(
              status: MessageQueueStatus.pending,
            );
            _messageQueue.add(updatedMessage);
          } else {
            _messageQueue.add(message);
          }
        } catch (e) {
          debugPrint('Lỗi khôi phục tin nhắn: $e');
        }
      }
      
      debugPrint('Đã khôi phục ${_messageQueue.length} tin nhắn từ storage');
    } catch (e) {
      debugPrint('Lỗi khôi phục hàng đợi: $e');
    }
  }
  
  /// Lưu hàng đợi vào bộ nhớ
  Future<void> _saveQueue() async {
    try {
      // Kết hợp cả tin nhắn đang chờ và đang gửi
      final allMessages = <_EnhancedQueuedMessage>[];
      
      // Thêm tin nhắn từ hàng đợi
      for (final message in _messageQueue.toList()) {
        // Chỉ lưu những tin nhắn chưa hoàn thành
        if (message.status != MessageQueueStatus.sent && 
            message.status != MessageQueueStatus.cancelled) {
          allMessages.add(message);
        }
      }
      
      // Thêm tin nhắn đang gửi
      for (final message in _sendingMessages.values) {
        if (message.status != MessageQueueStatus.cancelled) {
          allMessages.add(message);
        }
      }
      
      // Chuyển đổi sang JSON
      final jsonList = allMessages.map((message) => message.toMap()).toList();
      final jsonString = jsonEncode(jsonList);
      
      // Lưu vào storage
      await _localStorageService.setString(_storageKey, jsonString);
      
      debugPrint('Đã lưu ${allMessages.length} tin nhắn vào storage');
    } catch (e) {
      debugPrint('Lỗi lưu hàng đợi: $e');
    }
  }
  
  /// Thêm tin nhắn vào hàng đợi
  Future<EnhancedQueuedMessage> enqueueMessage({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String content,
    required ContentType contentType,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final localId = const Uuid().v4();
    final now = DateTime.now();
    
    // Tạo content hash để phát hiện trùng lặp
    final contentHash = _EnhancedQueuedMessage.generateContentHash(
      chatId: chatId,
      content: content,
      contentType: contentType,
    );
    
    // Kiểm tra trùng lặp
    _checkDuplicateMessage(contentHash);
    
    // Tạo tin nhắn mới
    final message = _EnhancedQueuedMessage(
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      contentType: contentType,
      createdAt: now,
      updatedAt: now,
      status: MessageQueueStatus.pending,
      retryCount: 0,
      nextRetryTime: null,
      errorMessage: null,
      errorType: null,
      priority: priority,
      contentHash: contentHash,
    );
    
    // Thêm vào hàng đợi
    _messageQueue.add(message);
    
    // Cập nhật metrics
    _metrics.recordEnqueued();
    
    // Lưu trạng thái
    await _saveQueue();
    
    // Thông báo trạng thái đã thay đổi
    _notifyMessageStatusChanged(message);
    
    // Phát sự kiện
    _emitEvent(MessageQueueEventType.messageEnqueued, messageId: localId);
    
    // Đảm bảo xử lý
    _ensureProcessing();
    
    return EnhancedQueuedMessage.fromInternal(message);
  }
  
  /// Kiểm tra tin nhắn trùng lặp
  void _checkDuplicateMessage(String contentHash) {
    // Kiểm tra trong hàng đợi
    final queueDuplicate = _messageQueue.any((msg) => msg.contentHash == contentHash);
    
    // Kiểm tra trong danh sách đang gửi
    final sendingDuplicate = _sendingMessages.values.any((msg) => msg.contentHash == contentHash);
    
    if (queueDuplicate || sendingDuplicate) {
      throw Exception('Duplicate message detected');
    }
  }
  
  /// Thêm tin nhắn với tệp đính kèm vào hàng đợi
  Future<EnhancedQueuedMessage> enqueueMessageWithAttachments({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String content,
    required ContentType contentType,
    required List<AttachmentInfo> attachments,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final localId = const Uuid().v4();
    final now = DateTime.now();
    
    // List lưu ID của các tệp đính kèm đã tạo
    final List<String> createdAttachmentIds = [];
    
    try {
      // Tạo các tệp đính kèm trước
      for (final attachment in attachments) {
        try {
          // Thêm vào hàng đợi tệp đính kèm
          final attachmentId = await _attachmentQueueService.enqueueAttachment(
            messageId: localId,
            chatId: chatId,
            filePath: attachment.filePath,
            type: attachment.type,
          );
          
          // Lưu ID đính kèm đã tạo
          createdAttachmentIds.add(attachmentId);
        } catch (e) {
          debugPrint('Lỗi thêm tệp đính kèm: $e');
          // Tiếp tục với tệp tiếp theo
        }
      }
      
      // Tạo content hash để phát hiện trùng lặp
      final contentHash = _EnhancedQueuedMessage.generateContentHash(
        chatId: chatId,
        content: content,
        contentType: contentType,
      );
      
      // Kiểm tra trùng lặp
      _checkDuplicateMessage(contentHash);
      
      // Tạo tin nhắn mới
      final message = _EnhancedQueuedMessage(
        localId: localId,
        chatId: chatId,
        senderId: senderId,
        recipientId: recipientId,
        content: content,
        contentType: contentType,
        createdAt: now,
        updatedAt: now,
        status: MessageQueueStatus.pending,
        retryCount: 0,
        nextRetryTime: null,
        errorMessage: null,
        errorType: null,
        priority: priority,
        contentHash: contentHash,
      );
      
      // Thêm vào hàng đợi
      _messageQueue.add(message);
      
      // Cập nhật metrics
      _metrics.recordEnqueued();
      
      // Lưu trạng thái
      await _saveQueue();
      
      // Phát sự kiện
      _emitEvent(MessageQueueEventType.messageEnqueued, messageId: localId);
      
      // Đảm bảo xử lý
      _ensureProcessing();
      
      return EnhancedQueuedMessage.fromInternal(message);
    } catch (e) {
      // Nếu có lỗi, hủy tất cả tệp đính kèm đã tạo
      for (final attachmentId in createdAttachmentIds) {
        await _attachmentQueueService.cancelAttachment(attachmentId);
      }
      
      // Ném lại lỗi
      rethrow;
    }
  }
  
  /// Xử lý cập nhật trạng thái nội bộ
  void _handleInternalStatusUpdate(_EnhancedQueuedMessage message) {
    if (_messageStatusController.isClosed) return;
    
    // Lấy danh sách tệp đính kèm liên quan
    final attachments = _attachmentQueueService.getAttachmentsForMessage(message.localId);
    
    // Tạo public message
    final publicMessage = EnhancedQueuedMessage.fromInternal(message);
    
    // Phát đi
    _messageStatusController.add(publicMessage);
  }
  
  /// Xử lý cập nhật trạng thái tệp đính kèm
  void _handleAttachmentStatusUpdate(QueuedAttachment attachment) {
    // Tìm tin nhắn liên quan
    final message = _findMessageByAttachmentId(attachment.messageId);
    if (message == null) return;
    
    // Thông báo cập nhật trạng thái tin nhắn
    _notifyMessageStatusChanged(message);
    
    // Kiểm tra xem tất cả tệp đính kèm đã hoàn thành chưa
    _checkAttachmentsCompletionStatus(message.localId);
  }
  
  /// Xử lý sự kiện từ attachment queue
  void _handleAttachmentEvent(MessageQueueEvent event) {
    // Chuyển tiếp sự kiện
    _emitEvent(event.type,
      messageId: event.messageId,
      attachmentId: event.attachmentId,
      serverId: event.serverId,
      error: event.error,
      errorType: event.errorType,
      scheduledTime: event.scheduledTime,
      progress: event.progress,
    );
    
    // Nếu là sự kiện tải lên thành công, kiểm tra trạng thái tin nhắn
    if (event.type == MessageQueueEventType.attachmentUploaded && event.messageId != null) {
      _checkAttachmentsCompletionStatus(event.messageId!);
    }
  }
  
  /// Kiểm tra xem tất cả tệp đính kèm đã hoàn thành chưa
  void _checkAttachmentsCompletionStatus(String messageId) {
    // Lấy tất cả tệp đính kèm của tin nhắn
    final attachments = _attachmentQueueService.getAttachmentsForMessage(messageId);
    
    // Lấy tin nhắn từ hàng đợi
    final message = _messageQueue.where((msg) => msg.localId == messageId).firstOrNull;
    
    if (message != null && attachments.isNotEmpty) {
      // Kiểm tra xem tất cả đã hoàn thành chưa
      final allCompleted = attachments.every((a) => a.isSuccessful);
      final anyFailed = attachments.any((a) => a.status == AttachmentQueueStatus.failed);
      
      // Nếu tin nhắn đang chờ và tất cả tệp đính kèm đã hoàn thành, tiếp tục gửi tin nhắn
      if (allCompleted && message.status == MessageQueueStatus.pending) {
        _ensureProcessing();
      }
      
      // Nếu có tệp đính kèm bị lỗi vĩnh viễn, đánh dấu tin nhắn lỗi
      else if (anyFailed && message.status == MessageQueueStatus.pending) {
        // Xóa khỏi hàng đợi
        final removedIndex = _messageQueue._messages.indexOf(message);
        if (removedIndex >= 0) {
          _messageQueue._messages.removeAt(removedIndex);
        }
        
        // Cập nhật trạng thái
        final updatedMessage = message.copyWithStatus(
          status: MessageQueueStatus.failed,
          errorMessage: 'Tệp đính kèm tải lên thất bại',
          errorType: MessageErrorType.fileError,
        );
        
        // Thêm lại vào hàng đợi
        _messageQueue.add(updatedMessage);
        
        // Thông báo thay đổi
        _notifyMessageStatusChanged(updatedMessage);
        
        // Phát sự kiện
        _emitEvent(MessageQueueEventType.messageFailed, 
          messageId: updatedMessage.localId,
          error: updatedMessage.errorMessage,
          errorType: updatedMessage.errorType,
        );
        
        // Lưu hàng đợi
        _saveQueue();
      }
    }
  }
  
  /// Tìm tin nhắn liên quan đến attachment
  _EnhancedQueuedMessage? _findMessageByAttachmentId(String messageId) {
    // Tìm trong hàng đợi
    final queuedMessage = _messageQueue[messageId];
    if (queuedMessage != null) return queuedMessage;
    
    // Tìm trong đang gửi
    return _sendingMessages[messageId];
  }
  
  /// Bắt đầu xử lý hàng đợi
  void _startProcessingQueue() {
    if (_processingTimer != null) {
      _processingTimer!.cancel();
    }
    
    // Xử lý hàng đợi mỗi 2 giây
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processQueue();
    });
    
    // Xử lý ngay lập tức
    _processQueue();
  }
  
  /// Dừng xử lý hàng đợi
  void _stopProcessingTimer() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }
  
  /// Đảm bảo bắt đầu xử lý
  void _ensureProcessing() {
    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }
  }
  
  /// Xử lý hàng đợi
  Future<void> _processQueue() async {
    // Bỏ qua nếu đã đang xử lý hoặc bị tạm dừng
    if (_isProcessing || _isPaused) return;
    
    _isProcessing = true;
    
    try {
      // Kiểm tra kết nối mạng
      final isConnected = await _connectivityService.checkNetworkStatus();
      if (!isConnected) {
        debugPrint('Không có kết nối mạng, bỏ qua xử lý hàng đợi');
        return;
      }
      
      // Xử lý các tin nhắn sẵn sàng
      await _processReadyMessages();
      
      // Kiểm tra các lần thử lại đã lên lịch
      _checkScheduledRetries();
      
    } catch (e) {
      debugPrint('Lỗi xử lý hàng đợi: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Xử lý các tin nhắn sẵn sàng
  Future<void> _processReadyMessages() async {
    // Thời gian hiện tại
    final now = DateTime.now();
    
    // Thu thập tin nhắn cần xử lý
    final messagesToProcess = <_EnhancedQueuedMessage>[];
    
    // Lấy các tin nhắn đang chờ hoặc đã lên lịch thử lại
    while (messagesToProcess.length < _maxBatchSize && !_messageQueue.isEmpty) {
      final message = _messageQueue.removeFirst()!;
      
      // Kiểm tra xem tin nhắn đã sẵn sàng xử lý chưa
      final isReadyForProcessing = message.status == MessageQueueStatus.pending ||
          (message.status == MessageQueueStatus.failed && 
           message.nextRetryTime != null && 
           message.nextRetryTime!.isBefore(now));
           
      // Kiểm tra xem tất cả tệp đính kèm đã sẵn sàng chưa
      final allAttachmentsReady = _checkAllAttachmentsReady(message);
      
      if (isReadyForProcessing && allAttachmentsReady) {
        messagesToProcess.add(message);
      } else {
        // Đưa lại vào hàng đợi nếu chưa sẵn sàng
        _messageQueue.add(message);
        break;
      }
    }
    
    // Xử lý các tin nhắn đã thu thập
    for (final message in messagesToProcess) {
      await _sendMessage(message);
    }
  }
  
  /// Kiểm tra xem tất cả tệp đính kèm đã sẵn sàng chưa
  bool _checkAllAttachmentsReady(_EnhancedQueuedMessage message) {
    // Nếu không có tệp đính kèm, luôn sẵn sàng
    if (message.attachmentIds.isEmpty) return true;
    
    // Lấy tất cả tệp đính kèm
    final attachments = _attachmentQueueService.getAttachmentsForMessage(message.localId);
    
    // Nếu không tìm thấy tệp đính kèm nào, coi là sẵn sàng
    if (attachments.isEmpty) return true;
    
    // Kiểm tra xem tất cả đã hoàn thành chưa
    return attachments.every((a) => a.isSuccessful);
  }
  
  /// Kiểm tra các lần thử lại đã lên lịch
  void _checkScheduledRetries() {
    final now = DateTime.now();
    
    // Tìm các tin nhắn đã lên lịch thử lại
    final retryMessages = _messageQueue.where((msg) => 
        msg.status == MessageQueueStatus.failed && 
        msg.nextRetryTime != null && 
        msg.nextRetryTime!.isBefore(now));
        
    if (retryMessages.isNotEmpty) {
      debugPrint('Tìm thấy ${retryMessages.length} tin nhắn cần thử lại');
      _ensureProcessing();
    }
  }
  
  /// Gửi một tin nhắn
  Future<void> _sendMessage(_EnhancedQueuedMessage message) async {
    // Cập nhật trạng thái thành đang gửi
    final updatedMessage = message.copyWithStatus(
      status: MessageQueueStatus.sending,
    );
    
    // Thêm vào danh sách đang gửi
    _sendingMessages[updatedMessage.localId] = updatedMessage;
    
    // Cập nhật metrics
    _metrics.recordProcessingStarted();
    
    // Thông báo trạng thái đã thay đổi
    _notifyMessageStatusChanged(updatedMessage);
    _emitEvent(MessageQueueEventType.messageSending,
      messageId: updatedMessage.localId,
    );
    
    // Bắt đầu thời gian đo
    final startTime = DateTime.now();
    
    try {
      // Thu thập IDs của tệp đính kèm đã tải lên server
      final serverAttachmentIds = <String>[];
      if (updatedMessage.attachmentIds.isNotEmpty) {
        final attachments = _attachmentQueueService.getAttachmentsForMessage(updatedMessage.localId);
        for (final attachment in attachments) {
          if (attachment.isSuccessful && attachment.serverId != null) {
            serverAttachmentIds.add(attachment.serverId!);
          }
        }
      }
      
      // Gửi tin nhắn lên server
      final result = await _messageRepository.sendMessage(
        chatId: updatedMessage.chatId,
        content: updatedMessage.content,
        senderId: 'current_user_id', // Cần lấy từ user service
        contentType: updatedMessage.contentType.toString().split('.').last,
        attachmentIds: serverAttachmentIds,
      );
      
      // Cập nhật thời gian hoàn thành
      final duration = DateTime.now().difference(startTime);
      _metrics.addSendDuration(duration);
      
      // Đánh dấu đã gửi
      final sentMessage = updatedMessage.copyWithStatus(
        status: MessageQueueStatus.sent,
        serverId: result.id,
      );
      
      // Xóa khỏi danh sách đang gửi
      _sendingMessages.remove(updatedMessage.localId);
      
      // Cập nhật metrics
      _metrics.recordSuccess(sendDuration: duration);
      _metrics.recordProcessingCompleted();
      
      // Thông báo thành công
      _notifyMessageStatusChanged(sentMessage);
      _emitEvent(MessageQueueEventType.messageSent,
        messageId: sentMessage.localId,
        serverId: sentMessage.serverId,
      );
      
      debugPrint('Tin nhắn gửi thành công: ${sentMessage.localId}');
      
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn: $e');
      
      // Phân loại lỗi
      final errorType = _categorizeError(e);
      
      // Tăng số lần thử lại
      final retryCount = updatedMessage.retryCount + 1;
      
      // Kiểm tra xem đã đạt giới hạn thử lại chưa
      if (retryCount >= _maxRetryCount) {
        // Đánh dấu lỗi vĩnh viễn
        final failedMessage = updatedMessage.copyWithStatus(
          status: MessageQueueStatus.failed,
          retryCount: retryCount,
          errorMessage: 'Lỗi sau $retryCount lần thử: $e',
          errorType: errorType,
        );
        
        // Xóa khỏi danh sách đang gửi
        _sendingMessages.remove(updatedMessage.localId);
        
        // Cập nhật metrics
        _metrics.recordFailure(errorType);
        _metrics.recordProcessingCompleted();
        
        // Thông báo thất bại
        _notifyMessageStatusChanged(failedMessage);
        _emitEvent(MessageQueueEventType.messageFailed,
          messageId: failedMessage.localId,
          error: failedMessage.errorMessage,
          errorType: errorType,
        );
        
        debugPrint('Tin nhắn lỗi vĩnh viễn: ${failedMessage.localId}');
      } else {
        // Lên lịch thử lại với độ trễ tăng dần
        final delayMs = _calculateRetryDelay(retryCount, errorType);
        final nextRetryTime = DateTime.now().add(Duration(milliseconds: delayMs));
        
        // Cập nhật thông tin thử lại
        final retryMessage = updatedMessage.copyWithStatus(
          status: MessageQueueStatus.failed,
          retryCount: retryCount,
          errorMessage: 'Thử lại $retryCount: $e',
          errorType: errorType,
          nextRetryTime: nextRetryTime,
        );
        
        // Xóa khỏi danh sách đang gửi
        _sendingMessages.remove(updatedMessage.localId);
        
        // Thêm lại vào hàng đợi
        _messageQueue.add(retryMessage);
        
        // Cập nhật metrics
        _metrics.recordRetry();
        _metrics.recordProcessingCompleted();
        
        // Thông báo thử lại
        _notifyMessageStatusChanged(retryMessage);
        _emitEvent(MessageQueueEventType.messageRetryScheduled,
          messageId: retryMessage.localId,
          scheduledTime: nextRetryTime,
          errorType: errorType,
          error: retryMessage.errorMessage,
        );
        
        debugPrint('Tin nhắn lên lịch thử lại: ${retryMessage.localId} lúc $nextRetryTime');
      }
    }
    
    // Lưu trạng thái hàng đợi
    await _saveQueue();
  }
  
  /// Phân loại lỗi
  MessageErrorType _categorizeError(dynamic error) {
    if (error is TimeoutException) {
      return MessageErrorType.networkError;
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('Connection refused')) {
      return MessageErrorType.networkError;
    } else if (error.toString().contains('status code: 401') || 
               error.toString().contains('status code: 403')) {
      return MessageErrorType.authError;
    } else if (error.toString().contains('status code: 429')) {
      return MessageErrorType.rateLimitError;
    } else if (error.toString().contains('status code: 4')) {
      return MessageErrorType.validationError;
    } else if (error.toString().contains('status code: 5')) {
      return MessageErrorType.serverError;
    } else if (error.toString().contains('File not found') || 
               error.toString().contains('No such file')) {
      return MessageErrorType.fileError;
    }
    
    return MessageErrorType.unknown;
  }
  
  /// Tính thời gian trễ cho việc thử lại
  int _calculateRetryDelay(int retryCount, MessageErrorType errorType) {
    // Độ trễ cơ bản với backoff tùy thuộc vào loại lỗi
    int baseDelay;
    
    switch (errorType) {
      case MessageErrorType.networkError:
        // Độ trễ ngắn hơn cho lỗi mạng
        baseDelay = _baseRetryDelayMs * pow(1.5, retryCount).toInt();
        break;
      case MessageErrorType.serverError:
        // Độ trễ dài hơn cho lỗi server
        baseDelay = _baseRetryDelayMs * pow(2.5, retryCount).toInt();
        break;
      case MessageErrorType.rateLimitError:
        // Độ trễ dài cho lỗi giới hạn tốc độ
        baseDelay = _baseRetryDelayMs * 5 + (15000 * retryCount);
        break;
      case MessageErrorType.authError:
        // Độ trễ dài cho lỗi xác thực
        baseDelay = _baseRetryDelayMs * 5;
        break;
      default:
        baseDelay = _baseRetryDelayMs * pow(2, retryCount).toInt();
        break;
    }
    
    // Giới hạn tối đa
    final maxDelay = min(baseDelay, _maxRetryDelayMs);
    
    // Thêm nhiễu để tránh thundering herd
    final jitter = Random().nextInt((maxDelay * 0.3).toInt());
    
    return maxDelay + jitter;
  }
  
  /// Thông báo trạng thái tin nhắn đã thay đổi
  void _notifyMessageStatusChanged(_EnhancedQueuedMessage message) {
    // Thông báo trong kênh nội bộ
    _internalStatusController.add(message);
    
    // Chuyển đổi sang API public và thông báo
    final publicMessage = EnhancedQueuedMessage.fromInternal(message);
    _messageStatusController.add(publicMessage);
  }
  
  /// Phát sự kiện
  void _emitEvent(MessageQueueEventType type, {
    String? messageId,
    String? attachmentId,
    String? serverId,
    String? error,
    MessageErrorType? errorType,
    DateTime? scheduledTime,
    double? progress,
  }) {
    if (!_eventController.isClosed) {
      _eventController.add(MessageQueueEvent(
        type: type,
        messageId: messageId,
        attachmentId: attachmentId,
        serverId: serverId,
        error: error,
        errorType: errorType,
        scheduledTime: scheduledTime,
        progress: progress,
      ));
    }
  }
  
  /// Tạm dừng xử lý hàng đợi
  void pauseQueue({String? reason}) {
    if (_isPaused) return;
    
    _isPaused = true;
    
    // Hủy timer xử lý
    _stopProcessingTimer();
    
    // Phát sự kiện
    _emitEvent(MessageQueueEventType.queuePaused);
    
    debugPrint('Queue tạm dừng${reason != null ? ": $reason" : ""}');
  }
  
  /// Tiếp tục xử lý hàng đợi
  Future<void> resumeQueue() async {
    if (_isPaused) {
      _isPaused = false;
      _emitEvent(MessageQueueEventType.queueResumed);
      debugPrint('Tiếp tục hàng đợi tin nhắn');
      _ensureProcessing();
    }
  }
  
  /// Xóa tin nhắn khỏi hàng đợi
  Future<bool> removeMessage(String messageId) async {
    bool found = false;
    
    // Tìm trong hàng đợi
    final queuedMessage = _messageQueue.where((msg) => msg.localId == messageId).firstOrNull;
    if (queuedMessage != null) {
      final index = _messageQueue._messages.indexOf(queuedMessage);
      if (index >= 0) {
        _messageQueue._messages.removeAt(index);
        found = true;
      }
    }
    
    // Tìm trong danh sách đang gửi
    if (_sendingMessages.containsKey(messageId)) {
      _sendingMessages.remove(messageId);
      found = true;
    }
    
    if (found) {
      // Cập nhật metrics
      _metrics.recordProcessingCompleted();
      
      // Lưu hàng đợi
      await _saveQueue();
      
      // Phát sự kiện
      _emitEvent(MessageQueueEventType.messageRemoved, messageId: messageId);
      
      // Xóa tệp đính kèm liên quan
      final attachments = _attachmentQueueService.getAttachmentsForMessage(messageId);
      for (final attachment in attachments) {
        await _attachmentQueueService.cancelAttachment(attachment.localId);
      }
    }
    
    return found;
  }
  
  /// Xóa tất cả tin nhắn trong hàng đợi
  Future<void> clearQueue() async {
    // Xóa tất cả tin nhắn đang chờ
    _messageQueue.clear();
    
    // Đánh dấu tất cả tin nhắn đang gửi là hủy
    for (final messageId in _sendingMessages.keys) {
      _sendingMessages[messageId] = _sendingMessages[messageId]!.copyWithStatus(
        status: MessageQueueStatus.cancelled,
      );
    }
    
    await _saveQueue();
    _emitEvent(MessageQueueEventType.queueCleared);
    
    // Xóa tất cả tệp đính kèm
    await _cancelAllAttachments();
  }
  
  /// Xóa tất cả tập tin đính kèm đang chờ
  Future<void> _cancelAllAttachments() async {
    final attachments = _attachmentQueueService.getAllAttachments();
    for (final attachment in attachments) {
      await _attachmentQueueService.cancelAttachment(attachment.localId);
    }
  }
  
  /// Thử lại tin nhắn lỗi
  Future<bool> retryMessage(String messageId) async {
    bool found = false;
    
    // Tìm trong hàng đợi
    final queuedMessage = _messageQueue.where((msg) => msg.localId == messageId).firstOrNull;
    if (queuedMessage != null && queuedMessage.status == MessageQueueStatus.failed) {
      // Xóa khỏi hàng đợi
      _messageQueue.remove(messageId);
      
      // Cập nhật trạng thái
      final updatedMessage = queuedMessage.copyWithStatus(
        status: MessageQueueStatus.pending,
        retryCount: queuedMessage.retryCount, // Không tăng số lần thử lại khi manually retry
        errorMessage: null,
        nextRetryTime: null,
      );
      
      // Thêm lại vào hàng đợi với độ ưu tiên cao
      _messageQueue.add(updatedMessage);
      
      // Thông báo trạng thái đã thay đổi
      _notifyMessageStatusChanged(updatedMessage);
      
      found = true;
    }
    
    if (found) {
      await _saveQueue();
      _emitEvent(MessageQueueEventType.messageSending, messageId: messageId);
      
      // Đảm bảo xử lý ngay
      _ensureProcessing();
    }
    
    return found;
  }
  
  /// Lấy tin nhắn từ ID
  EnhancedQueuedMessage? getMessage(String messageId) {
    // Tìm trong hàng đợi
    final queuedMessage = _messageQueue.where((msg) => msg.localId == messageId).firstOrNull;
    if (queuedMessage != null) {
      return EnhancedQueuedMessage.fromInternal(queuedMessage);
    }
    
    // Tìm trong danh sách đang gửi
    if (_sendingMessages.containsKey(messageId)) {
      return EnhancedQueuedMessage.fromInternal(_sendingMessages[messageId]!);
    }
    
    return null;
  }
  
  /// Lấy danh sách tin nhắn
  List<EnhancedQueuedMessage> getAllMessages() {
    // Kết hợp cả tin nhắn đang chờ và đang gửi
    final allMessages = <EnhancedQueuedMessage>[];
    
    // Thêm tin nhắn từ hàng đợi
    for (final message in _messageQueue.toList()) {
      allMessages.add(EnhancedQueuedMessage.fromInternal(message));
    }
    
    // Thêm tin nhắn đang gửi
    for (final message in _sendingMessages.values) {
      allMessages.add(EnhancedQueuedMessage.fromInternal(message));
    }
    
    // Sắp xếp theo thời gian tạo
    allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return allMessages;
  }
  
  /// Lấy số lượng tin nhắn trong hàng đợi
  int get queueSize => _messageQueue.length + _sendingMessages.length;
  
  /// Đặt lại metrics
  void resetMetrics() {
    _metrics.reset();
    _emitEvent(MessageQueueEventType.queueCleared);
  }
  
  /// Sư kiện lắng nghe kết nối
  void _handleConnectivityChange(bool isConnected) {
    debugPrint('Trạng thái kết nối thay đổi: ${isConnected ? 'có kết nối' : 'mất kết nối'}');
    
    if (isConnected) {
      // Có kết nối trở lại, tiếp tục hàng đợi
      if (_isPaused) {
        resumeQueue();
      } else {
        _ensureProcessing();
      }
    } else {
      // Mất kết nối, tạm dừng hàng đợi
      pauseQueue(reason: 'Mất kết nối mạng');
    }
  }
  
  /// Sự kiện lắng nghe trạng thái realtime
  void _handleRealtimeConnectionChange(RealtimeConnectionState state) {
    debugPrint('Trạng thái kết nối realtime thay đổi: $state');
    
    if (state == RealtimeConnectionState.connected) {
      // Kết nối realtime thành công, kiểm tra trạng thái tin nhắn
      _syncSentMessages();
    }
  }
  
  /// Đồng bộ trạng thái tin nhắn đã gửi
  Future<void> _syncSentMessages() async {
    // Lấy trạng thái các tin nhắn đã gửi từ server
    try {
      final sentIds = _sendingMessages.keys.toList();
      if (sentIds.isEmpty) return;
      
      final statuses = await _getMessageStatuses(sentIds);
      
      for (final status in statuses) {
        if (_sendingMessages.containsKey(status.localId)) {
          // Cập nhật trạng thái tin nhắn
          final message = _sendingMessages[status.localId]!;
          final updatedMessage = message.copyWithStatus(
            status: status.delivered 
                ? MessageQueueStatus.delivered 
                : (status.sent ? MessageQueueStatus.sent : message.status),
          );
          
          _sendingMessages[status.localId] = updatedMessage;
          _notifyMessageStatusChanged(updatedMessage);
        }
      }
    } catch (e) {
      debugPrint('Lỗi đồng bộ trạng thái tin nhắn: $e');
    }
  }
  
  /// Lấy trạng thái tin nhắn từ server (giả lập)
  Future<List<MessageStatus>> _getMessageStatuses(List<String> messageIds) async {
    // Giả lập API - trong thực tế sẽ gọi đến repository thật
    return messageIds.map((id) => MessageStatus(
      localId: id,
      sent: true,
      delivered: Random().nextBool(),
    )).toList();
  }
  
  /// Hủy tài nguyên
  Future<void> dispose() async {
    // Hủy các subscription
    await _connectivitySubscription?.cancel();
    await _realtimeConnectionSubscription?.cancel();
    await _internalStatusSubscription?.cancel();
    await _attachmentStatusSubscription?.cancel();
    await _attachmentEventSubscription?.cancel();
    
    // Hủy timers
    _processingTimer?.cancel();
    
    // Đóng controllers
    await _internalStatusController.close();
    await _messageStatusController.close();
    await _eventController.close();
    
    // Đánh dấu không được khởi tạo
    _initialized = false;
  }
}

/// Lớp chứa thông tin trạng thái tin nhắn
class MessageStatus {
  final String localId;
  final bool sent;
  final bool delivered;
  
  MessageStatus({
    required this.localId,
    required this.sent,
    required this.delivered,
  });
} 