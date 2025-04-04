import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/message/message_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

/// Implementation của MessageRepository với chiến lược cache thông minh
class MessageRepositoryWithCache implements IMessageRepository {
  final Logger _logger = Logger();
  final NetworkInfo _networkInfo;
  final MessageLocalDataSource _localDataSource;
  final MessageRemoteDataSource _remoteDataSource;
  final AppCacheManager _cacheManager;
  final CacheSyncStrategy _cacheSyncStrategy;
  final MediaCacheManager _mediaCacheManager;
  final _uuid = Uuid();

  /// Constructor
  MessageRepositoryWithCache(
    this._networkInfo,
    this._localDataSource,
    this._remoteDataSource,
    this._cacheManager,
    this._cacheSyncStrategy,
    this._mediaCacheManager,
  );

  @override
  Future<ChatMessage?> getMessageById(String messageId) async {
    try {
      // Kiểm tra cache trước
      final cacheKey = 'message_${messageId}';
      final cachedMessage = await _cacheManager.getApiResponse<MessageModel>(
        cacheKey,
        fromJson: (json) => MessageModel.fromMap(json),
      );
      
      if (cachedMessage != null) {
        _logger.v('Lấy tin nhắn từ cache: $messageId');
        return cachedMessage.toDomain();
      }
      
      // Nếu không có trong cache, kiểm tra database local
      final messages = await _localDataSource.getMessagesForChat('all');
      
      final message = messages.firstWhere(
        (m) => m.localId == messageId || m.serverId == messageId,
        orElse: () {
          _logger.w('Không tìm thấy tin nhắn trong database local: $messageId');
          throw NotFoundException(message: 'Không tìm thấy tin nhắn');
        },
      );
      
      // Cache lại để lần sau dùng nhanh hơn
      await _cacheManager.cacheApiResponse(cacheKey, message);
      
      return message.toDomain();
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException(message: 'Lỗi khi lấy tin nhắn: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getRecentMessages(String chatId, int limit) async {
    return getMessages(chatId, limit: limit);
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String chatId, {
    int limit = 20,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    // Tạo cache key dựa vào tham số
    final cacheKey = 'chat_messages_${chatId}_${limit}_${cursor ?? "initial"}';
    
    // Kiểm tra xem có cần làm mới cache không
    forceRefresh = forceRefresh || _cacheSyncStrategy.shouldRefreshChatMessages(chatId);
    
    if (!forceRefresh) {
      // Thử lấy từ cache
      final cachedMessages = await _cacheManager.getApiResponse<List<MessageModel>>(
        cacheKey,
        ttl: AppCacheManager.MESSAGE_TTL,
        fromJsonList: (jsonList) => jsonList
            .map((json) => MessageModel.fromMap(json as Map<String, dynamic>))
            .toList(),
      );
      
      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        _logger.v('Lấy ${cachedMessages.length} tin nhắn từ cache cho chat $chatId');
        
        // Tiền tải thumbnails cho attachments
        _prefetchAttachmentThumbnails(cachedMessages);
        
        return cachedMessages.map((m) => m.toDomain()).toList();
      }
    }
    
    // Không có trong cache hoặc cần làm mới
    if (await _networkInfo.isConnected) {
      try {
        _logger.v('Lấy tin nhắn từ server cho chat $chatId');
        // Lấy tin nhắn từ server
        final remoteMessages = await _remoteDataSource.getChatMessages(
          chatId,
          limit: limit,
          cursor: cursor,
        );

        // Lưu vào database local
        await _localDataSource.saveMessages(remoteMessages);
        
        // Cache lại API response
        await _cacheManager.cacheApiResponse(
          cacheKey,
          remoteMessages,
          ttl: AppCacheManager.MESSAGE_TTL,
        );
        
        // Reset dirty flag vì đã làm mới cache
        _cacheSyncStrategy.resetChatMessagesDirtyFlag(chatId);
        
        // Tiền tải thumbnails cho attachments
        _prefetchAttachmentThumbnails(remoteMessages);

        return remoteMessages.map((model) => model.toDomain()).toList();
      } catch (e) {
        _logger.w('Lỗi khi lấy tin nhắn từ server: $e, dùng dữ liệu local');
        // Nếu lỗi, dùng dữ liệu local
        return _getMessagesFromLocal(chatId, limit, cacheKey);
      }
    } else {
      _logger.i('Không có kết nối internet, dùng dữ liệu local');
      // Không có kết nối mạng, dùng dữ liệu local
      return _getMessagesFromLocal(chatId, limit, cacheKey);
    }
  }

  /// Helper method để lấy tin nhắn từ local database
  Future<List<ChatMessage>> _getMessagesFromLocal(
    String chatId,
    int limit,
    String cacheKey,
  ) async {
    final localMessages = await _localDataSource.getMessagesForChat(
      chatId,
      limit: limit,
    );
    
    // Cache lại local data cho lần sau
    await _cacheManager.cacheApiResponse(
      cacheKey,
      localMessages,
      ttl: const Duration(days: 1), // TTL dài hơn cho dữ liệu local
    );
    
    return localMessages.map((model) => model.toDomain()).toList();
  }

  @override
  Future<void> markAsRead(String messageId) async {
    try {
      // TODO: Implement mark as read
      // Implementation would depend on how messages are marked as read
      
      // Invalidate cache for this message
      await _cacheManager.invalidateCache('message_$messageId');
    } catch (e) {
      throw CacheException(message: 'Lỗi khi đánh dấu tin nhắn đã đọc: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId) async {
    if (await _networkInfo.isConnected) {
      try {
        // Đánh dấu đã đọc trên server
        await _remoteDataSource.markMessagesAsRead(chatId);
        
        // Get current user ID (this would come from auth/user repository)
        const userId = 'current_user_id'; // Placeholder
        
        // Đánh dấu tin nhắn đã đọc cục bộ
        await _localDataSource.markMessagesAsRead(chatId, userId);
        
        // Invalidate cache cho chat này
        _cacheSyncStrategy.markChatMessagesDirty(chatId);
        _cacheSyncStrategy.markChatListDirty(); // Vì unread count thay đổi
      } catch (e) {
        throw ServerException(message: 'Lỗi khi đánh dấu chat đã đọc: $e');
      }
    } else {
      // Offline - chỉ đánh dấu cục bộ
      const userId = 'current_user_id'; // Placeholder
      await _localDataSource.markMessagesAsRead(chatId, userId);
    }
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      // Delete on server
      final success = await _remoteDataSource.deleteMessage(messageId);
      
      if (success) {
        // Delete locally
        await _localDataSource.deleteMessage(messageId);
        
        // Invalidate cache
        await _cacheManager.invalidateCache('message_$messageId');
        
        // Mark related caches as dirty
        final chatId = await _getChatIdForMessage(messageId);
        if (chatId != null) {
          _cacheSyncStrategy.markChatMessagesDirty(chatId);
          _cacheSyncStrategy.markChatListDirty();
        }
      }
      
      return success;
    } catch (e) {
      throw ServerException(message: 'Lỗi khi xóa tin nhắn: $e');
    }
  }

  /// Helper method to get chatId for a message
  Future<String?> _getChatIdForMessage(String messageId) async {
    try {
      final messages = await _localDataSource.getMessagesForChat('all');
      final message = messages.firstWhere(
        (m) => m.localId == messageId || m.serverId == messageId,
        orElse: () => throw NotFoundException(),
      );
      return message.chatId;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> updateMessage(String messageId, String newContent) async {
    // TODO: Implement update message
    // This would typically call a server API to update a message
    return false;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    required String contentType,
    List<String> attachmentIds = const [],
  }) async {
    // Tạo tin nhắn cục bộ với trạng thái đang gửi
    final localId = _uuid.v4();
    final messageType = _parseMessageType(contentType);
    
    final localMessage = MessageModel(
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: messageType,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    // Lưu vào local storage ngay lập tức
    await _localDataSource.saveMessage(localMessage);
    
    // Mark chat messages as dirty
    _cacheSyncStrategy.markChatMessagesDirty(chatId);
    _cacheSyncStrategy.markChatListDirty();
    
    // Try to send to server if online
    if (await _networkInfo.isConnected) {
      try {
        // Send to server
        final sentMessage = await _remoteDataSource.sendMessage(localMessage);
        
        // Update local copy with server ID and success status
        final updatedMessage = sentMessage.copyWith(
          localId: localId, // Retain local ID for reference
          status: MessageStatus.sent,
        );
        
        // Save updated message
        await _localDataSource.saveMessage(updatedMessage);
        
        // Cache individual message
        await _cacheManager.cacheApiResponse(
          'message_${sentMessage.serverId}',
          updatedMessage,
        );
        
        _logger.i('Đã gửi tin nhắn thành công: $localId -> ${sentMessage.serverId}');
        
        return updatedMessage.toDomain();
      } catch (e) {
        // Mark as failed in local storage
        final failedMessage = localMessage.copyWith(
          status: MessageStatus.failed,
        );
        
        await _localDataSource.saveMessage(failedMessage);
        
        _logger.e('Lỗi khi gửi tin nhắn: $e');
        
        throw ServerException(message: 'Lỗi khi gửi tin nhắn: $e');
      }
    } else {
      // Offline - mark as pending and return local message
      final pendingMessage = localMessage.copyWith(
        status: MessageStatus.pending,
      );
      
      await _localDataSource.saveMessage(pendingMessage);
      
      _logger.i('Đã lưu tin nhắn vào hàng đợi offline: $localId');
      
      return pendingMessage.toDomain();
    }
  }

  @override
  Future<bool> checkMessageConflict(String localId, String serverId) async {
    // TODO: Implement message conflict resolution
    // Implementation would depend on specific conflict resolution logic
    return false;
  }

  @override
  Future<void> syncMessages(String chatId, {int limit = 50}) async {
    if (!(await _networkInfo.isConnected)) {
      _logger.w('Không thể đồng bộ tin nhắn: không có kết nối internet');
      return; // Can't sync without internet
    }

    try {
      _logger.i('Bắt đầu đồng bộ tin nhắn cho chat $chatId');
      
      // Get messages from server
      final remoteMessages = await _remoteDataSource.getChatMessages(
        chatId,
        limit: limit,
      );

      // Get local messages
      final localMessages = await _localDataSource.getMessagesForChat(chatId);

      // Find messages to add (in remote but not local)
      final localIds = localMessages.map((m) => m.serverId).toSet();
      final messagesToAdd = remoteMessages.where(
        (m) => m.serverId != null && !localIds.contains(m.serverId),
      ).toList();

      // Save new messages
      if (messagesToAdd.isNotEmpty) {
        await _localDataSource.saveMessages(messagesToAdd);
        _logger.i('Đã thêm ${messagesToAdd.length} tin nhắn mới từ server');
      }

      // Find pending messages that need to be sent
      final pendingMessages = localMessages.where(
        (m) => m.status == MessageStatus.pending,
      ).toList();

      _logger.i('Đang gửi ${pendingMessages.length} tin nhắn đang chờ');
      
      // Try to send pending messages
      for (final message in pendingMessages) {
        try {
          final sentMessage = await _remoteDataSource.sendMessage(message);
          final updatedMessage = sentMessage.copyWith(
            localId: message.localId,
            status: MessageStatus.sent,
          );
          await _localDataSource.saveMessage(updatedMessage);
          
          _logger.v('Đã gửi tin nhắn chờ: ${message.localId} -> ${sentMessage.serverId}');
        } catch (e) {
          // Mark as failed if sending fails
          final failedMessage = message.copyWith(
            status: MessageStatus.failed,
          );
          await _localDataSource.saveMessage(failedMessage);
          
          _logger.e('Lỗi khi gửi tin nhắn chờ ${message.localId}: $e');
        }
      }
      
      // Mark cache as refreshed
      _cacheSyncStrategy.resetChatMessagesDirtyFlag(chatId);
      
      // Invalidate message list cache to ensure fresh data
      await _cacheManager.invalidateCache('chat_messages_${chatId}');
      
      _logger.i('Đã hoàn thành đồng bộ tin nhắn cho chat $chatId');
    } catch (e) {
      _logger.e('Lỗi khi đồng bộ tin nhắn: $e');
    }
  }
  
  /// Parse contentType string to MessageType enum
  MessageType _parseMessageType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }
  
  /// Prefetch thumbnails for message attachments
  void _prefetchAttachmentThumbnails(List<MessageModel> messages) {
    try {
      // Extract image and video URLs that need thumbnails
      final imageUrls = <String>[];
      final videoUrls = <String>[];
      
      for (final message in messages) {
        if (message.attachments == null) continue;
        
        for (final attachment in message.attachments!) {
          if (attachment.type == 'image') {
            imageUrls.add(attachment.url);
          } else if (attachment.type == 'video') {
            videoUrls.add(attachment.url);
          }
        }
      }
      
      // Prefetch in background
      if (imageUrls.isNotEmpty) {
        _mediaCacheManager.prefetchThumbnails(imageUrls);
      }
      
      // TODO: Implement video thumbnail prefetching when needed
    } catch (e) {
      // Ignore prefetch errors, this is just an optimization
      _logger.v('Lỗi khi prefetch thumbnails: $e');
    }
  }
} 