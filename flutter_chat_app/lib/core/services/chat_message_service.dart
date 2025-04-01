import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/services/graphql_subscription_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';

/// Service quản lý tin nhắn chat
@lazySingleton
class ChatMessageService {
  final MessageQueueService _messageQueueService;
  final RealtimeConnectionService _realtimeConnectionService;
  final GraphQLSubscriptionService _subscriptionService;
  final IMessageRepository _messageRepository;
  
  /// Stream controller cho các tin nhắn mới
  final _newMessageController = StreamController<ChatMessage>.broadcast();
  
  /// Stream controller cho các tin nhắn đã được cập nhật
  final _messageStatusController = StreamController<ChatMessage>.broadcast();
  
  /// Flag đánh dấu đã khởi tạo
  bool _initialized = false;
  
  /// Constructor
  ChatMessageService(
    this._messageQueueService,
    this._realtimeConnectionService,
    this._subscriptionService,
    this._messageRepository,
  );
  
  /// Kiểm tra service đã được khởi tạo chưa
  bool get isInitialized => _initialized;
  
  /// Stream của tin nhắn mới
  Stream<ChatMessage> get messageStream => _newMessageController.stream;
  
  /// Stream của trạng thái tin nhắn (đã đọc, đã gửi, ...)
  Stream<ChatMessage> get messageStatusStream => _messageStatusController.stream;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _setupSubscriptions();
      _initialized = true;
      debugPrint('ChatMessageService initialized');
    } catch (e) {
      debugPrint('Error initializing ChatMessageService: $e');
    }
  }
  
  /// Thiết lập các subscription
  void _setupSubscriptions() {
    try {
      // Đăng ký nhận tin nhắn mới
      _subscriptionService.subscribeToNewMessages().listen((message) {
        _handleNewMessage(message);
      });
      
      // Đăng ký nhận cập nhật trạng thái tin nhắn
      _subscriptionService.subscribeToMessageStatusChanges().listen((message) {
        _handleMessageStatusUpdate(message);
      });
      
      // Theo dõi tin nhắn từ hàng đợi
      _messageQueueService.messageStatusStream.listen(_handleQueuedMessageStatus);
      
    } catch (e) {
      debugPrint('Error setting up subscriptions: $e');
    }
  }
  
  /// Xử lý tin nhắn mới
  void _handleNewMessage(ChatMessage message) {
    _newMessageController.add(message);
  }
  
  /// Xử lý cập nhật trạng thái tin nhắn
  void _handleMessageStatusUpdate(ChatMessage message) {
    _messageStatusController.add(message);
  }
  
  /// Xử lý tin nhắn từ hàng đợi
  void _handleQueuedMessageStatus(QueuedMessage queuedMessage) {
    // Chuyển đổi từ QueuedMessage sang ChatMessage
    // Thực hiện trong implementation thực tế
  }
  
  /// Gửi tin nhắn văn bản
  Future<String> sendTextMessage(String chatId, String content) async {
    // Implementation thực tế sẽ gửi tin nhắn
    // Bây giờ chỉ trả về một ID
    return _messageQueueService.enqueueMessage(
      chatId: chatId,
      message: content,
      contentType: ContentType.text,
    );
  }
  
  /// Gửi tin nhắn hình ảnh
  Future<String> sendImageMessage(String chatId, String imageUrl, {String? caption}) async {
    final content = caption ?? '';
    return _messageQueueService.enqueueMessage(
      chatId: chatId,
      message: content,
      contentType: ContentType.image,
      attachmentIds: [imageUrl],
    );
  }
  
  /// Đóng và giải phóng tài nguyên
  void dispose() {
    _newMessageController.close();
    _messageStatusController.close();
  }
} 