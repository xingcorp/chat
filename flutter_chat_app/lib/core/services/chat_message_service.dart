import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/services/graphql_subscription_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';

/// Service quản lý tin nhắn chat, kết hợp việc gửi/nhận tin nhắn
/// với hàng đợi tin nhắn và kết nối realtime
@lazySingleton
class ChatMessageService {
  /// Service quản lý hàng đợi tin nhắn
  final MessageQueueService _messageQueueService;
  
  /// Service quản lý kết nối realtime
  final RealtimeConnectionService _realtimeConnectionService;
  
  /// Service quản lý GraphQL subscription
  final GraphQLSubscriptionService _subscriptionService;
  
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
  final Map<String, StreamSubscription> _chatSubscriptions = {};
  
  /// Đã khởi tạo
  bool _initialized = false;
  
  /// Subscription theo dõi trạng thái kết nối
  StreamSubscription? _connectionStateSubscription;
  
  /// Subscription theo dõi trạng thái tin nhắn
  StreamSubscription? _messageStatusSubscription;
  
  /// Constructor
  ChatMessageService(
    this._messageQueueService,
    this._realtimeConnectionService,
    this._subscriptionService,
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
    
    // Khởi tạo các service phụ thuộc
    await _realtimeConnectionService.initialize();
    await _subscriptionService.initialize();
    await _messageQueueService.initialize();
    
    // Lắng nghe trạng thái kết nối
    _connectionStateSubscription = _realtimeConnectionService.connectionStateStream
        .listen(_handleConnectionStateChange);
    
    // Lắng nghe trạng thái tin nhắn
    _messageStatusSubscription = _messageQueueService.messageStatusStream
        .listen(_handleMessageStatusChange);
    
    // Kết nối realtime
    await _realtimeConnectionService.connect();
    
    _initialized = true;
  }
  
  /// Xử lý thay đổi trạng thái kết nối
  void _handleConnectionStateChange(ConnectionState state) {
    final isConnected = state == ConnectionState.connected;
    _connectionStatusController.add(isConnected);
    
    if (isConnected) {
      // Đồng bộ tin nhắn khi kết nối lại
      _synchronizeMessages();
    }
  }
  
  /// Xử lý thay đổi trạng thái tin nhắn
  void _handleMessageStatusChange(QueuedMessage message) {
    // Gửi thông báo nếu tin nhắn đã thay đổi trạng thái thành công
    if (message.status == MessageQueueStatus.sent && message.serverId != null) {
      // Tải tin nhắn đầy đủ từ local DB hoặc server nếu cần
      _loadAndNotifyMessage(message.serverId!);
    }
  }
  
  /// Tải và thông báo tin nhắn
  Future<void> _loadAndNotifyMessage(String messageId) async {
    try {
      final message = await _messageRepository.getMessageById(messageId);
      if (message != null) {
        _updatedMessagesController.add(message);
      }
    } catch (e) {
      debugPrint('Error loading message $messageId: $e');
    }
  }
  
  /// Đồng bộ tin nhắn khi kết nối lại
  Future<void> _synchronizeMessages() async {
    try {
      // Lấy danh sách chat có tin nhắn đang chờ
      final pendingMessages = _messageQueueService.getPendingMessages();
      final chatIds = pendingMessages.map((m) => m.chatId).toSet().toList();
      
      // Đồng bộ tin nhắn cho từng chat
      for (final chatId in chatIds) {
        await _synchronizeChatMessages(chatId);
      }
    } catch (e) {
      debugPrint('Error synchronizing messages: $e');
    }
  }
  
  /// Đồng bộ tin nhắn cho một chat cụ thể
  Future<void> _synchronizeChatMessages(String chatId) async {
    try {
      // Lấy tin nhắn gần đây
      final recentMessages = await _messageRepository.getRecentMessages(chatId, 50);
      
      // Đồng bộ với tin nhắn cục bộ
      await _messageQueueService.syncWithServer(recentMessages);
    } catch (e) {
      debugPrint('Error synchronizing messages for chat $chatId: $e');
    }
  }
  
  /// Đăng ký lắng nghe tin nhắn của một chat
  Future<void> subscribeToChat(String chatId) async {
    // Hủy subscription hiện tại nếu có
    _chatSubscriptions[chatId]?.cancel();
    
    // Đăng ký subscription mới
    final subscription = await _subscriptionService.queryAndSubscribe(
      query: '''
        query GetRecentMessages(\$chatId: ID!) {
          messages(chatId: \$chatId, limit: 20) {
            id
            content
            contentType
            sender {
              id
              name
              avatar
            }
            createdAt
            updatedAt
            readBy
            attachments {
              id
              url
              type
              size
              name
            }
          }
        }
      ''',
      subscriptionQuery: '''
        subscription WatchChatMessages(\$chatId: ID!) {
          messageEvents(chatId: \$chatId) {
            type
            message {
              id
              content
              contentType
              sender {
                id
                name
                avatar
              }
              createdAt
              updatedAt
              readBy
              attachments {
                id
                url
                type
                size
                name
              }
            }
          }
        }
      ''',
      variables: {'chatId': chatId},
      type: SubscriptionType.messageAdded,
    );
    
    // Lưu subscription
    _chatSubscriptions[chatId] = subscription.listen(
      (data) => _handleChatEvent(data, chatId),
      onError: (error) {
        debugPrint('Chat subscription error for $chatId: $error');
      },
    );
    
    // Đồng bộ tin nhắn
    await _synchronizeChatMessages(chatId);
  }
  
  /// Xử lý sự kiện từ chat subscription
  void _handleChatEvent(Map<String, dynamic> data, String chatId) {
    try {
      // Kiểm tra dữ liệu đầu vào
      if (data.containsKey('messages') && data['messages'] is List) {
        // Xử lý dữ liệu ban đầu từ query
        final messages = data['messages'] as List;
        for (final messageData in messages) {
          final message = ChatMessage.fromJson(messageData);
          _updatedMessagesController.add(message);
        }
      } else if (data.containsKey('messageEvents')) {
        // Xử lý sự kiện từ subscription
        final event = data['messageEvents'];
        final type = event['type'] as String;
        
        switch (type) {
          case 'ADDED':
            final message = ChatMessage.fromJson(event['message']);
            _newMessagesController.add(message);
            
            // Cập nhật trạng thái tin nhắn nếu cần
            _updateMessageStatusIfLocal(message);
            break;
            
          case 'UPDATED':
            final message = ChatMessage.fromJson(event['message']);
            _updatedMessagesController.add(message);
            break;
            
          case 'DELETED':
            final messageId = event['message']['id'] as String;
            _deletedMessagesController.add(messageId);
            break;
        }
      }
    } catch (e) {
      debugPrint('Error handling chat event: $e');
    }
  }
  
  /// Cập nhật trạng thái của tin nhắn cục bộ nếu nhận được tin nhắn từ server
  void _updateMessageStatusIfLocal(ChatMessage message) {
    _messageQueueService.updateMessageStatusByServerId(
      serverId: message.id,
      newStatus: MessageQueueStatus.delivered,
    );
  }
  
  /// Hủy đăng ký lắng nghe tin nhắn của một chat
  Future<void> unsubscribeFromChat(String chatId) async {
    // Hủy subscription
    await _chatSubscriptions[chatId]?.cancel();
    _chatSubscriptions.remove(chatId);
  }
  
  /// Gửi tin nhắn
  Future<String> sendMessage({
    required String chatId,
    required String content,
    required ContentType contentType,
    List<String> attachmentIds = const [],
    int priority = 0,
  }) async {
    // Thêm tin nhắn vào hàng đợi
    final localId = await _messageQueueService.enqueueMessage(
      chatId: chatId,
      content: content,
      contentType: contentType,
      attachmentIds: attachmentIds,
      priority: priority,
    );
    
    // Đảm bảo kết nối realtime nếu có thể
    if (!_realtimeConnectionService.isConnected) {
      _realtimeConnectionService.connect();
    }
    
    return localId;
  }
  
  /// Đánh dấu tin nhắn đã đọc
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messageRepository.markAsRead(messageId);
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }
  
  /// Đánh dấu tất cả tin nhắn trong chat đã đọc
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _messageRepository.markChatAsRead(chatId);
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
    }
  }
  
  /// Xóa tin nhắn
  Future<bool> deleteMessage(String messageId) async {
    try {
      return await _messageRepository.deleteMessage(messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }
  
  /// Cập nhật tin nhắn
  Future<bool> updateMessage(String messageId, String newContent) async {
    try {
      return await _messageRepository.updateMessage(messageId, newContent);
    } catch (e) {
      debugPrint('Error updating message: $e');
      return false;
    }
  }
  
  /// Hủy gửi tin nhắn
  Future<bool> cancelMessage(String localId) async {
    return await _messageQueueService.cancelMessage(localId);
  }
  
  /// Thử lại gửi tin nhắn
  Future<void> retryMessage(String localId) async {
    await _messageQueueService.retryMessage(localId);
  }
  
  /// Truy vấn tin nhắn
  Future<List<ChatMessage>> queryMessages(String chatId, {
    int limit = 20,
    String? cursor,
    bool includeLocal = true,
  }) async {
    try {
      // Lấy tin nhắn từ server
      final messages = await _messageRepository.getMessages(
        chatId, 
        limit: limit, 
        cursor: cursor,
      );
      
      // Nếu cần, kết hợp với tin nhắn cục bộ
      if (includeLocal) {
        final localMessages = await _getLocalMessages(chatId);
        
        // Loại bỏ tin nhắn đã có từ server
        final serverIds = messages.map((m) => m.id).toSet();
        final filteredLocalMessages = localMessages
            .where((m) => m.serverId == null || !serverIds.contains(m.serverId))
            .toList();
        
        // TODO: Chuyển đổi QueuedMessage thành ChatMessage
        // Hiện tại chỉ có interface tạm, cần xây dựng hàm chuyển đổi đầy đủ
      }
      
      return messages;
    } catch (e) {
      debugPrint('Error querying messages: $e');
      return [];
    }
  }
  
  /// Lấy tin nhắn cục bộ
  Future<List<QueuedMessage>> _getLocalMessages(String chatId) async {
    final pendingMessages = _messageQueueService.getPendingMessages();
    return pendingMessages.where((m) => m.chatId == chatId).toList();
  }
  
  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    // Hủy tất cả subscription
    for (final subscription in _chatSubscriptions.values) {
      await subscription.cancel();
    }
    _chatSubscriptions.clear();
    
    // Hủy các subscription khác
    await _connectionStateSubscription?.cancel();
    await _messageStatusSubscription?.cancel();
    
    // Đóng các controller
    await _newMessagesController.close();
    await _updatedMessagesController.close();
    await _deletedMessagesController.close();
    await _connectionStatusController.close();
    
    _initialized = false;
  }
} 