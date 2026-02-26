import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart' hide MessageReaction;
import 'package:flutter_chat_app/data/managers/sync_metadata_manager.dart';
import 'package:flutter_chat_app/data/strategies/gap_detection_logic.dart';
import 'package:flutter_chat_app/data/strategies/message_merge_strategy.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_list_transformer.dart';
import 'package:flutter_chat_app/domain/usecases/message/delete_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/edit_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/add_reaction_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/remove_reaction_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';
import 'package:flutter_chat_app/presentation/blocs/message/socket_event_buffer.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/core/services/location_service.dart';
import 'dart:io';

part 'message_event.dart';
part 'message_state.dart';

/// **ENTERPRISE MESSAGE BLOC - CLEAN ARCHITECTURE**
///
/// Updated to use UseCases and proper dependency injection.
/// Follows Clean Architecture with proper separation of concerns.
///
/// **Performance Targets:**
/// - State updates: <50ms
/// - Error handling: Comprehensive with user-friendly messages
/// - Real-time updates: <100ms delivery
@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> with BlocErrorMixin {
  // UseCases (Domain Layer)
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  final EditMessageUseCase _editMessage;
  final DeleteMessageUseCase _deleteMessage;
  final MarkAsReadUseCase _markAsRead;
  final AddReactionUseCase _addReaction;
  final RemoveReactionUseCase _removeReaction;

  // Repositories
  final IAttachmentRepository _attachmentRepository;

  // Services
  final CacheSyncStrategy _cacheSyncStrategy;
  final RealtimeService _realtimeService;
  final ILocationService _locationService;

  // === Phase 2 + 3 Dependencies ===
  final SyncMetadataManager _syncMetadataManager;

  // Logger (injected via DI) - must be AppLogger for BlocErrorMixin
  @override
  final AppLogger logger;

  // Map chat ID -> StreamSubscription
  final Map<String, StreamSubscription?> _messageSubscriptions = {};

  // === Phase 2 + 3 Internal State ===
  final SocketEventBuffer<MessageEvent> _socketEventBuffer = SocketEventBuffer<MessageEvent>();
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _messageEditedSubscription;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _messageReactionSubscription;
  CancelableOperation<void>? _backgroundFetchOperation;
  DateTime? _lastBackgroundedAt;

  // UI transform context
  String _currentUserId = '';
  bool _isGroupChat = false;
  String? _lastReadMessageId;
  String? _highlightedMessageId;

  /// Cập nhật context cho UI transform (gọi từ Page khi mở chat)
  void setTransformContext({
    required String currentUserId,
    bool isGroupChat = false,
    String? lastReadMessageId,
    String? highlightedMessageId,
  }) {
    _currentUserId = currentUserId;
    _isGroupChat = isGroupChat;
    _lastReadMessageId = lastReadMessageId;
    _highlightedMessageId = highlightedMessageId;
  }

  /// Transform messages thành UI state
  List<MessageUIState> _transformMessages(List<ChatMessage> messages) {
    return MessageListTransformer.transform(
      messages: messages,
      currentUserId: _currentUserId,
      lastReadMessageId: _lastReadMessageId,
      highlightedMessageId: _highlightedMessageId,
      isGroupChat: _isGroupChat,
    );
  }

  /// Constructor with UseCases injection
  MessageBloc({
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
    required EditMessageUseCase editMessage,
    required DeleteMessageUseCase deleteMessage,
    required MarkAsReadUseCase markAsRead,
    required AddReactionUseCase addReaction,
    required RemoveReactionUseCase removeReaction,
    required IAttachmentRepository attachmentRepository,
    required CacheSyncStrategy cacheSyncStrategy,
    required RealtimeService realtimeService,
    required ILocationService locationService,
    required SyncMetadataManager syncMetadataManager,
    required this.logger,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        _editMessage = editMessage,
        _deleteMessage = deleteMessage,
        _markAsRead = markAsRead,
        _addReaction = addReaction,
        _removeReaction = removeReaction,
        _attachmentRepository = attachmentRepository,
        _cacheSyncStrategy = cacheSyncStrategy,
        _realtimeService = realtimeService,
        _locationService = locationService,
        _syncMetadataManager = syncMetadataManager,
        super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<MarkChatAsRead>(_onMarkChatAsRead);
    on<ReceiveRealTimeMessage>(_onReceiveRealTimeMessage);
    on<RefreshMessages>(_onRefreshMessages);
    on<ClearMessages>(_onClearMessages);
    on<ToggleReaction>(_onToggleReaction);
    on<SendMessageWithAttachments>(_onSendMessageWithAttachments);
    on<SendLocationMessage>(_onSendLocationMessage);

    // Phase 2 + 3 event handlers
    on<_BackgroundFetchCompleted>(_onBackgroundFetchCompleted);
    on<_BackgroundFetchFailed>(_onBackgroundFetchFailed);
    on<_ReconnectionDetected>(_onReconnectionDetected);
    on<AppResumed>(_onAppResumed);
    on<ReceiveMessageEdited>(_onReceiveMessageEdited);
    on<ReceiveMessageDeleted>(_onReceiveMessageDeleted);
    on<ReceiveMessageReaction>(_onReceiveMessageReaction);

    // Subscribe to connection state changes for reconnection detection
    _connectionStateSubscription = _realtimeService.connectionState
        .distinct()
        .pairwise()
        .where((pair) =>
          pair.first != SocketConnectionState.connected &&
          pair.last == SocketConnectionState.connected)
        .listen((_) => add(const _ReconnectionDetected()));
  }
  
  /// **Load messages — Two-Phase Render + Delta Sync**
  ///
  /// Phase 1: Emit local data immediately (< 50ms) with background fetch flag
  /// Phase 2: Background fetch (delta or full) → merge → emit merged state
  /// Fallback: First-time load (no local data) → standard server fetch
  Future<void> _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    logger.i('[TwoPhase] _onLoadMessages START chatId=${event.chatId} limit=${event.limit} forceRefresh=${event.forceRefresh}');

    // Step 1: Try local data first (Two-Phase Render)
    final localResult = await _getMessages.repository.getMessagesFromLocal(
      event.chatId,
      limit: event.limit,
    );

    final hasLocalData = localResult.fold(
      (_) => false,
      (messages) => messages.isNotEmpty,
    );

    localResult.fold(
      (failure) => logger.w('[TwoPhase] getMessagesFromLocal FAILED: ${failure.message}'),
      (messages) {
        final newestTs = messages.isNotEmpty ? messages.first.createdAt.toIso8601String() : 'N/A';
        final oldestTs = messages.isNotEmpty ? messages.last.createdAt.toIso8601String() : 'N/A';
        logger.i('[TwoPhase] getMessagesFromLocal: count=${messages.length} newest=$newestTs oldest=$oldestTs');
      },
    );

    if (hasLocalData && !event.forceRefresh) {
      // === TWO-PHASE RENDER PATH ===
      final localMessages = localResult.fold((_) => <ChatMessage>[], (m) => m);
      logger.i('[TwoPhase] Taking TWO-PHASE path (hasLocal=true, forceRefresh=false)');

      // Phase 1: Emit local data immediately
      emit(MessagesLoaded(
        chatId: event.chatId,
        messages: localMessages,
        uiMessages: _transformMessages(localMessages),
        hasReachedMax: false,
        dataSource: MessageDataSource.local,
        isBackgroundFetching: true,
      ));

      logger.i('[TwoPhase] Phase 1 EMITTED: localCount=${localMessages.length} dataSource=local bgFetching=true blocHashCode=$hashCode');

      // Subscribe to real-time updates
      if (event.subscribeToUpdates) {
        unawaited(_subscribeToMessages(event.chatId));
        _subscribeToEditDeleteReaction(event.chatId);
      } else {
        unawaited(_cancelMessageSubscription(event.chatId));
      }

      // Phase 2: Background fetch (delta or full)
      _startBackgroundFetch(event.chatId, event.limit);
    } else {
      // === FIRST-TIME LOAD PATH (Phase 1 behavior) ===
      logger.i('[TwoPhase] Taking FIRST-TIME path (hasLocal=$hasLocalData, forceRefresh=${event.forceRefresh})');
      emit(MessagesLoading(chatId: event.chatId));

      final result = await _getMessages(
        conversationId: event.chatId,
        limit: event.limit,
      );

      result.fold(
        (failure) {
          logger.e('[TwoPhase] First-time load FAILED: ${failure.message}', error: failure);
          emit(MessagesError(
            chatId: event.chatId,
            error: failure.message,
          ));
        },
        (messages) {
          final newestTs = messages.isNotEmpty ? messages.first.createdAt.toIso8601String() : 'N/A';
          logger.i('[TwoPhase] First-time load OK: count=${messages.length} newest=$newestTs');

          // Reset dirty flag after successful load
          _cacheSyncStrategy.resetChatMessagesDirtyFlag(event.chatId);

          // Update sync metadata
          unawaited(_syncMetadataManager.updateFromMessages(event.chatId, messages));

          // Subscribe to real-time updates
          if (event.subscribeToUpdates) {
            unawaited(_subscribeToMessages(event.chatId));
            _subscribeToEditDeleteReaction(event.chatId);
          } else {
            unawaited(_cancelMessageSubscription(event.chatId));
          }

          emit(MessagesLoaded(
            chatId: event.chatId,
            messages: messages,
            uiMessages: _transformMessages(messages),
            hasReachedMax: messages.length < event.limit,
            dataSource: MessageDataSource.server,
          ));
        },
      );
    }
  }
  
  /// **Load more messages using GetMessagesUseCase (pagination) - CLEAN ARCHITECTURE**
  Future<void> _onLoadMoreMessages(LoadMoreMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    // If already reached max, do nothing
    if (currentState.hasReachedMax) return;

    logger.i('Loading more messages for chat: ${currentState.chatId}');

    // Calculate cursor based on oldest message timestamp.
    // Backend supports timestamp-based pagination via filters.from.
    final lastMessageCursor = currentState.messages.isNotEmpty
        ? currentState.messages.last.createdAt.millisecondsSinceEpoch.toString()
        : null;

    // Execute UseCase
    final result = await _getMessages(
      conversationId: currentState.chatId,
      limit: event.limit,
      cursor: lastMessageCursor,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load more messages', error: failure);
        // Don't emit error for pagination — just log and re-emit with a
        // pagination error flag so the page can reset its loading indicator.
        emit(currentState.copyWith(paginationError: failure.message));
      },
      (nextMessages) {
        logger.i('Loaded ${nextMessages.length} more messages');

        if (nextMessages.isEmpty) {
          // No more messages
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          // Add new messages to current list
          final byId = <String, ChatMessage>{
            for (final m in currentState.messages) m.id: m,
          };
          for (final m in nextMessages) {
            byId[m.id] = m;
          }

          final allMessages = byId.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(currentState.copyWith(
            messages: allMessages,
            uiMessages: _transformMessages(allMessages),
            hasReachedMax: nextMessages.length < event.limit,
          ));
        }
      },
    );
  }
  
  /// **Send message using SendMessageUseCase - CLEAN ARCHITECTURE**
  Future<void> _onSendMessage(SendMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Sending message in chat: ${currentState.chatId}');

    // Execute UseCase
    final result = await _sendMessage(
      conversationId: currentState.chatId,
      content: event.content,
      senderId: event.senderId,
      type: event.contentType,
      urls: event.attachmentIds,
      replyMessageId: event.replyMessageId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to send message', error: failure);
        emit(MessagesError(
          chatId: currentState.chatId,
          error: failure.message,
          previousMessages: currentState.messages,
        ));
      },
      (newMessage) {
        logger.i('Message sent successfully: ${newMessage.id}');
        
        // Add new message to the beginning of the list (optimistic update)
        final allMessages = [newMessage, ...currentState.messages];
        emit(currentState.copyWith(
          messages: allMessages,
          uiMessages: _transformMessages(allMessages),
        ));

        // Mark message list as dirty
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }

  /// **Edit message using EditMessageUseCase - CLEAN ARCHITECTURE**
  Future<void> _onEditMessage(EditMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Editing message: ${event.messageId}');

    // Execute UseCase
    final result = await _editMessage(
      messageId: event.messageId,
      content: event.content,
    );

    result.fold(
      (failure) {
        logger.e('Failed to edit message', error: failure);
        emit(MessagesError(
          chatId: currentState.chatId,
          error: failure.message,
          previousMessages: currentState.messages,
        ));
      },
      (_) {
        logger.i('Message edited successfully');
        
        // Update message in list with new content
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == event.messageId) {
            // Create updated message with new content
            return ChatMessage(
              id: msg.id,
              chatId: msg.chatId,
              sender: msg.sender,
              content: event.content, // Use new content
              contentType: msg.contentType,
              createdAt: msg.createdAt,
              updatedAt: DateTime.now(),
              editedAt: DateTime.now(),
              readBy: msg.readBy,
              deliveredTo: msg.deliveredTo,
              attachments: msg.attachments,
              reactions: msg.reactions,
            );
          }
          return msg;
        }).toList();

        emit(currentState.copyWith(
          messages: updatedMessages,
          uiMessages: _transformMessages(updatedMessages),
        ));

        // Mark message list as dirty
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
      },
    );
  }

  /// **Delete message using DeleteMessageUseCase - CLEAN ARCHITECTURE**
  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Deleting message: ${event.messageId}');

    // Create params for UseCase
    final params = DeleteMessageParams(messageId: event.messageId);

    // Execute UseCase
    final result = await _deleteMessage(params);

    result.fold(
      (failure) {
        logger.e('Failed to delete message', error: failure);
        emit(MessagesError(
          chatId: currentState.chatId,
          error: failure.message,
          previousMessages: currentState.messages,
        ));
      },
      (_) {
        logger.i('Message deleted successfully');
        
        // Remove message from list
        final updatedMessages = currentState.messages
            .where((msg) => msg.id != event.messageId)
            .toList();

        emit(currentState.copyWith(
          messages: updatedMessages,
          uiMessages: _transformMessages(updatedMessages),
        ));

        // Mark message list as dirty
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }

  /// **Mark chat as read using MarkAsReadUseCase - CLEAN ARCHITECTURE**
  Future<void> _onMarkChatAsRead(MarkChatAsRead event, Emitter<MessageState> emit) async {
    logger.i('Marking chat as read: ${event.chatId}');

    // Create params for UseCase
    final params = MarkAsReadParams(conversationId: event.chatId);

    // Execute UseCase
    final result = await _markAsRead(params);

    result.fold(
      (failure) {
        logger.w('Failed to mark chat as read: ${failure.toString()}');
        // Don't emit error for this operation, it's not critical
      },
      (_) {
        logger.i('Chat marked as read successfully');
        
        // Mark chat list as dirty (unread count changed)
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }

  /// Handle real-time message received via WebSocket
  ///
  /// **Enterprise Pattern (WhatsApp/Telegram/Messenger):**
  /// - Messages from SELF: IGNORE (API response is the source of truth)
  /// - Messages from OTHERS: Add to list (with duplicate check)
  ///
  /// This prevents duplicate messages when:
  /// 1. User sends message → API returns → WebSocket echoes back
  /// 2. User sends rapidly → multiple messages have similar timestamps
  void _onReceiveRealTimeMessage(ReceiveRealTimeMessage event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    // Only process messages for current chat
    if (event.message.chatId != currentState.chatId) return;

    logger.d('Received real-time message via socket: ${event.message.id}');

    // Check if message already exists in list (exact server ID match)
    final messageExists = currentState.messages.any((msg) => msg.id == event.message.id);
    if (messageExists) {
      logger.d('Message ${event.message.id} already exists, ignoring WebSocket echo');
      return;
    }

    // **KEY LOGIC**: If message is from current user, check if we have a pending draft
    // API response will handle our own messages, WebSocket is just an echo
    if (event.message.sender.id == _currentUserId) {
      // Check if we have ANY pending draft (message with clientId that hasn't been replaced yet)
      final hasPendingDraft = currentState.messages.any((msg) =>
          msg.clientId != null && msg.localStatus != null);

      if (hasPendingDraft) {
        // We have pending messages being sent via API
        // The API response will update them, ignore WebSocket echo
        logger.d('Ignoring self-message from WebSocket (API will handle): ${event.message.id}');
        return;
      }

      // No pending drafts - this might be a message sent from another device
      // Fall through to add it
      logger.d('Adding self-message from another device: ${event.message.id}');
    }

    // Add new message (from other users or self from another device)
    final allMessages = [event.message, ...currentState.messages];
    emit(currentState.copyWith(
      messages: allMessages,
      uiMessages: _transformMessages(allMessages),
    ));

    // Mark message list as dirty
    _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
    _cacheSyncStrategy.markChatListDirty();
  }

  // === Phase 2 + 3: Background Fetch ===

  /// Start background fetch with socket event buffering
  void _startBackgroundFetch(String chatId, int limit) {
    _socketEventBuffer.startBuffering();
    _backgroundFetchOperation?.cancel();
    _backgroundFetchOperation = CancelableOperation.fromFuture(
      _performBackgroundFetch(chatId, limit),
    );
  }

  /// Perform delta sync or full fetch in background
  Future<void> _performBackgroundFetch(String chatId, int limit) async {
    try {
      final lastTimestamp = _syncMetadataManager.getLastKnownTimestamp(chatId);
      logger.i('[TwoPhase] _performBackgroundFetch chatId=$chatId lastTimestamp=$lastTimestamp limit=$limit');

      Either<Failure, List<ChatMessage>> result;

      if (lastTimestamp != null) {
        // Delta sync: only fetch messages since last known timestamp
        logger.i('[TwoPhase] Doing DELTA sync from=${DateTime.fromMillisecondsSinceEpoch(lastTimestamp).toIso8601String()}');
        result = await _getMessages.repository.getMessagesDelta(
          chatId,
          fromTimestamp: lastTimestamp,
          limit: limit,
        );

        // Gap detection
        final deltaCount = result.fold((_) => 0, (m) => m.length);
        logger.i('[TwoPhase] Delta result: count=$deltaCount (gap threshold=$limit)');
        if (GapDetectionLogic.hasGap(deltaCount: deltaCount, pageSize: limit)) {
          logger.w('[TwoPhase] Gap detected (deltaCount=$deltaCount >= pageSize=$limit), doing FULL refresh');
          result = await _getMessages(conversationId: chatId, limit: limit);
        }
      } else {
        // No timestamp — full load
        logger.i('[TwoPhase] No lastTimestamp, doing FULL load');
        result = await _getMessages(conversationId: chatId, limit: limit);
      }

      result.fold(
        (failure) {
          logger.e('[TwoPhase] Background fetch FAILED: ${failure.message}');
          add(_BackgroundFetchFailed(chatId: chatId, error: failure.message));
        },
        (messages) {
          final newestTs = messages.isNotEmpty ? messages.first.createdAt.toIso8601String() : 'N/A';
          final oldestTs = messages.isNotEmpty ? messages.last.createdAt.toIso8601String() : 'N/A';
          logger.i('[TwoPhase] Background fetch OK: count=${messages.length} newest=$newestTs oldest=$oldestTs');
          add(_BackgroundFetchCompleted(chatId: chatId, serverMessages: messages));
        },
      );
    } catch (e) {
      logger.e('[TwoPhase] Background fetch EXCEPTION', error: e);
      add(_BackgroundFetchFailed(chatId: chatId, error: e.toString()));
    }
  }

  /// Handle background fetch completion — merge local + server
  void _onBackgroundFetchCompleted(
    _BackgroundFetchCompleted event,
    Emitter<MessageState> emit,
  ) {
    if (state is! MessagesLoaded) {
      logger.w('[TwoPhase] _onBackgroundFetchCompleted: state is NOT MessagesLoaded (${state.runtimeType}), ignoring');
      return;
    }
    final currentState = state as MessagesLoaded;

    // Race condition guard: ignore stale responses for wrong chat
    if (currentState.chatId != event.chatId) {
      logger.w('[TwoPhase] Background fetch completed for WRONG chat: event=${event.chatId} vs current=${currentState.chatId}');
      _socketEventBuffer.stopBuffering();
      return;
    }

    logger.i('[TwoPhase] _onBackgroundFetchCompleted: localCount=${currentState.messages.length} serverCount=${event.serverMessages.length}');

    // Merge local + server
    final merged = MessageMergeStrategy.merge(
      localMessages: currentState.messages,
      serverMessages: event.serverMessages,
    );

    final newestTs = merged.isNotEmpty ? merged.first.createdAt.toIso8601String() : 'N/A';
    final oldestTs = merged.isNotEmpty ? merged.last.createdAt.toIso8601String() : 'N/A';
    logger.i('[TwoPhase] Merge result: count=${merged.length} newest=$newestTs oldest=$oldestTs');

    // Update sync metadata
    unawaited(_syncMetadataManager.updateFromMessages(event.chatId, merged));
    _cacheSyncStrategy.resetChatMessagesDirtyFlag(event.chatId);

    emit(currentState.copyWith(
      messages: merged,
      uiMessages: _transformMessages(merged),
      dataSource: MessageDataSource.merged,
      isBackgroundFetching: false,
      hasReachedMax: event.serverMessages.length < 20,
    ));

    logger.i('[TwoPhase] _onBackgroundFetchCompleted EMITTED new state: mergedCount=${merged.length} dataSource=merged bgFetching=false blocHashCode=$hashCode');

    // Flush buffered socket events
    final bufferedEvents = _socketEventBuffer.stopBuffering();
    if (bufferedEvents.isNotEmpty) {
      logger.i('[TwoPhase] Flushing ${bufferedEvents.length} buffered socket events');
    }
    for (final bufferedEvent in bufferedEvents) {
      add(bufferedEvent);
    }
  }

  /// Handle background fetch failure — keep local data, no error state
  void _onBackgroundFetchFailed(
    _BackgroundFetchFailed event,
    Emitter<MessageState> emit,
  ) {
    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    if (currentState.chatId != event.chatId) {
      _socketEventBuffer.stopBuffering();
      return;
    }

    logger.w('[TwoPhase] Background fetch FAILED for chat ${event.chatId}: ${event.error} — keeping ${currentState.messages.length} local messages');

    emit(currentState.copyWith(
      isBackgroundFetching: false,
    ));

    // Flush buffered socket events
    final bufferedEvents = _socketEventBuffer.stopBuffering();
    if (bufferedEvents.isNotEmpty) {
      logger.i('[TwoPhase] Flushing ${bufferedEvents.length} buffered socket events after failure');
    }
    for (final bufferedEvent in bufferedEvents) {
      add(bufferedEvent);
    }
  }

  // === Phase 3: Socket Event Handlers (Edit/Delete/Reaction) ===

  /// Subscribe to edit/delete/reaction streams from RealtimeService.
  /// Does NOT duplicate room joining — that's handled by _subscribeToMessages.
  void _subscribeToEditDeleteReaction(String chatId) {
    _messageEditedSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageReactionSubscription?.cancel();

    _messageEditedSubscription = _realtimeService.messageEditedStream
        .where((msg) => msg.chatId == chatId)
        .listen((msg) => add(ReceiveMessageEdited(msg)));

    _messageDeletedSubscription = _realtimeService.messageDeletedStream
        .listen((msgId) => add(ReceiveMessageDeleted(msgId)));

    _messageReactionSubscription = _realtimeService.messageReactionStream
        .listen((reaction) => add(ReceiveMessageReaction(
              messageId: reaction.messageId,
              code: reaction.code,
              userId: reaction.userId,
              userName: reaction.userName,
              isAdd: reaction.action == ReactionAction.add,
            )));
  }

  /// Handle socket message:edit — update message in state
  void _onReceiveMessageEdited(ReceiveMessageEdited event, Emitter<MessageState> emit) {
    if (_socketEventBuffer.bufferIfNeeded(event)) return;

    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id == event.editedMessage.id) {
        return event.editedMessage;
      }
      return msg;
    }).toList();

    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    unawaited(_syncMetadataManager.updateFromMessages(
      currentState.chatId,
      [event.editedMessage],
    ));
  }

  /// Handle socket message:delete — remove message from state
  void _onReceiveMessageDeleted(ReceiveMessageDeleted event, Emitter<MessageState> emit) {
    if (_socketEventBuffer.bufferIfNeeded(event)) return;

    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    final updatedMessages = currentState.messages
        .where((msg) => msg.id != event.messageId)
        .toList();

    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));
  }

  /// Handle socket message:reaction — add/remove reaction on message
  void _onReceiveMessageReaction(ReceiveMessageReaction event, Emitter<MessageState> emit) {
    if (_socketEventBuffer.bufferIfNeeded(event)) return;

    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id != event.messageId) return msg;

      List<MessageReaction> updatedReactions;
      if (event.isAdd) {
        updatedReactions = [
          ...msg.reactions,
          MessageReaction(
            code: event.code,
            userId: event.userId,
            userName: event.userName,
            createdAt: DateTime.now(),
          ),
        ];
      } else {
        updatedReactions = msg.reactions
            .where((r) => !(r.code == event.code && r.userId == event.userId))
            .toList();
      }

      return msg.copyWith(reactions: updatedReactions);
    }).toList();

    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));
  }

  // === Phase 3: Reconnection & App Resume ===

  /// Handle reconnection — trigger delta sync for active conversation
  void _onReconnectionDetected(_ReconnectionDetected event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    logger.i('Reconnection detected, triggering delta sync for chat ${currentState.chatId}');
    _startBackgroundFetch(currentState.chatId, 20);
  }

  /// Handle app resume — delta sync if backgrounded > 30 seconds
  void _onAppResumed(AppResumed event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    final now = DateTime.now();
    if (_lastBackgroundedAt != null) {
      final backgroundDuration = now.difference(_lastBackgroundedAt!);
      if (backgroundDuration.inSeconds < 30) {
        logger.d('App resumed after ${backgroundDuration.inSeconds}s, skipping delta sync');
        return;
      }
    }

    logger.i('App resumed after >30s, triggering delta sync for chat ${currentState.chatId}');
    _startBackgroundFetch(currentState.chatId, 20);
  }

  /// Called from Page when app enters background
  void setBackgroundedAt(DateTime time) {
    _lastBackgroundedAt = time;
  }

  /// Handle refresh messages
  Future<void> _onRefreshMessages(RefreshMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;
    
    add(LoadMessages(
      chatId: (state as MessagesLoaded).chatId,
      forceRefresh: true,
    ));
  }
  
  /// Handle clear messages
  void _onClearMessages(ClearMessages event, Emitter<MessageState> emit) {
    emit(const MessageInitial());
  }
  
  /// **Cancel real-time message subscription - ENTERPRISE CLEANUP**
  ///
  /// **Performance**: <100ms cleanup
  /// **Strategy**: Clean subscription cancellation with room exit
  Future<void> _cancelMessageSubscription(String chatId) async {
    logger.d('Cancelling real-time subscription for chat: $chatId');

    final subscription = _messageSubscriptions[chatId];
    if (subscription != null) {
      await subscription.cancel();
      _messageSubscriptions[chatId] = null;
      logger.d('Subscription cancelled for chat: $chatId');
    }

    // Leave chat room to stop receiving updates
    final result = await _realtimeService.leaveChatRoom(chatId);
    result.fold(
      (failure) {
        logger.w('Failed to leave chat room $chatId: ${failure.toString()}');
      },
      (_) {
        logger.d('Successfully left chat room: $chatId');
      },
    );
  }
  
  /// **Subscribe to real-time messages - ENTERPRISE REAL-TIME**
  ///
  /// **Performance**: <100ms message delivery
  /// **Strategy**: WebSocket subscription with automatic room management
  Future<void> _subscribeToMessages(String chatId) async {
    logger.i('Subscribing to real-time messages for chat: $chatId');

    // Cancel existing subscription if any
    await _cancelMessageSubscription(chatId);

    // Ensure real-time connection is established
    if (!_realtimeService.isConnected) {
      final connectResult = await _realtimeService.connect();
      final connectOk = connectResult.fold((_) => false, (_) => true);
      if (!connectOk) {
        logger.e('Failed to connect to real-time server before joining chat room $chatId');
        return;
      }
    }

    // Join chat room for real-time updates
    final joinResult = await _realtimeService.joinChatRoom(chatId);
    final joined = joinResult.fold(
      (failure) {
        logger.e('Failed to join chat room $chatId', error: failure);
        return false;
      },
      (_) {
        logger.i('Successfully joined chat room: $chatId');
        return true;
      },
    );

    if (!joined) {
      return;
    }

    // Subscribe to real-time message stream
    _messageSubscriptions[chatId] = _realtimeService.messageStream
        .where((message) => message.chatId == chatId)
        .listen(
          (message) {
            logger.d('Received real-time message: ${message.id} in chat $chatId');
            add(ReceiveRealTimeMessage(message));
          },
          onError: (error) {
            logger.e('Error in real-time message stream: $error');
          },
        );

    logger.i('Real-time subscription established for chat: $chatId');
  }

  /// Handle toggle reaction on message (optimistic update + API call)
  Future<void> _onToggleReaction(
    ToggleReaction event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Toggling reaction ${event.emojiCode} on message ${event.messageId}');

    // Determine if we're adding or removing
    final targetMessage = currentState.messages.firstWhere(
      (msg) => msg.id == event.messageId,
      orElse: () => currentState.messages.first, // Fallback
    );

    final existingReaction = targetMessage.reactions.where(
      (r) => r.code == event.emojiCode && r.userId == _currentUserId,
    );

    final isRemoving = existingReaction.isNotEmpty;

    // Optimistic update: toggle reaction locally
    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id != event.messageId) return msg;

      List<MessageReaction> updatedReactions;
      if (isRemoving) {
        // Remove reaction
        updatedReactions = msg.reactions
            .where((r) => !(r.code == event.emojiCode && r.userId == _currentUserId))
            .toList();
      } else {
        // Add reaction
        updatedReactions = [
          ...msg.reactions,
          MessageReaction(
            code: event.emojiCode,
            userId: _currentUserId,
            createdAt: DateTime.now(),
          ),
        ];
      }

      return ChatMessage(
        id: msg.id,
        chatId: msg.chatId,
        sender: msg.sender,
        content: msg.content,
        contentType: msg.contentType,
        createdAt: msg.createdAt,
        updatedAt: msg.updatedAt,
        editedAt: msg.editedAt,
        deletedAt: msg.deletedAt,
        urls: msg.urls,
        fileName: msg.fileName,
        forwardedFromMessageId: msg.forwardedFromMessageId,
        replyMessageId: msg.replyMessageId,
        replyMessage: msg.replyMessage,
        actionType: msg.actionType,
        actor: msg.actor,
        targetUsers: msg.targetUsers,
        newValue: msg.newValue,
        oldValue: msg.oldValue,
        mentionTo: msg.mentionTo,
        readBy: msg.readBy,
        deliveredTo: msg.deliveredTo,
        attachments: msg.attachments,
        reactions: updatedReactions,
      );
    }).toList();

    // Emit optimistic update immediately
    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    // Call API to persist reaction on server
    try {
      final result = isRemoving
          ? await _removeReaction(
              messageId: event.messageId,
              code: event.emojiCode,
            )
          : await _addReaction(
              messageId: event.messageId,
              code: event.emojiCode,
            );

      result.fold(
        (failure) {
          logger.e('Failed to toggle reaction', error: failure.message);

          // Rollback optimistic update on failure
          emit(currentState.copyWith(
            messages: currentState.messages,
            uiMessages: _transformMessages(currentState.messages),
          ));

          // Note: Error handling can be improved by adding error field to MessagesLoaded state
        },
        (_) {
          logger.i('Reaction updated successfully');
          // Success - optimistic update already shown
          // Real-time socket will sync the full reaction list with reactors
        },
      );
    } catch (e, stackTrace) {
      logger.e('Unexpected error toggling reaction', error: e, stackTrace: stackTrace);

      // Rollback on unexpected error
      emit(currentState.copyWith(
        messages: currentState.messages,
        uiMessages: _transformMessages(currentState.messages),
      ));
    }
  }

  /// **Send message with file attachments - CLEAN ARCHITECTURE**
  ///
  /// Handles complete flow using enterprise-grade optimistic UI pattern:
  /// 1. Generate unique clientId (UUID) for tracking
  /// 2. Create optimistic message with local file (show immediately)
  /// 3. Upload files to GCP Cloud Storage (show progress)
  /// 4. Send message with uploaded file paths
  /// 5. Replace optimistic message with server response (matched by clientId)
  ///
  /// WebSocket handler will IGNORE messages from self (API response is source of truth)
  Future<void> _onSendMessageWithAttachments(
    SendMessageWithAttachments event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send message with attachments - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    logger.i('Sending message with ${event.localFilePaths.length} attachments');

    // Generate unique client ID (UUID) for tracking this message
    // This ensures we can match the API response even with rapid sends
    const uuid = Uuid();
    final clientId = uuid.v4();
    final draftId = 'draft_$clientId'; // Temporary ID until server assigns real one

    // Determine message type from first file
    // Cross-platform: use fileNames on web (path might be blob URL), path on mobile
    String extension;
    if (kIsWeb && event.fileNames != null && event.fileNames!.isNotEmpty) {
      // Web: extract extension from fileName (path might be blob URL)
      extension = event.fileNames!.first.split('.').last.toLowerCase();
    } else {
      // Mobile: extract extension from path
      extension = event.localFilePaths.first.split('.').last.toLowerCase();
    }
    final messageType = _getMessageTypeFromExtension(extension);
    final contentType = _getContentTypeFromExtension(extension);

    // Create attachments with local paths (for immediate display)
    // Cross-platform: use event data on web, File operations on mobile
    final localAttachments = await Future.wait(
      event.localFilePaths.asMap().entries.map((entry) async {
        final index = entry.key;
        final path = entry.value;

        // Get file name - from event on web, from path on mobile
        final fileName = kIsWeb && event.fileNames != null && index < event.fileNames!.length
            ? event.fileNames![index]
            : path.split('/').last.split('\\').last;

        // Get file size - from event on web, from File on mobile
        int fileSize = 0;
        if (kIsWeb && event.fileSizes != null && index < event.fileSizes!.length) {
          fileSize = event.fileSizes![index];
        } else if (!kIsWeb) {
          // Mobile only: use dart:io File operations
          final file = File(path);
          fileSize = await file.exists() ? await file.length() : 0;
        }

        // Get file bytes - from event on web (for display during upload)
        Uint8List? fileBytes;
        if (kIsWeb && event.fileBytes != null && index < event.fileBytes!.length) {
          fileBytes = Uint8List.fromList(event.fileBytes![index]);
        }

        return MessageAttachment(
          id: 'local_${clientId}_$index',
          url: '', // Empty - will be filled after upload
          type: messageType.toLowerCase(),
          size: fileSize,
          name: fileName,
          localPath: path,
          localBytes: fileBytes, // Web: bytes for display
          uploadProgress: 0.0, // Starting upload
        );
      }),
    );

    // Step 1: Create optimistic message with sending status and show immediately
    final optimisticMessage = ChatMessage(
      id: draftId,
      clientId: clientId, // Track by clientId for matching
      chatId: currentState.chatId,
      content: event.content,
      contentType: contentType,
      sender: MessageSender(
        id: event.senderId,
        name: '', // Will be filled by transformer
        avatar: null,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      attachments: localAttachments,
      urls: event.localFilePaths, // Use local paths for display
      reactions: const [],
      readBy: const [],
      mentionTo: const [],
      localStatus: MessageStatus.sending, // Optimistic: show as sending
    );

    // Add optimistic message to UI immediately
    var updatedMessages = [optimisticMessage, ...currentState.messages];
    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    logger.d('Created optimistic message with clientId: $clientId');

    try {
      // Step 2: Upload all files with progress tracking
      final uploadedUrls = <String>[];

      for (var i = 0; i < event.localFilePaths.length; i++) {
        final filePath = event.localFilePaths[i];

        // Cross-platform: use bytes on web, File on mobile
        final result = await _attachmentRepository.uploadAttachment(
          messageId: draftId,
          chatId: currentState.chatId,
          file: kIsWeb ? null : File(filePath),
          bytes: kIsWeb && event.fileBytes != null && i < event.fileBytes!.length
              ? Uint8List.fromList(event.fileBytes![i])
              : null,
          fileName: kIsWeb && event.fileNames != null && i < event.fileNames!.length
              ? event.fileNames![i]
              : null,
          onProgress: (progress) {
            // Update progress for this attachment
            _updateAttachmentProgress(
              emit: emit,
              clientId: clientId,
              attachmentIndex: i,
              progress: progress,
            );
          },
        );

        final url = result.fold(
          (failure) {
            logger.e('Failed to upload file', error: failure);
            throw Exception(failure.message);
          },
          (uploadResult) => uploadResult.url,
        );

        uploadedUrls.add(url);
      }

      logger.i('All files uploaded successfully: ${uploadedUrls.length}');

      // Step 3: Send message with uploaded URLs
      // Get fileName from first file (matching Angular frontend behavior)
      // Cross-platform: use fileNames on web, extract from path on mobile
      final fileName = kIsWeb && event.fileNames != null && event.fileNames!.isNotEmpty
          ? event.fileNames!.first
          : event.localFilePaths.isNotEmpty
              ? event.localFilePaths.first.split('/').last.split('\\').last
              : null;

      final result = await _sendMessage(
        conversationId: currentState.chatId,
        content: event.content,
        senderId: event.senderId,
        type: messageType,
        urls: uploadedUrls,
        replyMessageId: event.replyMessageId,
        fileName: fileName,
      );

      result.fold(
        (failure) {
          logger.e('Failed to send message with attachments', error: failure);
          // Mark message as failed
          _markMessageAsFailed(emit, clientId);
        },
        (message) {
          logger.i('Message sent successfully: ${message.id} (clientId: $clientId)');

          // Step 4: Replace optimistic message with server response
          // Match by clientId to handle rapid sends correctly
          _replaceDraftWithServerMessage(emit, clientId, message);
        },
      );
    } catch (e, stackTrace) {
      logger.e('Error sending message with attachments', error: e, stackTrace: stackTrace);
      _markMessageAsFailed(emit, clientId);
    }
  }

  /// Replace draft message with server response, matched by clientId
  void _replaceDraftWithServerMessage(
    Emitter<MessageState> emit,
    String clientId,
    ChatMessage serverMessage,
  ) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    final messages = currentState.messages.map((message) {
      // Match by clientId (not by draftId which could be ambiguous)
      if (message.clientId == clientId) {
        logger.d('Replacing draft (clientId: $clientId) with server message: ${serverMessage.id}');

        // Preserve file size from draft attachments (backend doesn't return size)
        final mergedAttachments = serverMessage.attachments.asMap().entries.map((entry) {
          final serverAttachment = entry.value;
          // Find corresponding draft attachment by index or URL
          if (entry.key < message.attachments.length) {
            final draftAttachment = message.attachments[entry.key];
            // If server returns size 0, use the size from draft (read from local file)
            if (serverAttachment.size == 0 && draftAttachment.size > 0) {
              return serverAttachment.copyWith(size: draftAttachment.size);
            }
          }
          return serverAttachment;
        }).toList();

        return serverMessage.copyWith(attachments: mergedAttachments);
      }
      return message;
    }).toList();

    emit(currentState.copyWith(
      messages: messages,
      uiMessages: _transformMessages(messages),
    ));
  }

  /// Update attachment upload progress (matched by clientId)
  void _updateAttachmentProgress({
    required Emitter<MessageState> emit,
    required String clientId,
    required int attachmentIndex,
    required double progress,
  }) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    final messages = currentState.messages.map((message) {
      // Match by clientId for accurate tracking with rapid sends
      if (message.clientId != clientId) return message;

      final updatedAttachments = message.attachments.asMap().entries.map((entry) {
        if (entry.key != attachmentIndex) return entry.value;
        return entry.value.copyWith(uploadProgress: progress);
      }).toList();

      return message.copyWith(attachments: updatedAttachments);
    }).toList();

    emit(currentState.copyWith(
      messages: messages,
      uiMessages: _transformMessages(messages),
    ));
  }

  /// Mark a draft message as failed (matched by clientId)
  void _markMessageAsFailed(Emitter<MessageState> emit, String clientId) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    final messages = currentState.messages.map((message) {
      // Match by clientId for accurate tracking
      if (message.clientId != clientId) return message;
      return message.copyWith(localStatus: MessageStatus.failed);
    }).toList();

    emit(currentState.copyWith(
      messages: messages,
      uiMessages: _transformMessages(messages),
    ));
  }

  /// Get ContentType from file extension
  ContentType _getContentTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
      case 'heif':
        return ContentType.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return ContentType.video;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return ContentType.audio;
      default:
        return ContentType.file;
    }
  }

  /// **Send location message - CLEAN ARCHITECTURE**
  ///
  /// Handles location sharing:
  /// 1. Get address from coordinates (optional)
  /// 2. Create location data JSON
  /// 3. Send message with type LOCATION
  Future<void> _onSendLocationMessage(
    SendLocationMessage event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send location - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    logger.i('Sending location message');

    try {
      // Get address from coordinates (optional, for better UX)
      String? locationName = event.locationName;

      if (locationName == null) {
        final addressResult = await _locationService.getAddressFromCoordinates(
          latitude: event.latitude,
          longitude: event.longitude,
        );

        locationName = addressResult.fold(
          (failure) {
            logger.w('Failed to get address');
            return null;
          },
          (address) => address,
        );
      }

      // Create location data JSON
      final locationData = LocationData(
        latitude: event.latitude,
        longitude: event.longitude,
        name: locationName,
        timestamp: DateTime.now(),
      );

      // Send message with type LOCATION
      final result = await _sendMessage(
        conversationId: currentState.chatId,
        content: locationData.toJson(),
        senderId: event.senderId,
        type: 'LOCATION',
      );

      result.fold(
        (failure) {
          logger.e('Failed to send location message', error: failure);
        },
        (message) {
          logger.i('Location message sent successfully: ${message.id}');

          // Add new message to top of list
          final updatedMessages = [message, ...currentState.messages];
          emit(currentState.copyWith(
            messages: updatedMessages,
            uiMessages: _transformMessages(updatedMessages),
          ));
        },
      );
    } catch (e, stackTrace) {
      logger.e('Error sending location message', error: e, stackTrace: stackTrace);
    }
  }

  /// Helper: Determine message type from file extension
  String _getMessageTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return 'IMAGE';

      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return 'VIDEO';

      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
      case 'aac':
        return 'AUDIO';

      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        return 'DOC';

      default:
        return 'DOC';
    }
  }

  @override
  Future<void> close() async {
    // Cancel background fetch
    _backgroundFetchOperation?.cancel();

    // Cancel Phase 2 + 3 subscriptions
    _connectionStateSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageReactionSubscription?.cancel();

    // Cancel existing Phase 1 subscriptions
    for (final chatId in _messageSubscriptions.keys) {
      await _cancelMessageSubscription(chatId);
    }
    _messageSubscriptions.clear();
    return super.close();
  }
}
