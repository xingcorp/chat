import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';

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

/// Lớp mô tả thông tin tệp đính kèm cần tải lên
class AttachmentInfo {
  final String filePath;
  final AttachmentType type;
  
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
  
  /// Nội dung tin nhắn
  final String content;
  
  /// Loại nội dung
  final ContentType contentType;
  
  /// Danh sách tệp đính kèm
  final List<String> attachmentIds;
  
  /// Số lần thử lại
  int retryCount;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Thời gian cập nhật
  DateTime updatedAt;
  
  /// Thời gian thử lại tiếp theo
  DateTime? scheduledRetryTime;
  
  /// Trạng thái hiện tại
  MessageQueueStatus status;
  
  /// ID trên server (sau khi gửi thành công)
  String? serverId;
  
  /// Thông báo lỗi (nếu có)
  String? errorMessage;
  
  /// Loại lỗi (nếu có)
  MessageErrorType? errorType;
  
  /// Mức độ ưu tiên
  final int priority;
  
  /// Hash nội dung để phát hiện trùng lặp
  final String contentHash;
  
  /// Constructor
  _EnhancedQueuedMessage({
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
    this.errorType,
    this.priority = 0,
  })  : localId = localId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        contentHash = _generateContentHash(chatId, content, contentType, attachmentIds);
  
  /// Tạo tin nhắn từ JSON
  factory _EnhancedQueuedMessage.fromJson(Map<String, dynamic> json) {
    return _EnhancedQueuedMessage(
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
      errorType: json['errorType'] != null 
          ? MessageErrorType.values[json['errorType']]
          : null,
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
      'scheduledRetryTime': scheduledRetryTime?.toIso8601String(),
      'status': status.toString(),
      'serverId': serverId,
      'errorMessage': errorMessage,
      'errorType': errorType?.index,
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
    // Sử dụng một hàm hash đơn giản
    var hash = 0;
    for (var i = 0; i < combinedString.length; i++) {
      hash = ((hash << 5) - hash) + combinedString.codeUnitAt(i);
      hash &= hash; // Convert to 32bit integer
    }
    return hash.toString();
  }
  
  /// Cập nhật trạng thái
  _EnhancedQueuedMessage copyWithStatus({
    required MessageQueueStatus status,
    String? serverId,
    String? errorMessage,
    MessageErrorType? errorType,
    DateTime? scheduledRetryTime,
    int? retryCount,
  }) {
    return _EnhancedQueuedMessage(
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
      errorType: errorType ?? this.errorType,
      priority: priority,
    );
  }
  
  /// Kiểm tra tin nhắn có cùng nội dung
  bool hasSameContent(_EnhancedQueuedMessage other) {
    return contentHash == other.contentHash;
  }
}

/// Thông tin về một tin nhắn cho API public
class EnhancedQueuedMessage {
  /// ID tin nhắn local
  final String localId;
  
  /// ID của chat
  final String chatId;
  
  /// Nội dung tin nhắn
  final String content;
  
  /// Loại nội dung
  final ContentType contentType;
  
  /// Trạng thái hiện tại
  final MessageQueueStatus status;
  
  /// ID trên server
  final String? serverId;
  
  /// Thông báo lỗi
  final String? errorMessage;
  
  /// Loại lỗi
  final MessageErrorType? errorType;
  
  /// Danh sách ID tệp đính kèm
  final List<String> attachmentIds;
  
  /// Danh sách tệp đính kèm chi tiết
  final List<QueuedAttachment> attachments;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Thời gian cập nhật
  final DateTime updatedAt;
  
  /// Số lần thử lại
  final int retryCount;
  
  /// Thời gian thử lại tiếp theo
  final DateTime? scheduledRetryTime;
  
  /// Tiến độ đính kèm (0-100%)
  final double attachmentProgress;
  
  /// Constructor
  EnhancedQueuedMessage({
    required this.localId,
    required this.chatId,
    required this.content,
    required this.contentType,
    required this.status,
    this.serverId,
    this.errorMessage,
    this.errorType,
    this.attachmentIds = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.scheduledRetryTime,
    this.attachmentProgress = 0.0,
  });
  
  /// Tạo từ message nội bộ
  factory EnhancedQueuedMessage._fromInternal(
    _EnhancedQueuedMessage internal, 
    List<QueuedAttachment> attachments,
  ) {
    // Tính tiến độ trung bình của các tệp đính kèm
    double avgProgress = 0;
    if (attachments.isNotEmpty) {
      double total = 0;
      for (final attachment in attachments) {
        total += attachment.progress;
      }
      avgProgress = total / attachments.length;
    }
    
    return EnhancedQueuedMessage(
      localId: internal.localId,
      chatId: internal.chatId,
      content: internal.content,
      contentType: internal.contentType,
      status: internal.status,
      serverId: internal.serverId,
      errorMessage: internal.errorMessage,
      errorType: internal.errorType,
      attachmentIds: internal.attachmentIds,
      attachments: attachments,
      createdAt: internal.createdAt,
      updatedAt: internal.updatedAt,
      retryCount: internal.retryCount,
      scheduledRetryTime: internal.scheduledRetryTime,
      attachmentProgress: avgProgress,
    );
  }
}

/// Priority queue implementation
class _MessagePriorityQueue {
  final List<_EnhancedQueuedMessage> _queue = [];
  final Map<String, _EnhancedQueuedMessage> _messageMap = {};
  
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
  
  void _sortQueue() {
    _queue.sort((a, b) {
      // Ưu tiên các tin nhắn thử lại
      final retryComp = b.retryCount.compareTo(a.retryCount);
      if (retryComp != 0) return retryComp;
      
      // Sau đó theo priority
      final priorityComp = b.priority.compareTo(a.priority);
      if (priorityComp != 0) return priorityComp;
      
      // Cuối cùng theo thời gian tạo
      return a.createdAt.compareTo(b.createdAt);
    });
  }
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
  final _messageQueue = _MessagePriorityQueue();
  
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
    
    // Đảm bảo các service khác đã khởi tạo
    await _attachmentQueueService.initialize();
    await _restoreQueue();
    
    // Theo dõi thay đổi kết nối
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_handleConnectivityChange);
    
    // Theo dõi thay đổi kết nối realtime
    _realtimeConnectionSubscription = _realtimeConnectionService.connectionStateStream
        .listen(_handleRealtimeConnectionChange);
    
    // Bắt đầu xử lý hàng đợi
    _startProcessingQueue();
    
    _initialized = true;
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
          final message = _EnhancedQueuedMessage.fromJson(item);
          
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
      final jsonList = allMessages.map((message) => message.toJson()).toList();
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
      attachmentIds: [],
    );
    
    // Kiểm tra tin nhắn trùng lặp
    final isDuplicate = _checkDuplicateMessage(contentHash);
    if (isDuplicate) {
      debugPrint('Phát hiện tin nhắn trùng lặp, không thêm vào hàng đợi');
      throw Exception('Duplicate message detected');
    }
    
    // Tạo tin nhắn mới
    final message = _EnhancedQueuedMessage(
      localId: localId,
      chatId: chatId,
      content: content,
      contentType: contentType,
      attachmentIds: [],
      status: MessageQueueStatus.pending,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
      scheduledRetryTime: null,
      serverId: null,
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
  bool _checkDuplicateMessage(String contentHash) {
    // Kiểm tra trong hàng đợi
    final queueDuplicate = _messageQueue.where((msg) => 
        msg.contentHash == contentHash &&
        msg.status != MessageQueueStatus.cancelled &&
        msg.status != MessageQueueStatus.failed).isNotEmpty;
    
    if (queueDuplicate) return true;
    
    // Kiểm tra trong danh sách đang gửi
    final sendingDuplicate = _sendingMessages.values.where((msg) => 
        msg.contentHash == contentHash &&
        msg.status != MessageQueueStatus.cancelled).isNotEmpty;
    
    return sendingDuplicate;
  }
  
  /// Thêm tin nhắn với tệp đính kèm vào hàng đợi
  Future<EnhancedQueuedMessage> enqueueMessageWithAttachments({
    required String chatId,
    required String content,
    required ContentType contentType,
    required List<AttachmentInfo> attachments,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final localId = const Uuid().v4();
    final now = DateTime.now();
    
    // Xử lý tệp đính kèm trước
    final attachmentIds = <String>[];
    
    if (attachments.isNotEmpty) {
      for (final attachment in attachments) {
        try {
          // Tạo ID cho tệp đính kèm
          final attachmentId = const Uuid().v4();
          attachmentIds.add(attachmentId);
          
          // Thêm vào hàng đợi tệp đính kèm
          await _attachmentQueueService.enqueueAttachment(
            QueuedAttachment(
              id: attachmentId,
              messageId: localId,
              filePath: attachment.filePath,
              type: attachment.type,
              status: AttachmentStatus.pending,
              progress: 0,
              createdAt: now,
              updatedAt: now,
              serverId: null,
              errorMessage: null,
            ),
          );
        } catch (e) {
          debugPrint('Lỗi thêm tệp đính kèm: $e');
          // Tiếp tục với tệp đính kèm tiếp theo
        }
      }
    }
    
    // Tạo content hash để phát hiện trùng lặp
    final contentHash = _EnhancedQueuedMessage.generateContentHash(
      chatId: chatId,
      content: content,
      contentType: contentType,
      attachmentIds: attachmentIds,
    );
    
    // Kiểm tra tin nhắn trùng lặp
    final isDuplicate = _checkDuplicateMessage(contentHash);
    if (isDuplicate) {
      // Hủy tệp đính kèm đã tạo
      for (final attachmentId in attachmentIds) {
        await _attachmentQueueService.cancelAttachment(attachmentId);
      }
      
      debugPrint('Phát hiện tin nhắn trùng lặp, không thêm vào hàng đợi');
      throw Exception('Duplicate message detected');
    }
    
    // Tạo tin nhắn mới
    final message = _EnhancedQueuedMessage(
      localId: localId,
      chatId: chatId,
      content: content,
      contentType: contentType,
      attachmentIds: attachmentIds,
      status: MessageQueueStatus.pending,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
      scheduledRetryTime: null,
      serverId: null,
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
    
    // Bắt đầu tải lên tệp đính kèm
    await _attachmentQueueService.processAttachments(localId);
    
    return EnhancedQueuedMessage.fromInternal(message);
  }
  
  /// Xử lý cập nhật trạng thái nội bộ
  void _handleInternalStatusUpdate(_EnhancedQueuedMessage message) {
    if (_messageStatusController.isClosed) return;
    
    // Lấy danh sách tệp đính kèm liên quan
    final attachments = _attachmentQueueService.getAttachmentsForMessage(message.localId);
    
    // Tạo public message
    final publicMessage = EnhancedQueuedMessage._fromInternal(message, attachments);
    
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
    _checkAttachmentCompletionStatus(message);
  }
  
  /// Xử lý sự kiện từ attachment queue
  void _handleAttachmentEvent(MessageQueueEvent event) {
    // Phát lại sự kiện
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
    if (event.type == MessageQueueEventType.attachmentUploaded && 
        event.messageId != null) {
      final message = _findMessageByAttachmentId(event.messageId!);
      if (message != null) {
        _checkAttachmentCompletionStatus(message);
      }
    }
  }
  
  /// Kiểm tra xem tất cả tệp đính kèm đã hoàn thành chưa
  void _checkAttachmentCompletionStatus(_EnhancedQueuedMessage message) {
    // Lấy tất cả attachments
    final attachments = _attachmentQueueService.getAttachmentsForMessage(message.localId);
    if (attachments.isEmpty || message.attachmentIds.isEmpty) return;
    
    // Kiểm tra xem tất cả đã hoàn thành chưa
    final allCompleted = attachments.every((a) => a.isSuccessful);
    final anyFailed = attachments.any((a) => a.status == AttachmentQueueStatus.failed);
    
    // Nếu tin nhắn đang chờ và tất cả tệp đính kèm đã hoàn thành, tiếp tục gửi tin nhắn
    if (allCompleted && message.status == MessageQueueStatus.pending) {
      _ensureProcessing();
    }
    
    // Nếu có tệp đính kèm bị lỗi và tin nhắn đang chờ, đánh dấu tin nhắn lỗi
    if (anyFailed && message.status == MessageQueueStatus.pending) {
      final updatedMessage = message.copyWithStatus(
        status: MessageQueueStatus.failed,
        errorMessage: 'Tệp đính kèm tải lên thất bại',
        errorType: MessageErrorType.fileError,
      );
      
      // Cập nhật trong hàng đợi
      if (_messageQueue.contains(message.localId)) {
        _messageQueue.add(updatedMessage);
      } else if (_sendingMessages.containsKey(message.localId)) {
        _sendingMessages[message.localId] = updatedMessage;
      }
      
      // Thông báo
      _notifyMessageStatusChanged(updatedMessage);
      _emitEvent(MessageQueueEventType.messageFailed,
        messageId: updatedMessage.localId,
        error: updatedMessage.errorMessage,
        errorType: updatedMessage.errorType,
      );
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
  void _stopProcessingQueue() {
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
           message.scheduledRetryTime != null && 
           message.scheduledRetryTime!.isBefore(now));
           
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
        msg.scheduledRetryTime != null && 
        msg.scheduledRetryTime!.isBefore(now));
        
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
          scheduledRetryTime: nextRetryTime,
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
    String? serverId,
    String? error,
    MessageErrorType? errorType,
    DateTime? scheduledTime,
  }) {
    final event = MessageQueueEvent(
      type: type,
      messageId: messageId,
      serverId: serverId,
      error: error,
      errorType: errorType,
      scheduledTime: scheduledTime,
      timestamp: DateTime.now(),
    );
    
    _eventController.add(event);
  }
  
  /// Tạm dừng xử lý hàng đợi
  Future<void> pauseQueue() async {
    if (!_isPaused) {
      _isPaused = true;
      _emitEvent(MessageQueueEventType.queuePaused);
      debugPrint('Tạm dừng hàng đợi tin nhắn');
    }
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
      _messageQueue.remove(queuedMessage);
      found = true;
    }
    
    // Tìm trong danh sách đang gửi
    if (_sendingMessages.containsKey(messageId)) {
      // Không thể xóa tin nhắn đang gửi, nhưng đánh dấu để xóa sau khi hoàn thành
      _sendingMessages[messageId] = _sendingMessages[messageId]!.copyWithStatus(
        status: MessageQueueStatus.cancelled,
      );
      found = true;
    }
    
    if (found) {
      await _saveQueue();
      _emitEvent(MessageQueueEventType.messageRemoved, messageId: messageId);
      
      // Xóa tệp đính kèm liên quan
      await _attachmentQueueService.cancelAttachmentsForMessage(messageId);
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
    await _attachmentQueueService.clearAllPendingAttachments();
  }
  
  /// Thay đổi độ ưu tiên của tin nhắn
  Future<bool> changePriority(String messageId, MessagePriority priority) async {
    bool found = false;
    
    // Tìm trong hàng đợi
    final queuedMessage = _messageQueue.where((msg) => msg.localId == messageId).firstOrNull;
    if (queuedMessage != null) {
      // Xóa khỏi hàng đợi
      _messageQueue.remove(queuedMessage);
      
      // Cập nhật độ ưu tiên
      final updatedMessage = _EnhancedQueuedMessage(
        localId: queuedMessage.localId,
        chatId: queuedMessage.chatId,
        content: queuedMessage.content,
        contentType: queuedMessage.contentType,
        attachmentIds: queuedMessage.attachmentIds,
        status: queuedMessage.status,
        retryCount: queuedMessage.retryCount,
        createdAt: queuedMessage.createdAt,
        updatedAt: DateTime.now(),
        scheduledRetryTime: queuedMessage.scheduledRetryTime,
        serverId: queuedMessage.serverId,
        errorMessage: queuedMessage.errorMessage,
        errorType: queuedMessage.errorType,
        priority: priority,
        contentHash: queuedMessage.contentHash,
      );
      
      // Thêm lại vào hàng đợi
      _messageQueue.add(updatedMessage);
      
      // Thông báo trạng thái đã thay đổi
      _notifyMessageStatusChanged(updatedMessage);
      found = true;
    }
    
    if (found) {
      await _saveQueue();
      _emitEvent(MessageQueueEventType.messagePriorityChanged, messageId: messageId);
    }
    
    return found;
  }
  
  /// Thử lại tin nhắn lỗi
  Future<bool> retryMessage(String messageId) async {
    bool found = false;
    
    // Tìm trong hàng đợi
    final queuedMessage = _messageQueue.where((msg) => msg.localId == messageId).firstOrNull;
    if (queuedMessage != null && queuedMessage.status == MessageQueueStatus.failed) {
      // Xóa khỏi hàng đợi
      _messageQueue.remove(queuedMessage);
      
      // Cập nhật trạng thái
      final updatedMessage = queuedMessage.copyWithStatus(
        status: MessageQueueStatus.pending,
        retryCount: queuedMessage.retryCount, // Không tăng số lần thử lại khi manually retry
        errorMessage: null,
        scheduledRetryTime: null,
      );
      
      // Thêm lại vào hàng đợi với độ ưu tiên cao
      _messageQueue.add(updatedMessage);
      
      // Thông báo trạng thái đã thay đổi
      _notifyMessageStatusChanged(updatedMessage);
      
      found = true;
    }
    
    if (found) {
      await _saveQueue();
      _emitEvent(MessageQueueEventType.messageRetried, messageId: messageId);
      
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
    _emitEvent(MessageQueueEventType.metricsReset);
  }
  
  /// Sư kiện lắng nghe kết nối
  void _handleConnectivityChanged(bool isConnected) {
    if (isConnected) {
      debugPrint('Kết nối mạng khôi phục, tiếp tục xử lý hàng đợi');
      if (_isPaused) {
        resumeQueue();
      } else {
        _ensureProcessing();
      }
    } else {
      debugPrint('Mất kết nối mạng, tạm dừng xử lý hàng đợi');
      pauseQueue();
    }
  }
  
  /// Sự kiện lắng nghe trạng thái realtime
  void _handleRealtimeConnectionChanged(bool isConnected) {
    if (isConnected) {
      debugPrint('Kết nối realtime khôi phục, tiếp tục xử lý hàng đợi');
      if (_isPaused) {
        resumeQueue();
      } else {
        _ensureProcessing();
      }
    }
  }
  
  /// Xử lý sự kiện từ AttachmentQueueService
  void _handleAttachmentEvent(AttachmentQueueEvent event) {
    switch (event.type) {
      case AttachmentQueueEventType.uploadCompleted:
        // Khi tệp đính kèm đã tải lên thành công, kiểm tra xem có thể gửi tin nhắn hay không
        if (event.messageId != null) {
          _ensureProcessing();
        }
        break;
        
      case AttachmentQueueEventType.uploadFailed:
        // Xử lý khi tệp đính kèm không tải lên được
        if (event.messageId != null) {
          // Tìm tin nhắn liên quan
          final message = getMessage(event.messageId!);
          if (message != null) {
            // Đánh dấu tin nhắn lỗi do tệp đính kèm
            final internalMessage = _messageQueue.where((msg) => msg.localId == event.messageId).firstOrNull;
            if (internalMessage != null) {
              _messageQueue.remove(internalMessage);
              
              final failedMessage = internalMessage.copyWithStatus(
                status: MessageQueueStatus.failed,
                errorMessage: 'Lỗi tệp đính kèm: ${event.error}',
                errorType: MessageErrorType.fileError,
              );
              
              _messageQueue.add(failedMessage);
              _notifyMessageStatusChanged(failedMessage);
              _saveQueue();
            }
          }
        }
        break;
        
      default:
        break;
    }
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