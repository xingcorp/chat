import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/data/datasources/message/message_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/mappers/message_mapper.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';

import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// **ENTERPRISE MESSAGE REPOSITORY IMPLEMENTATION**
///
/// Unified implementation consolidating MessageRepositoryWithCache logic
/// with BaseRepository pattern for enterprise-grade messaging performance.
///
/// **Performance Targets:**
/// - Message delivery: <100ms (WhatsApp standard)
/// - Cache retrieval: <50ms
/// - Offline operations: Immediate response
///
/// **Architecture:** Clean Architecture + SOLID principles + BaseRepository pattern
@LazySingleton(as: IMessageRepository)
class MessageRepositoryImpl extends BaseRepository
    implements IMessageRepository {
  final MessageLocalDataSource _localDataSource;
  final IMessageRemoteDataSource _remoteDataSource;
  final AppCacheManager _cacheManager;
  final CacheSyncStrategy _cacheSyncStrategy;
  final MediaCacheManager _mediaCacheManager;
  final _uuid = const Uuid();

  MessageRepositoryImpl({
    required MessageLocalDataSource localDataSource,
    required IMessageRemoteDataSource remoteDataSource,
    required AppCacheManager cacheManager,
    required CacheSyncStrategy cacheSyncStrategy,
    required MediaCacheManager mediaCacheManager,
    required super.networkInfo,
    required super.logger,
    required super.performanceMonitor,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _cacheManager = cacheManager,
        _cacheSyncStrategy = cacheSyncStrategy,
        _mediaCacheManager = mediaCacheManager;

  /// **GET MESSAGE BY ID - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <50ms for cached messages
  /// **Strategy**: Cache → Local DB → Error handling
  @override
  Future<Either<Failure, ChatMessage?>> getMessageById(String messageId) async {
    return executeOfflineFirst<ChatMessage?>(
      remoteDataSource: () async {
        // Remote fallback not implemented for single message
        throw ServerException(
            message: 'Remote single message fetch not supported');
      },
      localDataSource: () async {
        // Check cache first
        final cacheKey = 'message_$messageId';
        final cachedMessage = await _cacheManager.getApiResponse<MessageModel>(
          cacheKey,
          fromJson: MessageModel.fromMap,
        );

        if (cachedMessage != null) {
          logger.d('Retrieved message from cache: $messageId');
          return cachedMessage.toDomain();
        }

        // Check local database
        final messages = await _localDataSource.getMessagesForChat('all');

        final message = messages.firstWhere(
          (m) => m.localId == messageId || m.serverId == messageId,
          orElse: () => throw NotFoundException(message: 'Message not found'),
        );

        // Cache for next time
        await _cacheManager.cacheApiResponse(cacheKey, message.toMap());

        return message.toDomain();
      },
      operationName: 'getMessageById',
    );
  }

  /// **GET RECENT MESSAGES - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <100ms for recent messages
  /// **Strategy**: Local immediate → Background sync
  @override
  Future<Either<Failure, List<ChatMessage>>> getRecentMessages(
      String chatId, int limit) async {
    return getMessages(chatId, limit: limit);
  }

  /// **GET MESSAGES WITH PAGINATION**
  ///
  /// **Performance**: <150ms for paginated loading
  /// **Strategy**:
  ///   - Initial load (cursor == null): Remote-first with local fallback.
  ///     Users expect to see the latest messages when opening a chat.
  ///   - Load-more (cursor != null): Offline-first (local/cache → background remote sync).
  ///     Historical messages are unlikely to change, so stale-while-revalidate is fine.
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId,
      {int limit = 20, String? cursor}) async {
    const cacheVersion = 'v2';
    final cacheKey =
        'chat_messages_${chatId}_${limit}_${cursor ?? "initial"}_$cacheVersion';

    // ── Initial load: remote-first ──────────────────────────────────────
    if (cursor == null) {
      return _getMessagesRemoteFirst(chatId, limit: limit, cacheKey: cacheKey);
    }

    // ── Load-more: offline-first ────────────────────────────────────────
    return _getMessagesOfflineFirst(chatId,
        limit: limit, cursor: cursor, cacheKey: cacheKey);
  }

  /// Remote-first strategy for initial message load.
  /// Try server first; fall back to local cache/DB only on failure or offline.
  Future<Either<Failure, List<ChatMessage>>> _getMessagesRemoteFirst(
    String chatId, {
    required int limit,
    required String cacheKey,
  }) async {
    // If online, try remote first
    if (await networkInfo.isConnected) {
      try {
        final messages = await _fetchAndCacheFromRemote(chatId,
            limit: limit, cursor: null, cacheKey: cacheKey);
        return Right(messages);
      } catch (e) {
        // Remote failed — fall through to local fallback
        logger.w(
            'Remote fetch failed for initial load of chat $chatId, falling back to local: $e');
      }
    }

    // Offline or remote failed — serve from local
    return _getMessagesFromLocal(chatId,
        limit: limit, cursor: null, cacheKey: cacheKey);
  }

  /// Offline-first strategy for load-more (pagination).
  /// Serve cached/local data immediately; background-sync from remote.
  Future<Either<Failure, List<ChatMessage>>> _getMessagesOfflineFirst(
    String chatId, {
    required int limit,
    required String cursor,
    required String cacheKey,
  }) async {
    final forceRefresh = _cacheSyncStrategy.shouldRefreshChatMessages(chatId);

    return executeOfflineFirst<List<ChatMessage>>(
      remoteDataSource: () => _fetchAndCacheFromRemote(chatId,
          limit: limit, cursor: cursor, cacheKey: cacheKey),
      localDataSource: () async {
        // Check cache first if not forcing refresh
        if (!forceRefresh) {
          final cachedMessages =
              await _cacheManager.getApiResponse<List<MessageModel>>(
            cacheKey,
            fromJsonList: (json) => json
                .map((item) =>
                    MessageModel.fromMap(item as Map<String, dynamic>))
                .toList(),
          );

          if (cachedMessages != null && cachedMessages.isNotEmpty) {
            logger.d('Retrieved messages from cache for chat $chatId');
            return cachedMessages.map((model) => model.toDomain()).toList();
          }
        }

        // Get from local database
        final localMessages = await _localDataSource.getMessagesForChat(chatId);
        final paginatedMessages =
            _applyPagination(localMessages, limit, cursor);

        // If local is empty but we're online, fetch synchronously
        if (paginatedMessages.isEmpty && await networkInfo.isConnected) {
          logger.d(
              'Local messages empty for load-more in chat $chatId; fetching from server');
          return _fetchAndCacheFromRemote(chatId,
              limit: limit, cursor: cursor, cacheKey: cacheKey);
        }

        // Cache the result
        await _cacheManager.cacheApiResponse(
          cacheKey,
          paginatedMessages.map((m) => m.toMap()).toList(),
          ttl: AppCacheManager.messageTtl,
        );

        return paginatedMessages.map((model) => model.toDomain()).toList();
      },
      operationName: 'getMessages',
    );
  }

  /// Shared helper: fetch from remote, save to local DB + cache, return domain entities.
  Future<List<ChatMessage>> _fetchAndCacheFromRemote(
    String chatId, {
    required int limit,
    required String? cursor,
    required String cacheKey,
  }) async {
    // logger.d('Fetching messages from server for chat $chatId');

    final cursorTs = cursor != null ? int.tryParse(cursor) : null;

    final response = await _remoteDataSource.getMessageList(
      conversationId: chatId,
      size: limit,
      lastKey: cursorTs != null
          ? {'conversationId': chatId, 'createdAt': cursorTs}
          : null,
    );
    final dtos = response.messages;
    final models = MessageMapper.toModelList(dtos);

    await _localDataSource.saveMessages(models);

    // Verify persistence — read back from Isar to confirm messages were saved
    final verifyCount =
        (await _localDataSource.getMessagesForChat(chatId)).length;
    logger.i(
        '[_fetchAndCacheFromRemote] chatId=$chatId: '
        'fetched=${dtos.length} models=${models.length} '
        'isarAfterSave=$verifyCount');

    await _cacheManager.cacheApiResponse(
      cacheKey,
      models.map((m) => m.toMap()).toList(),
      ttl: AppCacheManager.messageTtl,
    );

    _cacheSyncStrategy.resetChatMessagesDirtyFlag(chatId);
    _prefetchAttachmentThumbnails(models);

    return models.map((model) => model.toDomain()).toList();
  }

  /// Local fallback: try cache first, then local DB.
  Future<Either<Failure, List<ChatMessage>>> _getMessagesFromLocal(
    String chatId, {
    required int limit,
    required String? cursor,
    required String cacheKey,
  }) async {
    try {
      // Try cache
      final cachedMessages =
          await _cacheManager.getApiResponse<List<MessageModel>>(
        cacheKey,
        fromJsonList: (json) => json
            .map((item) => MessageModel.fromMap(item as Map<String, dynamic>))
            .toList(),
      );

      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        logger.d('Serving cached messages for chat $chatId (local fallback)');
        return Right(cachedMessages.map((model) => model.toDomain()).toList());
      }

      // Try local DB
      final localMessages = await _localDataSource.getMessagesForChat(chatId);
      final paginatedMessages = _applyPagination(localMessages, limit, cursor);
      return Right(paginatedMessages.map((model) => model.toDomain()).toList());
    } catch (e) {
      logger.e('Local fallback failed for chat $chatId: $e');
      return Left(
          CacheFailure(message: 'Failed to load messages from local storage'));
    }
  }

  /// **SEND MESSAGE - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <100ms delivery target
  /// **Strategy**: Local immediate → Server sync → Status update
  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    required String contentType,
    List<String> attachmentIds = const [],
    String? replyMessageId,
    String? fileName,
    String? forwardedFromMessageId,
    String? receiverId,
  }) async {
    // Create local message with sending status
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
      replyToMessageId: replyMessageId,
    );

    if (kDebugMode) {
      logger.i(
          '[sendMessage][local] localId=$localId chatId=$chatId senderId=$senderId '
          'type=${messageType.name} replyMessageId=$replyMessageId '
          'attachments=${attachmentIds.length} content="${content.replaceAll("\n", "\\n")}"');
    }

    // Save to local storage immediately for instant UI feedback
    await _localDataSource.saveMessage(localMessage);

    // Mark cache as dirty
    _cacheSyncStrategy.markChatMessagesDirty(chatId);
    _cacheSyncStrategy.markChatListDirty();

    return executeOnlineFirst<ChatMessage>(
      remoteDataSource: () async {
        // Send to server using DTO
        final serverType = _resolveServerMessageType(
          contentType: contentType,
          parsedType: messageType,
        );
        if (kDebugMode) {
          logger.i('[sendMessage][remote] chatId=$chatId type=$serverType '
              'replyMessageId=$replyMessageId urls=${attachmentIds.length} '
              'receiverId=$receiverId isPendingDirect=${receiverId != null && receiverId.isNotEmpty}');
        }
        // For pending direct chats (no server conversation yet), pass receiverId
        // so backend auto-creates the conversation. Don't pass temp chatId as
        // conversationId — backend doesn't know it.
        final isPendingDirect = receiverId != null && receiverId.isNotEmpty;
        final dto = await _remoteDataSource.sendMessage(
          conversationId: isPendingDirect ? null : chatId,
          receiverId: isPendingDirect ? receiverId : null,
          type: serverType,
          message: content,
          urls: attachmentIds,
          fileName: fileName,
          replyMessageId: replyMessageId,
          forwardedFromMessageId: forwardedFromMessageId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Convert DTO to Model using mapper
        final sentMessage = MessageMapper.toModel(dto);

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
          updatedMessage.toMap(),
        );

        logger.i(
            'Message sent successfully: $localId -> ${sentMessage.serverId}');

        return updatedMessage.toDomain();
      },
      localDataSource: () async {
        // Offline - mark as pending and return local message
        final pendingMessage = localMessage.copyWith(
          status: MessageStatus.pending,
        );

        await _localDataSource.saveMessage(pendingMessage);

        logger.i('Message queued for offline sending: $localId');

        return pendingMessage.toDomain();
      },
      cacheData: (message) async {
        // Additional caching if needed
      },
      operationName: 'sendMessage',
    );
  }

  /// **MARK AS READ - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <100ms for read receipts
  /// **Strategy**: Server update → Local sync
  @override
  Future<Either<Failure, void>> markAsRead(String messageId) async {
    return executeOnlineFirst<void>(
      remoteDataSource: () async {
        // Note: Backend uses markAsRead at conversation level, not message level
        // This is a placeholder - actual implementation should use conversation-level API
        logger.i('Marked message as read: $messageId');
      },
      localDataSource: () async {
        // Mark locally
        logger.i('Marked message as read locally: $messageId');
      },
      operationName: 'markAsRead',
    );
  }

  /// **MARK CHAT AS READ - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <200ms for bulk operations
  @override
  Future<Either<Failure, void>> markChatAsRead(String chatId) async {
    return executeOnlineFirst<void>(
      remoteDataSource: () async {
        // Backend contract (see @src ChatMessageService.updateUnreadCount):
        // use readCount=1000000 to reset unread count to 0 for the current user.
        await _remoteDataSource.markAsRead(
          conversationId: chatId,
          readCount: 1000000,
        );

        // logger.i('Marked chat as read: $chatId');
      },
      localDataSource: () async {
        // Mark locally
        // logger.i('Marked chat as read locally: $chatId');
      },
      operationName: 'markChatAsRead',
    );
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> searchMessages({
    required String keyword,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<String>? messageTypes,
    int? from,
    int? to,
    int page = 0,
    int size = 100,
  }) async {
    return executeOnlineFirst<List<ChatMessage>>(
      remoteDataSource: () async {
        final dtos = await _remoteDataSource.searchMessages(
          keyword: keyword,
          conversationIds: conversationIds,
          senderIds: senderIds,
          messageTypes: messageTypes,
          from: from,
          to: to,
          page: page,
          size: size,
        );

        return dtos.map((dto) => dto.toDomain()).toList();
      },
      localDataSource: () async {
        final chatId = (conversationIds != null && conversationIds.isNotEmpty)
            ? conversationIds.first
            : '';

        if (chatId.isEmpty) {
          return <ChatMessage>[];
        }

        final localMessages = await _localDataSource.getMessagesForChat(chatId);
        final q = keyword.toLowerCase();

        return localMessages
            .where((m) => m.content.toLowerCase().contains(q))
            .take(size)
            .map((m) => m.toDomain())
            .toList();
      },
      operationName: 'searchMessages',
    );
  }

  @override
  Future<Either<Failure, bool>> updateReaction({
    required String messageId,
    required String code,
    required String act,
  }) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        await _remoteDataSource.updateReaction(
          messageId: messageId,
          code: code,
          act: act,
        );

        return true;
      },
      localDataSource: () async {
        return false;
      },
      operationName: 'updateReaction',
    );
  }

  /// **DELETE MESSAGE - REMOTE-ONLY STRATEGY**
  ///
  /// **Performance**: <150ms for delete operations
  /// **Strategy**: Remote-only because delete requires server confirmation.
  /// Server rejection (e.g., ChatMessageNotFound) should not silently succeed locally.
  /// **chatId**: Required for O(1) local cache deletion.
  @override
  Future<Either<Failure, bool>> deleteMessage(
      String chatId, String messageId) async {
    return executeRemoteOnly<bool>(
      remoteDataSource: () async {
        // Delete message on server (hard-delete: removes from database)
        // Backend expects ChatMessageAct enum: DEL=0, EDIT=1
        await _remoteDataSource.editMessage(
          messageId: messageId,
          act: 'DEL',
        );
        // Also delete from local cache - O(1) with chatId
        await _localDataSource.deleteMessage(chatId, messageId);
        return true;
      },
      operationName: 'deleteMessage',
    );
  }

  /// **UPDATE MESSAGE - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <100ms for message edits
  @override
  Future<Either<Failure, bool>> updateMessage(
      String messageId, String newContent) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        // Edit message on server
        // Backend expects ChatMessageAct enum: DEL=0, EDIT=1
        await _remoteDataSource.editMessage(
          messageId: messageId,
          act: 'EDIT',
          message: newContent,
        );
        return true;
      },
      localDataSource: () async {
        // Update locally
        logger.i('Updated message locally: $messageId');
        return true;
      },
      operationName: 'updateMessage',
    );
  }

  /// **CHECK MESSAGE CONFLICT - REMOTE-ONLY STRATEGY**
  ///
  /// **Performance**: <200ms for conflict resolution
  @override
  Future<Either<Failure, bool>> checkMessageConflict(
      String localId, String serverId) async {
    return executeRemoteOnly<bool>(
      remoteDataSource: () async {
        // TODO: Implement conflict resolution logic
        return false; // Placeholder
      },
      operationName: 'checkMessageConflict',
    );
  }

  /// **SYNC MESSAGES - SYNC STRATEGY**
  ///
  /// **Performance**: Background process, non-blocking UI
  @override
  Future<Either<Failure, void>> syncMessages(String chatId,
      {int limit = 50}) async {
    return executeSyncStrategy(
      syncOperation: () async {
        if (!(await networkInfo.isConnected)) {
          logger.w('Cannot sync messages: no internet connection');
          return;
        }

        try {
          // Get messages from server
          final response = await _remoteDataSource.getMessageList(
            conversationId: chatId,
            size: limit,
          );
          final dtos = response.messages;

          // Convert DTOs to Models using mapper
          final remoteMessages = MessageMapper.toModelList(dtos);

          // Get local messages
          final localMessages =
              await _localDataSource.getMessagesForChat(chatId);

          // Find messages to add (in remote but not local)
          final localIds = localMessages.map((m) => m.serverId).toSet();
          final messagesToAdd = remoteMessages
              .where(
                (m) => m.serverId != null && !localIds.contains(m.serverId),
              )
              .toList();

          // Save new messages
          if (messagesToAdd.isNotEmpty) {
            await _localDataSource.saveMessages(messagesToAdd);
          }

          // Find pending messages that need to be sent
          final pendingMessages = localMessages
              .where(
                (m) => m.status == MessageStatus.pending,
              )
              .toList();

          // Try to send pending messages
          for (final pendingMessage in pendingMessages) {
            try {
              // Skip pending direct chat messages (temp numeric chatId).
              // These need receiverId from UI layer to create conversation.
              if (!pendingMessage.chatId.contains('-')) {
                logger.w(
                    'syncMessages: skipping pending message ${pendingMessage.localId} — '
                    'pending direct chat needs receiverId');
                continue;
              }

              final dto = await _remoteDataSource.sendMessage(
                conversationId: pendingMessage.chatId,
                type: pendingMessage.type.name.toUpperCase(),
                message: pendingMessage.content,
                createdAt: pendingMessage.createdAt.millisecondsSinceEpoch,
              );

              // Convert DTO to Model
              final sentMessage = MessageMapper.toModel(dto);

              // Update local message with server ID
              final updatedMessage = sentMessage.copyWith(
                localId: pendingMessage.localId,
                status: MessageStatus.sent,
              );

              await _localDataSource.saveMessage(updatedMessage);

              logger.i(
                  'Synced pending message: ${pendingMessage.localId} -> ${sentMessage.serverId}');
            } catch (e) {
              logger.e(
                  'Failed to sync pending message ${pendingMessage.localId}: $e');
            }
          }

          // Mark cache as refreshed
          _cacheSyncStrategy.resetChatMessagesDirtyFlag(chatId);

          // Invalidate message list cache to ensure fresh data
          await _cacheManager.invalidateCache('chat_messages_$chatId');

          logger.i('Completed message sync for chat $chatId');
        } catch (e) {
          logger.e('Error syncing messages: $e');
          throw ServerException(message: 'Sync failed: $e');
        }
      },
      operationName: 'syncMessages',
    );
  }

  /// **RETRY PENDING MESSAGES FOR A SPECIFIC CHAT**
  ///
  /// Finds messages with status=pending in the given chat,
  /// locks them (pending→sending), sends to server, then updates status.
  /// Anti-duplicate: only picks up messages still in pending state.
  @override
  Future<Either<Failure, int>> retryPendingMessages(String chatId) async {
    return _retryPendingMessagesInternal(chatId: chatId);
  }

  /// **RETRY ALL PENDING MESSAGES ACROSS ALL CHATS**
  ///
  /// Scans all local storage for pending/stale-sending messages,
  /// groups by chatId, and retries them in FIFO order.
  @override
  Future<Either<Failure, int>> retryAllPendingMessages() async {
    return _retryPendingMessagesInternal();
  }

  /// Internal retry implementation.
  /// If [chatId] is provided, retries only for that chat.
  /// If null, retries all pending messages across all chats.
  Future<Either<Failure, int>> _retryPendingMessagesInternal({
    String? chatId,
  }) async {
    try {
      if (!(await networkInfo.isConnected)) {
        logger.w('retryPendingMessages: no internet, skipping');
        return const Right(0);
      }

      // Gather pending messages
      final List<MessageModel> pendingMessages;
      if (chatId != null) {
        final allMessages =
            await _localDataSource.getMessagesForChat(chatId);
        pendingMessages = allMessages
            .where((m) =>
                m.status == MessageStatus.pending ||
                (m.status == MessageStatus.sending &&
                    DateTime.now().difference(m.createdAt) >
                        const Duration(minutes: 2)))
            .toList();
      } else {
        pendingMessages = await _localDataSource.getAllPendingMessages();
      }

      if (pendingMessages.isEmpty) {
        logger.d('retryPendingMessages: no pending messages found');
        return const Right(0);
      }

      logger.i(
          'retryPendingMessages: found ${pendingMessages.length} pending messages');

      int successCount = 0;

      for (final message in pendingMessages) {
        try {
          // Skip pending direct chat messages (temp numeric chatId, no UUID hyphens).
          // These require receiverId which is only available from the UI/Bloc layer.
          // Once the navigation-layer fix propagates receiverId correctly, the first
          // message will create the conversation with a real UUID chatId, so
          // subsequent retry won't hit this path.
          if (!message.chatId.contains('-')) {
            logger.w(
                'retryPendingMessages: skipping ${message.localId} — '
                'pending direct chat (chatId=${message.chatId}) needs receiverId');
            continue;
          }

          // Lock: mark as sending to prevent duplicate retry
          final sendingMessage =
              message.copyWith(status: MessageStatus.sending);
          await _localDataSource.saveMessage(sendingMessage);

          // Send to server
          final serverType = _toServerMessageType(message.type);
          final dto = await _remoteDataSource.sendMessage(
            conversationId: message.chatId,
            type: serverType,
            message: message.content,
            replyMessageId: message.replyToMessageId,
            createdAt: message.createdAt.millisecondsSinceEpoch,
          );

          // Update local with server response
          final sentMessage = MessageMapper.toModel(dto);
          final updatedMessage = sentMessage.copyWith(
            localId: message.localId,
            status: MessageStatus.sent,
          );
          await _localDataSource.saveMessage(updatedMessage);

          // Cache individual message
          await _cacheManager.cacheApiResponse(
            'message_${sentMessage.serverId}',
            updatedMessage.toMap(),
          );

          logger.i(
              'retryPendingMessages: sent ${message.localId} -> ${sentMessage.serverId}');
          successCount++;
        } catch (e) {
          // Revert to pending so it can be retried later
          final revertedMessage =
              message.copyWith(status: MessageStatus.pending);
          await _localDataSource.saveMessage(revertedMessage);

          logger.e(
              'retryPendingMessages: failed to send ${message.localId}: $e');
        }
      }

      // Invalidate cache for affected chats
      final affectedChatIds =
          pendingMessages.map((m) => m.chatId).toSet();
      for (final cid in affectedChatIds) {
        _cacheSyncStrategy.markChatMessagesDirty(cid);
        await _cacheManager.invalidateCache('chat_messages_$cid');
      }

      logger.i(
          'retryPendingMessages: completed $successCount/${pendingMessages.length}');
      return Right(successCount);
    } catch (e) {
      logger.e('retryPendingMessages: unexpected error: $e');
      return Left(CacheFailure(message: 'Retry failed: $e'));
    }
  }

  /// **HELPER METHODS**

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
      case 'voice_note':
        return MessageType.audio;
      case 'file':
      case 'doc': // Handle DOC type from server/bloc
        return MessageType.file;
      case 'location':
        return MessageType.location;
      case 'sticker':
        return MessageType.sticker;
      default:
        return MessageType.text;
    }
  }

  String _resolveServerMessageType({
    required String contentType,
    required MessageType parsedType,
  }) {
    if (contentType.toLowerCase() == 'voice_note') {
      return 'VOICE_NOTE';
    }
    return _toServerMessageType(parsedType);
  }

  /// Convert MessageType enum to server API type string
  /// Server expects: TEXT, IMAGE, VIDEO, AUDIO, DOC, LOCATION
  String _toServerMessageType(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.image:
        return 'IMAGE';
      case MessageType.video:
        return 'VIDEO';
      case MessageType.audio:
        return 'AUDIO';
      case MessageType.file:
        return 'DOC'; // Server uses DOC, not FILE
      case MessageType.location:
        return 'LOCATION';
      case MessageType.sticker:
        return 'STICKER';
      default:
        return 'TEXT';
    }
  }

  /// Apply pagination to message list
  List<MessageModel> _applyPagination(
      List<MessageModel> messages, int limit, String? cursor) {
    // Sort by timestamp descending
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (cursor != null) {
      // Cursor is a timestamp (millisecondsSinceEpoch) — find messages OLDER
      // than this timestamp for the next page.
      final cursorTs = int.tryParse(cursor);
      if (cursorTs != null) {
        final cursorDate = DateTime.fromMillisecondsSinceEpoch(cursorTs);
        final olderMessages =
            messages.where((m) => m.createdAt.isBefore(cursorDate)).toList();
        return olderMessages.take(limit).toList();
      }

      // Fallback: try matching by message ID
      final cursorIndex = messages
          .indexWhere((m) => m.serverId == cursor || m.localId == cursor);
      if (cursorIndex >= 0) {
        final startIndex = cursorIndex + 1;
        return messages.skip(startIndex).take(limit).toList();
      }
    }

    return messages.take(limit).toList();
  }

  // === Phase 2 + 3: Two-Phase Render & Delta Sync ===

  /// **GET MESSAGES FROM LOCAL - LOCAL-ONLY STRATEGY**
  ///
  /// Returns cached/local messages without hitting the server.
  /// Returns empty list (not failure) if no local data or read fails.
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessagesFromLocal(
    String chatId, {
    int limit = 20,
  }) async {
    try {
      final localMessages = await _localDataSource.getMessagesForChat(chatId);
      if (localMessages.isEmpty) {
        logger.i(
            '[TwoPhase][Repo] getMessagesFromLocal chatId=$chatId: Isar returned 0 messages');
        return const Right([]);
      }

      // Sort descending and take limit
      final sorted = _applyPagination(localMessages, limit, null);
      final domainMessages = sorted.map((model) => model.toDomain()).toList();
      final newestTs = domainMessages.isNotEmpty
          ? domainMessages.first.createdAt.toIso8601String()
          : 'N/A';
      final oldestTs = domainMessages.isNotEmpty
          ? domainMessages.last.createdAt.toIso8601String()
          : 'N/A';
      logger.i(
          '[TwoPhase][Repo] getMessagesFromLocal chatId=$chatId: isarTotal=${localMessages.length} returned=${domainMessages.length} newest=$newestTs oldest=$oldestTs');
      return Right(domainMessages);
    } catch (e) {
      logger.w(
          '[TwoPhase][Repo] getMessagesFromLocal FAILED for chat $chatId, returning empty: $e');
      return const Right([]);
    }
  }

  /// **GET MESSAGES DELTA - DELTA SYNC STRATEGY**
  ///
  /// Fetches only messages newer than fromTimestamp from server,
  /// saves new messages to local cache, returns ONLY the delta messages.
  ///
  /// NOTE: Merge voi local state duoc thuc hien o BLoC layer (single merge),
  /// KHONG merge o day de tranh double-merge bug.
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessagesDelta(
    String chatId, {
    required int fromTimestamp,
    int limit = 20,
  }) async {
    try {
      logger.i(
          '[TwoPhase][Repo] getMessagesDelta chatId=$chatId from=${DateTime.fromMillisecondsSinceEpoch(fromTimestamp).toIso8601String()} limit=$limit');

      // Fetch delta from server using `from` parameter
      final response = await _remoteDataSource.getMessageList(
        conversationId: chatId,
        size: limit,
        from: fromTimestamp,
      );
      final dtos = response.messages;
      final serverModels = MessageMapper.toModelList(dtos);
      final serverMessages = serverModels.map((m) => m.toDomain()).toList();

      final serverNewest = serverMessages.isNotEmpty
          ? serverMessages.first.createdAt.toIso8601String()
          : 'N/A';
      logger.i(
          '[TwoPhase][Repo] Delta server response: dtoCount=${dtos.length} domainCount=${serverMessages.length} newest=$serverNewest');

      // Save delta messages to local cache (additive — saveMessages does upsert)
      if (serverModels.isNotEmpty) {
        await _localDataSource.saveMessages(serverModels);
      }

      // Invalidate old cache keys
      await _cacheManager.invalidateCache('chat_messages_$chatId');
      _cacheSyncStrategy.resetChatMessagesDirtyFlag(chatId);

      // Return ONLY delta messages — BLoC layer will merge with local state
      return Right(serverMessages);
    } on ServerException catch (e) {
      logger.e(
          '[TwoPhase][Repo] Delta sync ServerException for chat $chatId: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e(
          '[TwoPhase][Repo] Delta sync UNEXPECTED error for chat $chatId: $e');
      return Left(UnexpectedFailure(message: 'Delta sync failed: $e'));
    }
  }

  /// Prefetch attachment thumbnails for better UX
  void _prefetchAttachmentThumbnails(List<MessageModel> messages) {
    try {
      // Extract image and video URLs that need thumbnails
      final imageUrls = <String>[];
      final videoUrls = <String>[];

      for (final message in messages) {
        final domainMessage = message.toDomain();
        if (domainMessage.attachments.isEmpty) continue;

        for (final attachment in domainMessage.attachments) {
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

      if (videoUrls.isNotEmpty) {
        _mediaCacheManager.prefetchThumbnails(videoUrls);
      }

      // logger.d('Prefetched ${imageUrls.length} image and ${videoUrls.length} video thumbnails');
    } catch (e) {
      logger.w('Error prefetching thumbnails: $e');
    }
  }
}
