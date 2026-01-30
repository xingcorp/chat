import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/core/services/realtime_messaging_service.dart';
import 'package:flutter_chat_app/data/mappers/socket_io_event_mapper.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';

/// Composite subscription helper
class CompositeSubscription {
  final List<StreamSubscription> _subscriptions;
  
  CompositeSubscription(this._subscriptions);
  
  Future<void> cancel() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
  }
}

/// Service quản lý tin nhắn chat, kết hợp việc gửi/nhận tin nhắn
/// với hàng đợi tin nhắn và kết nối realtime
@lazySingleton
class ChatMessageService {
  /// Service quản lý hàng đợi tin nhắn
  final MessageQueueService _messageQueueService;
  
  /// Service quản lý real-time messaging
  final RealtimeMessagingService _realtimeService;
  
  /// Socket.IO event mapper
  final SocketIOEventMapper _eventMapper;
  
  /// Repository xử lý tin nhắn
  final IMessageRepository _messageRepository;
  
  /// Controller cho stream tin nhắn mới
  final _newMessagesController = BehaviorSubject<ChatMessage>();
  
  /// Controller cho stream cập nhật tin nhắn
  final _updatedMessagesController = BehaviorSubject<ChatMessage>();
  
  /// Controller cho stream xóa tin nhắn
  final _deletedMessagesController = BehaviorSubject<String>();
  
  /// Controller cho stream trạng thái kết nối
  final _connectionStatusController = BehaviorSubject<bool>.seeded(false);
  
  /// Map lưu trữ các subscription theo chatId
  final Map<String, CompositeSubscription> _chatSubscriptions = {};
  
  /// Đã khởi tạo
  bool _initialized = false;
  
  /// Subscription theo dõi trạng thái kết nối
  StreamSubscription? _connectionStateSubscription;
  
  /// Subscription theo dõi trạng thái tin nhắn
  StreamSubscription? _messageStatusSubscription;
  
  /// Constructor
  ChatMessageService(
    this._messageQueueService,
    this._realtimeService,
    this._eventMapper,
    this._messageRepository,
  );
  
  /// Stream tin nhắn mới
  Stream<ChatMessage> get newMessages => _newMessagesController.stream;
  
  /// Stream cập nhật tin nhắn
  Stream<ChatMessage> get updatedMessages => _updatedMessagesController.stream;
  
  /// Stream xóa tin nhắn
  Stream<String> get deletedMessages => _deletedMessagesController.stream;
  
  /// Stream trạng thái kết nối
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  /// Đang kết nối
  bool get isConnected => _connectionStatusController.value;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Khởi tạo message queue service
    await _messageQueueService.initialize();
    
    // Lắng nghe trạng thái kết nối từ RealtimeMessagingService
    _connectionStateSubscription = _realtimeService.connectionState.listen((state) {
      final isConnected = state == WebSocketConnectionState.connected;
      _connectionStatusController.add(isConnected);
      
      if (isConnected) {
        // Đồng bộ tin nhắn khi kết nối lại
        _synchronizeMessages();
      }
    });
    
    // Kết nối realtime
    await _realtimeService.connect();
    
    _initialized = true;
  }
  
  /// Đồng bộ tin nhắn khi kết nối lại
  Future<void> _synchronizeMessages() async {
    try {
      // Since getPendingMessages is no longer accessible, let's sync recent messages for active chats
      for (final chatId in _chatSubscriptions.keys) {
        await _synchronizeChatMessages(chatId);
      }
    } catch (e) {
      debugPrint('Error synchronizing messages: $e');
    }
  }
  
  /// Đồng bộ tin nhắn cho một chat cụ thể
  Future<void> _synchronizeChatMessages(String chatId) async {
    try {
      // Lấy tin nhắn gần đây nhưng không làm gì với chúng vì không còn truy cập được syncWithServer
      await _messageRepository.getRecentMessages(chatId, 50);
      
      // Let MessageQueueService handle the internal sync
      // We no longer have access to the syncWithServer method
    } catch (e) {
      debugPrint('Error synchronizing messages for chat $chatId: $e');
    }
  }
  
  /// Đăng ký lắng nghe tin nhắn của một chat
  Future<void> subscribeToChat(String chatId) async {
    // Hủy subscription hiện tại nếu có
    _chatSubscriptions[chatId]?.cancel();
    
    // Join Socket.IO room
    await _realtimeService.sendMessage(
      type: 'conversation:joined',
      data: {'conversationId': chatId},
    );
    
    // Subscribe to message:sent events
    final messageSentSub = _realtimeService.messages
        .where((msg) => msg.type == 'message:sent')
        .where((msg) => msg.data['conversationId'] == chatId)
        .listen((msg) {
          try {
            final chatMessage = _eventMapper.mapMessageSent(msg.data);
            _newMessagesController.add(chatMessage);
          } catch (e) {
            debugPrint('Error mapping message:sent: $e');
          }
        });
    
    // Subscribe to message:read events
    final messageReadSub = _realtimeService.messages
        .where((msg) => msg.type == 'message:read')
        .where((msg) => msg.data['conversationId'] == chatId)
        .listen((msg) {
          try {
            final readEvent = _eventMapper.mapMessageRead(msg.data);
            // Update message read status in repository
            _messageRepository.markAsRead(readEvent.messageId);
          } catch (e) {
            debugPrint('Error mapping message:read: $e');
          }
        });
    
    // Subscribe to message:edit events
    final messageEditSub = _realtimeService.messages
        .where((msg) => msg.type == 'message:edit')
        .where((msg) => msg.data['conversationId'] == chatId)
        .listen((msg) {
          try {
            final chatMessage = _eventMapper.mapMessageEdit(msg.data);
            _updatedMessagesController.add(chatMessage);
          } catch (e) {
            debugPrint('Error mapping message:edit: $e');
          }
        });
    
    // Subscribe to message:delete events
    final messageDeleteSub = _realtimeService.messages
        .where((msg) => msg.type == 'message:delete')
        .where((msg) => msg.data['conversationId'] == chatId)
        .listen((msg) {
          try {
            final deleteEvent = _eventMapper.mapMessageDelete(msg.data);
            _deletedMessagesController.add(deleteEvent.messageId);
          } catch (e) {
            debugPrint('Error mapping message:delete: $e');
          }
        });
    
    // Combine all subscriptions
    _chatSubscriptions[chatId] = CompositeSubscription([
      messageSentSub,
      messageReadSub,
      messageEditSub,
      messageDeleteSub,
    ]);
    
    // Đồng bộ tin nhắn
    await _synchronizeChatMessages(chatId);
  }
  
  /// Hủy đăng ký lắng nghe tin nhắn của một chat
  Future<void> unsubscribeFromChat(String chatId) async {
    // Hủy subscription
    await _chatSubscriptions[chatId]?.cancel();
    _chatSubscriptions.remove(chatId);
    
    // Leave Socket.IO room
    await _realtimeService.sendMessage(
      type: 'conversation:leaved',
      data: {'conversationId': chatId},
    );
  }
  
  /// Gửi tin nhắn
  Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String content,
    required ContentType contentType,
    List<String> attachmentIds = const [],
  }) async {
    // Thêm tin nhắn vào hàng đợi
    final queuedMessage = await _messageQueueService.enqueueMessage(
      chatId: chatId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      contentType: contentType,
    );
    
    return queuedMessage.localId;
  }
  
  /// Hủy tin nhắn đang chờ gửi
  Future<bool> cancelMessage(String localId) async {
    return await _messageQueueService.cancelMessage(localId);
  }
  
  /// Thử lại gửi tin nhắn bị lỗi
  Future<bool> retryMessage(String localId) async {
    return await _messageQueueService.retryMessage(localId);
  }
  
  /// Đánh dấu tin nhắn đã đọc
  Future<void> markMessageAsRead(String messageId) async {
    await _messageRepository.markAsRead(messageId);
  }
  
  /// Đánh dấu tất cả tin nhắn trong chat đã đọc
  Future<void> markChatAsRead(String chatId) async {
    await _messageRepository.markChatAsRead(chatId);
  }
  
  /// Dispose
  Future<void> dispose() async {
    _initialized = false;
    
    // Hủy các subscriptions
    _connectionStateSubscription?.cancel();
    _messageStatusSubscription?.cancel();
    
    // Hủy các chat subscriptions
    for (final subscription in _chatSubscriptions.values) {
      await subscription.cancel();
    }
    _chatSubscriptions.clear();
    
    // Đóng các controllers
    _newMessagesController.close();
    _updatedMessagesController.close();
    _deletedMessagesController.close();
    _connectionStatusController.close();
  }
} 